#!/usr/bin/env python3
"""
ChronoChess 5D — Центральный мастер-сервер и релей комнат для онлайн-игры.
Поддерживает:
1. 5D Хроно-шахматы с путешествиями во времени (2 игрока).
2. Мульти-шахматы без времени: 1х1х1 (3 игрока), 2х2 (4 игрока) и 1х1х1х1 (4 игрока).
3. Список комнат (Server Browser), динамическое лобби ожидания и переподключение (Graceful Reconnection).
"""

import asyncio
import json
import logging
import random
import sys
from typing import Dict, List, Optional

try:
    import websockets
except ImportError:
    print("Ошибка: библиотека websockets не установлена. Выполните: pip install websockets")
    sys.exit(1)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

PORT = 7575
CODE_CHARS = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
TOKEN_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789abcdefghijkmnopqrstuvwxyz"
GRACE_PERIOD_SECONDS = 60


class PlayerSlot:
    def __init__(self, ws, token: str, name: str, color: int, is_host: bool = False, skin: str = "classic"):
        self.ws = ws
        self.token: str = token
        self.name: str = name
        self.color: int = color
        self.is_host: bool = is_host
        self.skin: str = skin
        self.is_connected: bool = True


class Room:
    def __init__(self, code: str, name: str, variant: str, game_type: str, max_players: int, host_color: int, host_ws, host_token: str, host_name: str, host_skin: str = "classic"):
        self.code: str = code
        self.name: str = name
        self.variant: str = variant         # standard, princess, 1v1v1, 2v2, 1v1v1v1
        self.game_type: str = game_type     # "5d" или "multi"
        self.max_players: int = max_players # 2 (5D), 3 (1v1v1), 4 (2v2, 1v1v1v1)
        self.players: List[PlayerSlot] = [PlayerSlot(host_ws, host_token, host_name, host_color, True, host_skin)]
        self.active: bool = False
        self.turns: list = []
        self.disconnect_task: Optional[asyncio.Task] = None

    def get_slot_by_ws(self, ws) -> Optional[PlayerSlot]:
        for p in self.players:
            if p.ws == ws:
                return p
        return None

    def get_slot_by_token(self, token: str) -> Optional[PlayerSlot]:
        for p in self.players:
            if p.token == token:
                return p
        return None

    def get_available_color(self) -> int:
        taken = {p.color for p in self.players}
        for c in range(self.max_players):
            if c not in taken:
                return c
        return 0

    def connected_count(self) -> int:
        return len([p for p in self.players if p.is_connected])

    def to_dict(self):
        return {
            "code": self.code,
            "name": self.name,
            "variant": self.variant,
            "game_type": self.game_type,
            "max_players": self.max_players,
            "current_players": self.connected_count(),
            "color": self.players[0].color if self.players else 0,
        }


rooms: Dict[str, Room] = {}
ws_to_room: Dict[object, Optional[Room]] = {}


def generate_code() -> str:
    for _ in range(100):
        c = "".join(random.choice(CODE_CHARS) for _ in range(4))
        if c not in rooms:
            return c
    return "".join(random.choice(CODE_CHARS) for _ in range(6))


def generate_token() -> str:
    return "".join(random.choice(TOKEN_CHARS) for _ in range(16))


async def send_json(ws, data: dict):
    if ws is None:
        return
    try:
        await ws.send(json.dumps(data))
    except Exception as e:
        logging.warning(f"Ошибка отправки сообщения: {e}")


async def broadcast_room_list():
    """Рассылает открытые комнаты всем свободным клиентам в лобби."""
    open_rooms = [r.to_dict() for r in rooms.values() if not r.active and r.connected_count() < r.max_players]
    msg = {"type": "room_list", "rooms": open_rooms}
    for ws, r in list(ws_to_room.items()):
        if r is None:
            await send_json(ws, msg)


async def broadcast_lobby_update(room: Room):
    """Обновляет состояние слотов лобби для всех участников комнаты."""
    players_data = []
    for p in room.players:
        if p.is_connected:
            players_data.append({
                "name": p.name,
                "color": p.color,
                "is_host": p.is_host,
                "skin": getattr(p, "skin", "classic")
            })
    msg = {
        "type": "room_lobby_update",
        "code": room.code,
        "name": room.name,
        "game_type": room.game_type,
        "variant": room.variant,
        "max_players": room.max_players,
        "players": players_data
    }
    for p in room.players:
        if p.is_connected and p.ws:
            await send_json(p.ws, msg)


