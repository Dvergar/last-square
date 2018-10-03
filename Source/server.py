from __future__ import annotations
import struct
import random
import math
import time
import sys
from typing import *

# from twisted.internet.protocol import Protocol, Factory
from twisted.internet import reactor
from twisted.internet import task
from twisted.python import log
# from twisted.web import static, server

from autobahn.twisted.websocket import WebSocketServerFactory, WebSocketServerProtocol
import randomcolor
# factory = WebSocketServerFactory()
# factory.protocol = MyServerProtocol

import serverhelpers
from common import *


log.startLogging(sys.stdout)


def log(msg):
    localtime = time.localtime()
    now = time.strftime("<%H:%M:%S>", localtime)
    print(now, msg)


class BinaryStream:
    def __init__(self):
        self.byte_struct = struct.Struct("!b")
        self.ubyte_struct = struct.Struct("!B")
        self.int_struct = struct.Struct("!i")
        self.short_struct = struct.Struct("!h")

    def put_data(self, data:bytes) -> None:
        self.data = data
        self.len_data = len(data)
        self.pos:int = 0

    def read_data_left(self) -> bytes:
        return self.data[self.pos:]

    def read_byte(self) -> bytes:
        size = 1
        byte = self.data[self.pos:self.pos + size]
        byte, = self.byte_struct.unpack(byte)
        self.pos += size
        return byte

    def read_ubyte(self) -> bytes:
        size = 1
        byte = self.data[self.pos:self.pos + size]
        byte, = self.ubyte_struct.unpack(byte)
        self.pos += size
        return byte

    def read_int(self) -> bytes:
        size = 4
        _int = self.data[self.pos:self.pos + size]
        _int, = self.int_struct.unpack(_int)
        self.pos += size
        return _int

    def read_short(self) -> bytes:
        size = 2
        short = self.data[self.pos:self.pos + size]
        short, = self.short_struct.unpack(short)
        self.pos += size
        return short

    def read_UTF(self) -> bytes:
        size = 2
        length = self.data[self.pos:self.pos + size]
        length, = self.short_struct.unpack(length)
        self.pos += size
        string = self.data[self.pos:self.pos + length]
        string, = struct.unpack("!" + str(length) + "s", string)
        self.pos += length
        return string

    def working(self) -> bool:
        if self.pos == self.len_data:
            return False
        else:
            return True

bs = BinaryStream()


def broadcast(data:bytes):
    for connection in Connection._registry.values():
        connection.send(data)


def read_policy():
    print("policy request")
    with file("mypolicy.xml", 'rb') as f:
        policy = f.read(10001)
        return policy


World = Dict[Tuple[int, int], int]


class Pillar:
    _registry:List[Pillar] = []
    def __init__(self, x:int, y:int, world:World, owner:Connection) -> None:
        self._registry.append(self)
        self.owner = owner
        self.world:World = world
        self.x = x
        self.y = y
        self.checklist = [
                        (-1, 0),
                        (-1, 1),
                        (0, 1),
                        (1, 1),
                        (0, 0),
                        (1, 0),
                        (1, -1),
                        (0, -1),
                        (-1, -1)
                        ]

    def attack(self):
        angle = random.random() * 2 * math.pi
        distance_max = 8
        distance = random.randint(1, distance_max)
        x_off = int(math.cos(angle) * distance)
        y_off = int(math.sin(angle) * distance)
        print(x_off, y_off)
        try:
            for (dx, dy) in self.checklist:
                x = self.x + x_off + dx
                y = self.y + y_off + dy
                self.owner.push_dot(x, y)
            target_x = self.x + x_off
            target_y = self.y + y_off
            broadcast(struct.pack("!6B", CST.PILLAR_ATTACK, self.owner.id, self.x, self.y, target_x, target_y))
        except KeyError:
            pass


class Tower:
    _registry:List[Tower] = []

    def __init__(self, x:int, y:int, world:World, owner:Connection) -> None:
        self._registry.append(self)
        self.owner:Connection = owner
        self.world:World = world
        self.x, self.y = x, y
        self.left = self.right = self.up = self.down = (x, y)

    def propagate(self):
        self.left = (self.left[0] - 1, self.left[1])
        self.right = (self.right[0] + 1, self.right[1])
        self.up = (self.up[0], self.up[1] + 1)
        self.down = (self.down[0], self.down[1] - 1)
        propagating = 4

        if self.left in self.world:
            self.owner.push_dot(*self.left)
        else:
            propagating -= 1

        if self.right in self.world:
            self.owner.push_dot(*self.right)
        else:
            propagating -= 1

        if self.up in self.world:
            self.owner.push_dot(*self.up)
        else:
            propagating -= 1

        if self.down in self.world:
            self.owner.push_dot(*self.down)
        else:
            propagating -= 1

        if not propagating:
            self.destroy()

    def destroy(self):
        log("Tower destroy")
        self._registry.remove(self)
        self.owner.towers.remove(self)
        broadcast(struct.pack("!4B", CST.TOWER, 0, self.x, self.y))


