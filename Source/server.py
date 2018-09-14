import struct
import random
import time

from twisted.internet.protocol import Protocol, Factory
from twisted.internet import reactor
from twisted.internet import task
# from twisted.web import static, server


MESSAGE = 0
CONNECTION = 1
DOT_COLOR = 2
RANKING = 3
MAP = 4
DISCONNECTION = 5
UPDATE = 6
TOWER = 7
FULL = 8
WIN = 9

SIZE = 30
DOT_COST = 10


def log(msg):
    localtime = time.localtime()
    now = time.strftime("<%H:%M:%S>", localtime)
    print now, msg


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


def broadcast(data):
    for connection in Connection._registry.values():
        connection.send(data)


def read_policy():
    with file("mypolicy.xml", 'rb') as f:
        policy = f.read(10001)
        return policy


def eat_dot(_id):
    # pass
    if _id:
        Connection._registry[_id].dots -= 1


class Tower:
    _registry = []

    def __init__(self, x, y, world, owner):
        self._registry.append(self)
        self.owner = owner
        self.world = world
        self.x, self.y = x, y
        self.left = self.right = self.up = self.down = (x, y)

    def propagate(self):
        self.left = (self.left[0] - 1, self.left[1])
        self.right = (self.right[0] + 1, self.right[1])
        self.up = (self.up[0], self.up[1] + 1)
        self.down = (self.down[0], self.down[1] - 1)
        propagating = 4

        if self.left in self.world:
            eat_dot(self.world[self.left])
            self.world[self.left] = self.owner.id
            self.owner.dots += 1
            broadcast(struct.pack("!4B", DOT_COLOR, self.owner.id,
                                                *self.left))
        else:
            propagating -= 1

        if self.right in self.world:
            eat_dot(self.world[self.right])
            self.world[self.right] = self.owner.id
            self.owner.dots += 1
            broadcast(struct.pack("!4B", DOT_COLOR, self.owner.id,
                                                *self.right))
        else:
            propagating -= 1

        if self.up in self.world:
            eat_dot(self.world[self.up])
            self.world[self.up] = self.owner.id
            self.owner.dots += 1
            broadcast(struct.pack("!4B", DOT_COLOR, self.owner.id,
                                                *self.up))
        else:
            propagating -= 1

        if self.down in self.world:
            eat_dot(self.world[self.down])
            self.world[self.down] = self.owner.id
            self.owner.dots += 1
            broadcast(struct.pack("!4B", DOT_COLOR, self.owner.id,
                                                *self.down))
        else:
            propagating -= 1

        if not propagating:
            self.destroy()

    def destroy(self):
        log("Tower destroy")
        self._registry.remove(self)
        self.owner.towers.remove(self)
        broadcast(struct.pack("!4b", TOWER, 0, self.x, self.y))


