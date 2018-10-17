import struct
import random
import math
import time
import sys
from typing import *

from twisted.internet import reactor
from twisted.internet import task
from twisted.python import log
from twisted.web import static, server

from autobahn.twisted.websocket import WebSocketServerFactory, WebSocketServerProtocol
import randomcolor

from common import CST
from serverhelpers import *


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

    def put_data(self, data):
        self.data = data
        self.len_data = len(data)
        self.pos = 0

    def read_data_left(self):
        return self.data[self.pos:]

    def read_byte(self):
        size = 1
        byte = self.data[self.pos:self.pos + size]
        byte, = self.byte_struct.unpack(byte)
        self.pos += size
        return byte

    def read_ubyte(self):
        size = 1
        byte = self.data[self.pos:self.pos + size]
        byte, = self.ubyte_struct.unpack(byte)
        self.pos += size
        return byte

    def read_int(self):
        size = 4
        _int = self.data[self.pos:self.pos + size]
        _int, = self.int_struct.unpack(_int)
        self.pos += size
        return _int

    def read_short(self):
        size = 2
        short = self.data[self.pos:self.pos + size]
        short, = self.short_struct.unpack(short)
        self.pos += size
        return short

    def read_UTF(self):
        size = 2
        length = self.data[self.pos:self.pos + size]
        length, = self.short_struct.unpack(length)
        self.pos += size
        string = self.data[self.pos:self.pos + length]
        string, = struct.unpack("!" + str(length) + "s", string)
        self.pos += length
        return string

    def working(self):
        if self.pos == self.len_data:
            return False
        else:
            return True

bs = BinaryStream()


class ToolHx:
    def broadcast_hx(mg, struct_parameters):
        packed = struct.pack(*struct_parameters)
        mg.broadcast(packed)


def read_policy():
    print("policy request")
    with file("mypolicy.xml", 'rb') as f:
        policy = f.read(10001)
        return policy


class Game:
    def __init__(self):
        self.clear_world()
        self.players = {}
        self.pillars = []
        self.towers = []
        self.tower_time = time.time()
        self.pillar_time = time.time()

        # LOOPS
        self.task_game = task.LoopingCall(self.game_loop)
        self.task_game.start(1 / 10.)

        self.task_rank = task.LoopingCall(self.generate_ranking)
        self.task_rank.start(3)

        print("NEW GAME ", id(self))

    def clear_world(self):
        for x in range(0, CST.SIZE):
            for y in range(0, CST.SIZE):
                mg.world[(x, y)] = 0

    def get_world(self):
        exp_world = []

        for x in range(0, CST.SIZE):
            for y in range(0, CST.SIZE):
                exp_world.append(mg.world[(x, y)])

        return exp_world

    def active_players(self):
        count = 0

        for player in players.values():
            if player.dots:
                count += 1

        if count == 0:
            count = 1

        return count

    def generate_ranking(self):
        # Also check end of the game
        for player in self.players.values():
            # if player.dots > CST.SIZE ** 2 / (0.8 * self.active_players()):
            if player.dots > CST.WIN_DOTS:
                log("Game won by " + player.nick)
                mg.broadcast(struct.pack("!BB", CST.WIN, player.id))
                self.task_game.stop()
                self.task_rank.stop()
                self.restart()
                break

        # WHY NOT CLIENT-SIDE ONLY ?
        ranking = {}
        for _id in mg.connections:
            count = sum(value == _id for value in mg.world.values())
            if count:
                ranking[count] = _id

        ranking = sorted(ranking.items(), reverse=True)
        ranking = [_id for (count, _id) in ranking]
        rank_struct = "!BB" + str(len(ranking)) + "B"

        mg.broadcast(struct.pack(rank_struct, CST.RANKING, len(ranking), *ranking))

    def game_loop(self):
        for connection in mg.connections.values():
            connection.update()

        if time.time() - self.tower_time > 0.4:
            for tower in mg.game.towers:
                tower.propagate()
            self.tower_time = time.time()

        if time.time() - self.pillar_time > 1:
            for pillar in mg.game.pillars:
                pillar.attack()
            self.pillar_time = time.time()

    def restart(self):
        # WORLD CLEANUP
        for tower in self.towers:
            tower.destroy()

        for pillar in self.pillars:
            pillar.destroy()

        # NEW GAME NEW WORLD
        mg.game = Game()
        mg.broadcast(get_map_struct(self.get_world()))

        # DO REASSIGN NEW PLAYER TO .PLAYER
        for conn in mg.connections.values():
            conn.reset()