class Connection(WebSocketServerProtocol):
    _registry:Dict[int, Connection] = {}
    _ids:List[int] = list(range(1, 255))
    energy = CST.ENERGY_DEFAULT
    dots = 0

    def __init__(self):
        super().__init__()

        self.energy_max = 20 + self.dots * 0.2
        self.towers:List[Tower] = []
        self.pillars:List[Pillar] = []
        self.last_frame_time = time.time()
        self.temp_dots:List[Dot] = []
        self.REALLY_connected = 0
        self.checklist = [
                        (-1, 0),
                        (-1, 1),
                        (0, 1),
                        (1, 1),
                        (1, 0),
                        (1, -1),
                        (0, -1),
                        (-1, -1)
                        ]

    def enc(self, string:str) -> bytes:
        return string.encode("utf-8")

    def dec(self, string:bytes) -> str:
        return string.decode("utf-8")

    def onMessage(self, data:bytes, isBinary:bool):
        ## echo back message verbatim

        bs.put_data(data)

        while bs.working():
            msg_type = bs.read_byte()

            if msg_type == CST.CONNECTION:
                # Here to prevent client receiving other clients datas before init
                self._registry[self.id] = self
                self.tosend = b''
                self.nick = bs.read_UTF().decode("utf-8")
                # self.color = random.randint(0, 0xFFFFFF)
                color, = randomcolor.RandomColor().generate(luminosity="light")
                self.color = int("0x" + color[1:], 16)
                self.REALLY_connected = 1
                print(self.nick)
                log("Connection from " + str(self.nick))

                # send connected players data
                for connection in Connection._registry.values():
                    if connection.REALLY_connected:
                        if connection != self:
                            # Send players to me
                            self.send(connection.get_datas_connection())
                            # Send me to players
                            connection.send(self.get_datas_connection())
                        else:
                            # Send me to me
                            self.send(struct.pack("!BBH8siB", CST.CONNECTION,
                                                    self.id, 8,
                                                    self.enc(self.nick), self.color, 1))

                # map
                exp_world = self.factory.get_world()                
                self.send(get_map_struct(exp_world))

            if msg_type == CST.DOT_COLOR:
                posx, posy = int(bs.read_byte()), int(bs.read_byte())
                if self.energy > CST.DOT_COST:
                    pushed = self.push_dot(posx, posy)
                    if pushed:
                        self.energy -= CST.DOT_COST
                # else:
                #     self.temp_dots.append((posx, posy))

            if msg_type == CST.TOWER:
                log("Tower create")
                posx, posy = int(bs.read_byte()), int(bs.read_byte())
                if self.energy > 25:
                    try:
                        buildable = True
                        world = self.factory.world
                        for (dx, dy) in self.checklist:
                            if world[posx + dx, posy + dy] != self.id:
                                buildable = False
                        if buildable:
                            print("buildable")
                            broadcast(struct.pack("!4B", CST.TOWER, 1, posx, posy))
                            self.towers.append(Tower(posx, posy, world, self))
                            self.energy -= 25
                            # if(self.energy < 0): self.energy = 0
                    except KeyError:
                        pass

            if msg_type == CST.PILLAR:
                log("Pillar create")
                posx, posy = int(bs.read_byte()), int(bs.read_byte())
                print(posx, posy)
                # if self.energy_max // CST.SECTOR_COST > 2:
                try:
                    buildable = True
                    world = self.factory.world
                    if world[posx, posy] != self.id:
                            buildable = False
                    if buildable:
                        print("buildable")
                        broadcast(struct.pack("!5B", CST.PILLAR, 1, self.id, posx, posy))
                        self.pillars.append(Pillar(posx, posy, world, self))
                except KeyError:
                    pass

            if msg_type == CST.MESSAGE:
                chatmsg = bs.read_UTF()
                log(self.nick + " > " + self.dec(chatmsg))
                chatstruct = "!BBH" + str(len(chatmsg)) + "s"
                broadcast(struct.pack(chatstruct, CST.MESSAGE, self.id,
                                            len(chatmsg), chatmsg))

    def onConnect(self, request):
        print("Client connecting: {}".format(request.peer))

    def onOpen(self):
        print("WebSocket connection open.")
        try:
            self.id = self._ids.pop()
            print("ID is ", self.id)
        except IndexError:
            self.sendMessage(struct.pack("!B", CST.FULL), True)
            self.disconnect()

    def onClose(self, wasClean, code, reason):
        log("Connection lost...")
        for tower in self.towers:
            tower.destroy()
        if self in self._registry.values():
            log("...from " + self.nick)
            broadcast(struct.pack("!BB", CST.CONNECTION, self.id))
        self.disconnect()  # Here and not above !
        for (posx, posy), _id in self.factory.world.items():
            if _id == self.id:
                self.factory.world[posx, posy] = 0
                broadcast(struct.pack("!4B", CST.DOT_COLOR, 0, posx, posy))

    def reset(self):
        for tower in self.towers:
            tower._registry.remove(tower)
        self.towers = []
        self.dots = 0

    def disconnect(self):
        self._ids.append(self.id)
        if self in self._registry.values():
            del self._registry[self.id]

    def push_dot(self, posx:int, posy:int):
        world = self.factory.world
        if (posx, posy) in world:
            old_owner_id = world[(posx, posy)]
            if old_owner_id:
                old_owner = Connection._registry[old_owner_id]
                old_owner.dots -= 1
            self.dots += 1
            
            world[(posx, posy)] = self.id
            broadcast(struct.pack("!4B", CST.DOT_COLOR, self.id,
                                                posx, posy))

            return True
        return False

    def send(self, data:bytes):
        self.tosend += data

    def update(self):
        dt = time.time() - self.last_frame_time

        # if len(self.temp_dots) > 0:  # What is this ?
        #     posx, posy = self.temp_dots.pop(0)
        #     self.push_dot(posx, posy)

        self.energy_max = 20 + self.dots * 0.2

        if self.energy_max > 100:
            self.energy_max = 100
        self.energy += CST.DOT_REGEN * dt
        if self.energy > self.energy_max:
            self.energy = self.energy_max
        elif self.energy < 0:
            self.energy = 0

        # if time.clock() - self.energy_time > 1:
        self.send(self.get_datas_update())
        self.energy_time = time.time()

        if len(self.tosend) > 0:
            self.sendMessage(self.tosend, True)
            self.tosend = b''

        self.last_frame_time = time.time()

    def get_datas_connection(self):
        return struct.pack("!BBH8siB", CST.CONNECTION, self.id, 8,
                                        self.enc(self.nick), self.color, 0)

    def get_datas_update(self):
        return struct.pack("!3B", CST.UPDATE, int(self.energy), int(self.energy_max))