async def start_game_in_room(room: Room):
    """Запускает матч и рассылает сигнал старта всем участникам."""
    room.active = True

    # Для мульти-шахмат заполняем недостающие слоты ботами
    all_slots = []
    taken_colors = {p.color for p in room.players if p.is_connected}
    for p in room.players:
        if p.is_connected:
            all_slots.append({
                "name": p.name,
                "color": p.color,
                "is_bot": False,
                "skin": getattr(p, "skin", "classic")
            })

    for c in range(room.max_players):
        if c not in taken_colors:
            all_slots.append({"name": f"Бот {c+1} (ИИ)", "color": c, "is_bot": True, "skin": "classic"})

    logging.info(f"Матч в комнате [{room.code}] запущен! Формат: {room.variant}, участников: {len(all_slots)}")

    if room.game_type in ["multi", "d20_multi"]:
        for p in room.players:
            if p.is_connected and p.ws:
                await send_json(p.ws, {
                    "type": "multi_game_start",
                    "game_type": room.game_type,
                    "is_d20": (room.game_type == "d20_multi"),
                    "code": room.code,
                    "sub_mode": room.variant,
                    "my_color": p.color,
                    "players": all_slots,
                    "token": p.token
                })
    else:
        # Классические 5D шахматы
        p1 = room.players[0]
        p2 = room.players[1] if len(room.players) > 1 else room.players[0]
        await send_json(p1.ws, {
            "type": "game_start",
            "game_type": "5d",
            "code": room.code,
            "variant": room.variant,
            "my_color": p1.color,
            "opponent_name": p2.name,
            "opponent_skin": getattr(p2, "skin", "classic"),
            "my_skin": getattr(p1, "skin", "classic"),
            "token": p1.token
        })
        if len(room.players) > 1 and p2.ws:
            await send_json(p2.ws, {
                "type": "game_start",
                "game_type": "5d",
                "code": room.code,
                "variant": room.variant,
                "my_color": p2.color,
                "opponent_name": p1.name,
                "opponent_skin": getattr(p1, "skin", "classic"),
                "my_skin": getattr(p2, "skin", "classic"),
                "token": p2.token
            })

    await broadcast_room_list()


async def _grace_timeout_check(room: Room):
    try:
        await asyncio.sleep(GRACE_PERIOD_SECONDS)
        logging.info(f"Таймаут переподключения в комнате [{room.code}] истек.")
        for p in room.players:
            if p.is_connected and p.ws:
                await send_json(p.ws, {
                    "type": "opponent_disconnected",
                    "message": "Время на переподключение соперника (60с) истекло."
                })
    except asyncio.CancelledError:
        return
    finally:
        if room.code in rooms and room.connected_count() == 0:
            del rooms[room.code]


async def handle_disconnect(room: Room, disconnected_ws, client_ip: str):
    slot = room.get_slot_by_ws(disconnected_ws)
    if slot is None:
        return

    # Если игра ещё в лобби
    if not room.active:
        if slot.is_host:
            # Хост вышел — закрываем комнату
            if room.code in rooms:
                del rooms[room.code]
            for p in room.players:
                if p != slot and p.is_connected and p.ws:
                    await send_json(p.ws, {
                        "type": "error",
                        "message": "Хост покинул лобби. Комната закрыта."
                    })
                    ws_to_room[p.ws] = None
        else:
            # Вышел гость — освобождаем слот и обновляем лобби
            room.players.remove(slot)
            await broadcast_lobby_update(room)
        return

    # Во время активного матча
    slot.is_connected = False
    slot.ws = None

    alive = [p for p in room.players if p.is_connected]
    if len(alive) == 0:
        if room.disconnect_task and not room.disconnect_task.done():
            room.disconnect_task.cancel()
        room.disconnect_task = asyncio.create_task(_grace_timeout_check(room))
    else:
        for p in alive:
            if p.ws:
                await send_json(p.ws, {
                    "type": "opponent_disconnected_temporary",
                    "timeout": GRACE_PERIOD_SECONDS,
                    "player_color": slot.color,
                    "message": f"Игрок {slot.name} отключился. Ожидание возвращения (60с)..."
                })
        if room.disconnect_task and not room.disconnect_task.done():
            room.disconnect_task.cancel()
        room.disconnect_task = asyncio.create_task(_grace_timeout_check(room))