class Connection(Protocol):
    _registry = {}
    _ids = range(1, 255)
    energy = 100
    dots = 0

    def __init__(self):
        self.energy_max = 20 + self.dots * 0.2
        self.towers = []
        self.last_frame_time = time.time()
        self.temp_dots = []
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

    def reset(self):
        for tower in self.towers:
            tower._registry.remove(tower)
        self.towers = []
        self.dots = 0

    def connectionMade(self):
        log("connection made")
        try:
            self.id = self._ids.pop()
        except IndexError:
            self.transport.write(struct.pack("!b", FULL))
            self.disconnect()

    def connectionLost(self, reason):
        log("Connection lost...")
        for tower in self.towers:
            tower.destroy()
        if self in self._registry.values():
            log("...from " + self.nick)
            broadcast(struct.pack("!BB", DISCONNECTION, self.id))
        self.disconnect()  # Here and not above !
        for (posx, posy), _id in self.factory.world.items():
            if _id == self.id:
                self.factory.world[posx, posy] = 0
                broadcast(struct.pack("!4B", DOT_COLOR, 0, posx, posy))

    def disconnect(self):
        self._ids.append(self.id)
        if self in self._registry.values():
            del self._registry[self.id]

    def dataReceived(self, data):
        if data == "<policy-file-request/>\x00":
            log("Policy file request")
            self.transport.write(read_policy() + "\0")
        else:
            bs.put_data(data)

            while bs.working():
                msg_type = bs.read_byte()

                if msg_type == CONNECTION:
                    # Here to prevent client receiving other clients datas before init
                    self._registry[self.id] = self
                    self.tosend = ""
                    self.nick = bs.read_UTF()
                    self.color = random.randint(0, 0xFFFFFF)
                    self.REALLY_connected = 1
                    log("Connection from " + self.nick)

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
                                self.send(struct.pack("!BBH8siB", CONNECTION,
                                                        self.id, 8,
                                                        self.nick, self.color, 1))

                    # map
                    exp_world = self.factory.get_world()
                    self.send(struct.pack("!B" + str(SIZE ** 2) + "B",
                                                    MAP, *exp_world))

                if msg_type == DOT_COLOR:
                    posx, posy = bs.read_byte(), bs.read_byte()
                    if self.energy > DOT_COST:
                        self.push_dot(posx, posy)
                    else:
                        self.temp_dots.append((posx, posy))

                if msg_type == TOWER:
                    log("Tower create")
                    posx, posy = bs.read_byte(), bs.read_byte()
                    if self.energy_max // 25 > len(self.towers):
                        try:
                            buildable = True
                            world = self.factory.world
                            for (dx, dy) in self.checklist:
                                if world[posx + dx, posy + dy] != self.id:
                                    buildable = False
                            if buildable:
                                broadcast(struct.pack("!4B", TOWER, 1, posx, posy))
                                self.towers.append(Tower(posx, posy, world, self))
                        except KeyError:
                            pass

                if msg_type == MESSAGE:
                    chatmsg = bs.read_UTF()
                    log(self.nick + " > " + chatmsg)
                    chatstruct = "!BBH" + str(len(chatmsg)) + "s"
                    broadcast(struct.pack(chatstruct, MESSAGE, self.id,
                                                len(chatmsg), chatmsg))

    def push_dot(self, posx, posy):
        world = self.factory.world
        if (posx, posy) in world:
            old_owner_id = world[(posx, posy)]
            if old_owner_id:
                old_owner = Connection._registry[old_owner_id]
                old_owner.dots -= 1
            self.dots += 1
            self.energy -= 10
            world[(posx, posy)] = self.id
            broadcast(struct.pack("!4B", DOT_COLOR, self.id,
                                                posx, posy))

    def send(self, data):
        self.tosend += data

    def update(self):
        dt = time.time() - self.last_frame_time

        if len(self.temp_dots) > 0:
            posx, posy = self.temp_dots.pop(0)
            self.push_dot(posx, posy)

        self.energy_max = 20 + self.dots * 0.2
        if self.energy_max > 100:
            self.energy_max = 100
        self.energy += 30 * dt
        if self.energy > self.energy_max:
            self.energy = self.energy_max
        elif self.energy < 0:
            self.energy = 0

        # if time.clock() - self.energy_time > 1:
        self.send(self.get_datas_update())
        self.energy_time = time.time()

        if len(self.tosend) > 0:
            self.transport.write(self.tosend)
            self.tosend = ""

        self.last_frame_time = time.time()

    def get_datas_connection(self):
        return struct.pack("!BBH8siB", CONNECTION, self.id, 8,
                                        self.nick, self.color, 0)

    def get_datas_update(self):
        return struct.pack("!3B", UPDATE, int(self.energy), int(self.energy_max))


class GameServer(Factory):
    protocol = Connection
    game_running = False
    world = {}

    def __init__(self):
        self.gen_world()
        self.tower_time = time.time()

        self.l = task.LoopingCall(self.game_loop)
        self.l.start(1 / 10.)

        self.l = task.LoopingCall(self.generate_ranking)
        self.l.start(3)
        print "@@@ Server started @@@"

    def gen_world(self):
        for x in range(0, SIZE):
            for y in range(0, SIZE):
                self.world[(x, y)] = 0

    def get_world(self):
        exp_world = []
        for x in range(0, SIZE):
            for y in range(0, SIZE):
                exp_world.append(self.world[(x, y)])
        return exp_world

    def restart(self):
        for conn in Connection._registry.values():
            conn.reset()

        self.gen_world()
        exp_world = self.get_world()
        broadcast(struct.pack("!B" + str(SIZE ** 2) + "B",
                                        MAP, *exp_world))

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
            if player.dots > SIZE ** 2 / (0.8 * self.active_players()):
                log("Game won by " + player.nick)
                broadcast(struct.pack("!BB", WIN, player.id))
                self.restart()
                break

        ranking = {}
        for _id in Connection._registry:
            count = self.world.values().count(_id)
            if count:
                ranking[count] = _id

        ranking = sorted(ranking.items(), reverse=True)
        ranking = [_id for (count, _id) in ranking]
        rank_struct = "!BB" + str(len(ranking)) + "B"
        broadcast(struct.pack(rank_struct, RANKING, len(ranking), *ranking))

    def game_loop(self):
        for connection in Connection._registry.values():
            connection.update()

        if time.time() - self.tower_time > 0.4:
            for tower in Tower._registry:
                tower.propagate()
            self.tower_time = time.time()


if __name__ == '__main__':
    # Game server
    game_server = GameServer()
    reactor.listenTCP(9999, game_server)
    # Web server
    # root = static.File("../Export/flash/bin/")
    # web_server = server.Site(root)
    # reactor.listenTCP(8008, web_server)

    reactor.run()