def get_map_struct(world):
    return struct.pack("!BB" + str(CST.SIZE ** 2) + "B", CST.MAP, CST.SIZE, *world)


class GameServer(WebSocketServerFactory):
    # protocol = Connection
    game_running = False
    world:World = {}

    def __init__(self, uri):
        WebSocketServerFactory.__init__(self, uri)

        self.gen_world()
        self.tower_time = time.time()
        self.pillar_time = time.time()

        self.l = task.LoopingCall(self.game_loop)
        self.l.start(1 / 10.)

        self.l = task.LoopingCall(self.generate_ranking)
        self.l.start(3)
        print("@@@ Server started @@@")

    def gen_world(self):
        for x in range(0, CST.SIZE):
            for y in range(0, CST.SIZE):
                self.world[(x, y)] = 0

    def get_world(self):
        exp_world = []
        for x in range(0, CST.SIZE):
            for y in range(0, CST.SIZE):
                exp_world.append(self.world[(x, y)])
        return exp_world

    def restart(self):
        for conn in Connection._registry.values():
            conn.reset()

        self.gen_world()
        exp_world = self.get_world()
        broadcast(get_map_struct(exp_world))

    def active_players(self):
        count = 0
        for player in Connection._registry.values():
            if player.dots:
                count += 1
        if count == 0:
            count = 1
        return count

    def generate_ranking(self):
        # Also check end of the game
        for player in Connection._registry.values():
            # if player.dots > CST.SIZE ** 2 / (0.8 * self.active_players()):
            if player.dots > CST.SIZE ** 2 / 0.8:
                log("Game won by " + player.nick)
                broadcast(struct.pack("!BB", CST.WIN, player.id))
                self.restart()
                break

        ranking = {}
        for _id in Connection._registry:
            # count = self.world.values().count(_id)
            count = sum(value == _id for value in self.world.values())
            if count:
                ranking[count] = _id

        ranking = sorted(ranking.items(), reverse=True)
        ranking = [_id for (count, _id) in ranking]
        rank_struct = "!BB" + str(len(ranking)) + "B"
        broadcast(struct.pack(rank_struct, CST.RANKING, len(ranking), *ranking))

    def game_loop(self):
        for connection in Connection._registry.values():
            connection.update()

        if time.time() - self.tower_time > 0.4:
            for tower in Tower._registry:
                tower.propagate()
            self.tower_time = time.time()

        if time.time() - self.pillar_time > 1:
            for pillar in Pillar._registry:
                pillar.attack()
            self.pillar_time = time.time()


if __name__ == '__main__':
    # Game server
    game_server = GameServer(u"ws://127.0.0.1:9999")
    game_server.protocol = Connection
    reactor.listenTCP(9999, game_server)
    # Web server
    # root = static.File("../Export/flash/bin/")
    # web_server = server.Site(root)
    # reactor.listenTCP(8008, web_server)

    reactor.run()