async def handle_client(websocket):
    client_ip = websocket.remote_address[0] if websocket.remote_address else "unknown"
    logging.info(f"Новое подключение: {client_ip}")
    ws_to_room[websocket] = None

    try:
        async for message in websocket:
            try:
                data = json.loads(message)
            except json.JSONDecodeError:
                continue

            msg_type = data.get("type")

            # 1. Запрос списка открытых комнат
            if msg_type == "list_rooms":
                open_rooms = [r.to_dict() for r in rooms.values() if not r.active and r.connected_count() < r.max_players]
                await send_json(websocket, {"type": "room_list", "rooms": open_rooms})

            # 2. Создание комнаты (5D или Мульти-шахматы)
            elif msg_type == "create_room":
                old_room = ws_to_room.get(websocket)
                if old_room and old_room.code in rooms and not old_room.active:
                    del rooms[old_room.code]

                code = generate_code()
                name = data.get("name", f"Комната {code}")
                game_type = data.get("game_type", "5d")
                variant = data.get("variant", "standard")

                if game_type in ["multi", "d20_multi"]:
                    max_players = 3 if variant == "1v1v1" else 4
                else:
                    max_players = 2

                color = int(data.get("color", 0))
                host_token = generate_token()
                host_name = data.get("player_name", "Хост")
                host_skin = str(data.get("skin", "classic"))

                room = Room(code, name, variant, game_type, max_players, color, websocket, host_token, host_name, host_skin)
                rooms[code] = room
                ws_to_room[websocket] = room

                logging.info(f"Создана комната [{code}] ({name}, тип {game_type}, вариант {variant}, скин {host_skin}, {max_players} мест) от {client_ip}")
                await send_json(websocket, {
                    "type": "room_created",
                    "code": code,
                    "name": name,
                    "game_type": game_type,
                    "variant": variant,
                    "max_players": max_players,
                    "color": color,
                    "token": host_token
                })

                await broadcast_lobby_update(room)
                await broadcast_room_list()

            # 3. Подключение к комнате по коду
            elif msg_type == "join_room":
                code = str(data.get("code", "")).strip().upper().replace("-", "").replace(" ", "")
                room = rooms.get(code)
                if not room or room.active or room.connected_count() >= room.max_players:
                    await send_json(websocket, {
                        "type": "error",
                        "message": f"Комната [{code}] не найдена или уже заполнена"
                    })
                    continue

                guest_color = room.get_available_color()
                guest_token = generate_token()
                guest_name = data.get("player_name", f"Игрок {room.connected_count() + 1}")
                guest_skin = str(data.get("skin", "classic"))

                guest_slot = PlayerSlot(websocket, guest_token, guest_name, guest_color, False, guest_skin)
                room.players.append(guest_slot)
                ws_to_room[websocket] = room

                logging.info(f"Игрок {guest_name} ({client_ip}, скин {guest_skin}) присоединился к [{code}]. Игроков: {room.connected_count()}/{room.max_players}")

                # Отправляем подтверждение входа игроку
                await send_json(websocket, {
                    "type": "joined_room",
                    "code": room.code,
                    "game_type": room.game_type,
                    "variant": room.variant,
                    "max_players": room.max_players,
                    "color": guest_color,
                    "token": guest_token
                })

                # Все режимы (5D, Мульти, D20) теперь используют лобби ожидания без авто-старта
                await broadcast_lobby_update(room)
                await broadcast_room_list()

            # 4. Принудительный старт игры хостом (с ботами)
            elif msg_type == "start_room_game":
                room = ws_to_room.get(websocket)
                if room and not room.active:
                    slot = room.get_slot_by_ws(websocket)
                    if slot and slot.is_host:
                        await start_game_in_room(room)

            # 5. Передача хода мульти-шахмат
            elif msg_type == "multi_turn":
                room = ws_to_room.get(websocket)
                if room and room.active:
                    move = data.get("move", {})
                    room.turns.append(move)
                    for p in room.players:
                        if p.ws != websocket and p.is_connected and p.ws:
                            await send_json(p.ws, {
                                "type": "multi_turn",
                                "move": move
                            })

            # 6. Передача хода 5D-шахмат
            elif msg_type == "turn":
                room = ws_to_room.get(websocket)
                if room and room.active:
                    moves = data.get("moves", [])
                    room.turns.append(moves)
                    for p in room.players:
                        if p.ws != websocket and p.is_connected and p.ws:
                            await send_json(p.ws, {
                                "type": "turn",
                                "moves": moves
                            })

            # Синхронизация скинов игроков
            elif msg_type == "skin_sync":
                room = ws_to_room.get(websocket)
                if room:
                    slot = room.get_slot_by_ws(websocket)
                    if slot:
                        slot.skin = str(data.get("skin", slot.skin))
                    for p in room.players:
                        if p.ws != websocket and p.is_connected and p.ws:
                            await send_json(p.ws, data)

            # 7. Переподключение к матчу
            elif msg_type == "reconnect":
                code = str(data.get("code", "")).strip().upper().replace("-", "").replace(" ", "")
                token = str(data.get("token", "")).strip()
                last_turn_index = int(data.get("last_turn_index", 0))

                room = rooms.get(code)
                if not room or not room.active:
                    await send_json(websocket, {
                        "type": "reconnect_failed",
                        "message": "Матч не найден или уже завершён"
                    })
                    continue

                slot = room.get_slot_by_token(token)
                if slot is None:
                    await send_json(websocket, {
                        "type": "reconnect_failed",
                        "message": "Неверный токен доступа к матчу"
                    })
                    continue

                if room.disconnect_task and not room.disconnect_task.done():
                    room.disconnect_task.cancel()
                    room.disconnect_task = None

                slot.ws = websocket
                slot.is_connected = True
                ws_to_room[websocket] = room

                missed_turns = room.turns[last_turn_index:] if 0 <= last_turn_index <= len(room.turns) else room.turns
                logging.info(f"Игрок {slot.name} успешно переподключился к [{code}]")

                all_slots = [{"name": p.name, "color": p.color, "is_bot": False} for p in room.players]
                await send_json(websocket, {
                    "type": "reconnected",
                    "code": room.code,
                    "game_type": room.game_type,
                    "variant": room.variant,
                    "my_color": slot.color,
                    "players": all_slots,
                    "missed_turns": missed_turns,
                    "turn_history": room.turns,
                    "total_turns": len(room.turns)
                })

                for p in room.players:
                    if p != slot and p.is_connected and p.ws:
                        await send_json(p.ws, {
                            "type": "opponent_reconnected",
                            "player_color": slot.color,
                            "message": f"Игрок {slot.name} вернулся в игру!"
                        })

            # 8. Сдача партии
            elif msg_type == "resign":
                room = ws_to_room.get(websocket)
                if room and room.active:
                    slot = room.get_slot_by_ws(websocket)
                    for p in room.players:
                        if p.ws != websocket and p.is_connected and p.ws:
                            await send_json(p.ws, {
                                "type": "player_resigned",
                                "color": slot.color if slot else -1,
                                "name": slot.name if slot else "Игрок"
                            })
                    if room.game_type == "5d":
                        if room.code in rooms:
                            del rooms[room.code]

            # 9. Выход из лобби
            elif msg_type == "leave_room":
                room = ws_to_room.get(websocket)
                if room:
                    await handle_disconnect(room, websocket, client_ip)
                    ws_to_room[websocket] = None
                    await broadcast_room_list()

            # 10. Ping
            elif msg_type == "ping":
                await send_json(websocket, {"type": "pong"})

    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        room = ws_to_room.pop(websocket, None)
        if room:
            await handle_disconnect(room, websocket, client_ip)
            await broadcast_room_list()
        logging.info(f"Клиент отключился: {client_ip}")


async def main():
    async with websockets.serve(handle_client, "0.0.0.0", PORT):
        logging.info(f"=== ChronoChess 5D Server запущен на порту {PORT} ===")
        await asyncio.Future()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logging.info("Сервер остановлен.")