class Player:
    def __init__(self):
        self.energy = CST.ENERGY_DEFAULT
        self.dots = 0
        self.color = 0
        self.nick = ""
        self.energy_max = 20 + self.dots * 0.2

        self.towers = []
        self.pillars = []

    def update(self, dt):
        self.energy_max = 20 + self.dots * 0.2

        if self.energy_max > 100:
            self.energy_max = 100
        self.energy += CST.DOT_REGEN * dt
        if self.energy > self.energy_max:
            self.energy = self.energy_max
        elif self.energy < 0:
            self.energy = 0



class Connection(WebSocketServerProtocol):
    _ids = list(range(1, 255))

    def __init__(self):
        super().__init__()
        self.player = None
        self.color = None
        self.id = None
        self.nick = ""
        self.tosend = b''

        self.last_frame_time = time.time()
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

    def enc(self, string):
        return string.encode("utf-8")

    def dec(self, string):
        return string.decode("utf-8")

    def new_player(self):
        player = Player()
        player.id = self.id
        player.nick = self.nick
        player.color = self.color
        mg.game.players[self.id] = player

        return player

    def onMessage(self, data, isBinary):
        ## echo back message verbatim

        bs.put_data(data)

        while bs.working():
            msg_type = bs.read_byte()

            if msg_type == CST.CONNECTION:
                # Here to prevent client receiving other clients datas before init
                mg.connections[self.id] = self

                print("Num connections", len(mg.connections.values()))
                self.tosend = b''

                # NICKNAME
                self.nick = bs.read_UTF().decode("utf-8")
                log("Connection from " + str(self.nick))

                # RANDOM COLOR
                color, = randomcolor.RandomColor().generate(luminosity="light")
                self.color = int("0x" + color[1:], 16)

                self.player = self.new_player()

                self.REALLY_connected = 1  # HOHO

                # BROADCAST CONNECTION
                for connection in mg.connections.values():
                    if connection.REALLY_connected:
                        if connection != self:
                            # Send players to me
                            self.send(connection.get_datas_connection())
                            # Send me to players
                            connection.send(self.get_datas_connection())
                        else:
                            # Send me to me
                            self.send(self.get_datas_connection(me=1))

                # MAP
                flat_world = mg.game.get_world()
                self.send(get_map_struct(flat_world))

                # SEND TOWERS
                for pillar in mg.game.pillars:
                    print("send tower")
                    self.send(struct.pack("!5B", CST.PILLAR, 1, pillar.owner.id, pillar.x, pillar.y))


            if msg_type == CST.DOT_COLOR:
                posx, posy = int(bs.read_byte()), int(bs.read_byte())
                
                if self.player.energy > CST.DOT_COST:
                    pushed = self.push_dot(posx, posy)
                    if pushed:
                        self.player.energy -= CST.DOT_COST

            if msg_type == CST.TOWER:
                log("Tower create")
                x, y = int(bs.read_byte()), int(bs.read_byte())

                if self.player.energy > 25:
                    buildable = True

                    for (dx, dy) in self.checklist:
                        xt = x + dx
                        yt = y + dy

                        if Tool.valid_position(xt, yt):
                            if mg.world[xt, yt] != self.id:
                                buildable = False
                        else:
                            buildable = False

                    if buildable:
                        print("buildable")
                        mg.broadcast(struct.pack("!4B", CST.TOWER, 1, x, y))
                        mg.game.towers.append(Tower(mg, x, y, self))
                        self.player.energy -= 25


            if msg_type == CST.PILLAR:
                log("Pillar create")
                x, y = int(bs.read_byte()), int(bs.read_byte())

                if self.player.energy > 50:
                    buildable = True

                    if Tool.valid_position(x, y):
                        if mg.world[x, y] != self.id:
                            buildable = False
                    else:
                        buildable = False

                    if buildable:
                        print("buildable")
                        mg.broadcast(struct.pack("!5B", CST.PILLAR, 1, self.id, x, y))
                        mg.game.pillars.append(Pillar(mg, x, y, self))
                        self.player.energy -= 50


            if msg_type == CST.MESSAGE:
                chatmsg = bs.read_UTF()

                log(self.nick + " > " + self.dec(chatmsg))
                chatstruct = "!BBH" + str(len(chatmsg)) + "s"

                mg.broadcast(struct.pack(chatstruct, CST.MESSAGE, self.id,
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
        if self.player is not None:
            for tower in reversed(self.player.towers):
                tower.destroy()

            for pillar in reversed(self.player.pillars):
                pillar.destroy()

        for (posx, posy), _id in mg.world.items():
            if _id == self.id:
                mg.world[posx, posy] = 0
                mg.broadcast(struct.pack("!4B", CST.DOT_COLOR, 0, posx, posy))  # only client-side please

        if self in mg.connections.values():
            mg.broadcast(struct.pack("!BB", CST.DISCONNECTION, self.id))

        self.disconnect()

    def reset(self):
        print("new player")
        self.player = self.new_player()

    def disconnect(self):
        self._ids.append(self.id)

        if self in mg.connections.values():
            del mg.connections[self.id]

    def push_dot(self, posx, posy):

        if (posx, posy) in mg.world:
            old_owner_id = mg.world[(posx, posy)]
            if old_owner_id in mg.game.players:
                old_owner = mg.game.players[old_owner_id]
                old_owner.dots -= 1
            self.player.dots += 1
            
            mg.world[(posx, posy)] = self.id
            mg.broadcast(struct.pack("!4B", CST.DOT_COLOR, self.id,
                                                posx, posy))

            return True
        return False

    def send(self, data):
        self.tosend += data

    def update(self):
        dt = time.time() - self.last_frame_time

        # if len(self.temp_dots) > 0:  # What is this ?
        #     posx, posy = self.temp_dots.pop(0)
        #     self.push_dot(posx, posy)

        self.player.update(dt)

        # if time.clock() - self.energy_time > 1:
        self.send(self.get_datas_update())
        self.energy_time = time.time()

        if len(self.tosend) > 0:
            self.sendMessage(self.tosend, True)
            self.tosend = b''

        self.last_frame_time = time.time()

    def get_datas_connection(self, me=0):
        return struct.pack("!BBH8siB", CST.CONNECTION, self.id, 8,
                                        self.enc(self.nick), self.color, me)

    def get_datas_update(self):
        return struct.pack("!3B", CST.UPDATE, int(self.player.energy), int(self.player.energy_max))


def get_map_struct(world):
    return struct.pack("!BB" + str(CST.SIZE ** 2) + "B", CST.MAP, CST.SIZE, *world)


class GameServer(WebSocketServerFactory):
    def __init__(self, uri):
        WebSocketServerFactory.__init__(self, uri)
        mg.game = Game()
        print("@@@ Server started @@@")


if __name__ == '__main__':
    print(sys.argv[0])

    # Game server
    mg = Manager()
    game_server = GameServer(u"ws://127.0.0.1:9999")
    game_server.protocol = Connection
    reactor.listenTCP(9999, game_server)
    # Web server
    root = static.File("site/")
    web_server = server.Site(root)
    reactor.listenTCP(8008, web_server)

    reactor.run()
