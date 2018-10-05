# Generated by Haxe 3.4.7
# coding: utf-8

import math as python_lib_Math
import math as Math
from server import ToolHx
import functools as python_lib_Functools
import inspect as python_lib_Inspect
import random as python_lib_Random


class _hx_AnonObject:
    def __init__(self, fields):
        self.__dict__ = fields


class Enum:
    _hx_class_name = "Enum"
    __slots__ = ("tag", "index", "params")
    _hx_fields = ["tag", "index", "params"]
    _hx_methods = ["__str__"]

    def __init__(self,tag,index,params):
        self.tag = tag
        self.index = index
        self.params = params

    def __str__(self):
        if (self.params is None):
            return self.tag
        else:
            _this = self.params
            return (((HxOverrides.stringOrNull(self.tag) + "(") + HxOverrides.stringOrNull(",".join([python_Boot.toString1(x1,'') for x1 in _this]))) + ")")



class CST:
    _hx_class_name = "CST"
    __slots__ = ()
    _hx_statics = ["MESSAGE", "CONNECTION", "DOT_COLOR", "RANKING", "MAP", "DISCONNECTION", "UPDATE", "TOWER", "FULL", "WIN", "PILLAR", "PILLAR_ATTACK", "SIZE", "DOT_COST", "DOT_REGEN", "SECTOR_COST", "ENERGY_DEFAULT"]

    def __init__(self):
        pass


class Common:
    _hx_class_name = "Common"
    __slots__ = ()
    _hx_statics = ["main"]

    @staticmethod
    def main():
        pass


class Reflect:
    _hx_class_name = "Reflect"
    __slots__ = ()
    _hx_statics = ["field"]

    @staticmethod
    def field(o,field):
        return python_Boot.field(o,field)


class ServerHelpers:
    _hx_class_name = "ServerHelpers"
    __slots__ = ()
    _hx_statics = ["main"]

    @staticmethod
    def main():
        pass


class Tool:
    _hx_class_name = "Tool"
    __slots__ = ()
    _hx_statics = ["valid_position"]

    @staticmethod
    def valid_position(x,y):
        if (x < 0):
            return False
        if (y < 0):
            return False
        if (x >= 27):
            return False
        if (y >= 27):
            return False
        return True


class Manager:
    _hx_class_name = "Manager"
    __slots__ = ("connections", "world")
    _hx_fields = ["connections", "world"]
    _hx_methods = ["broadcast"]

    def __init__(self):
        self.world = dict()
        self.connections = dict()

    def broadcast(self,data):
        connection = python_HaxeIterator(iter(self.connections.values()))
        while connection.hasNext():
            connection1 = connection.next()
            connection1.send(data)



class Pillar:
    _hx_class_name = "Pillar"
    __slots__ = ("manager", "owner", "world", "x", "y", "checklist")
    _hx_fields = ["manager", "owner", "world", "x", "y", "checklist"]
    _hx_methods = ["attack", "destroy"]
    _hx_statics = ["_registry"]

    def __init__(self,manager,x,y,world,owner):
        self.checklist = None
        self.y = None
        self.x = None
        self.world = None
        self.owner = None
        self.manager = None
        _this = Pillar._registry
        _this.append(self)
        self.manager = manager
        self.owner = owner
        self.world = world
        self.x = x
        self.y = y
        self.checklist = [[-1, 0], [-1, 1], [0, 1], [1, 1], [0, 0], [1, 0], [1, -1], [0, -1], [-1, -1]]

    def attack(self):
        angle = ((python_lib_Random.random() * 2) * Math.PI)
        distance_max = 8
        distance = (1 + ((((distance_max - 1)) * python_lib_Random.random())))
        x = (((Math.NaN if (((angle == Math.POSITIVE_INFINITY) or ((angle == Math.NEGATIVE_INFINITY)))) else python_lib_Math.cos(angle))) * distance)
        x_off = None
        try:
            x_off = int(x)
        except Exception as _hx_e:
            _hx_e1 = _hx_e
            e = _hx_e1
            x_off = None
        x1 = (((Math.NaN if (((angle == Math.POSITIVE_INFINITY) or ((angle == Math.NEGATIVE_INFINITY)))) else python_lib_Math.sin(angle))) * distance)
        y_off = None
        try:
            y_off = int(x1)
        except Exception as _hx_e:
            _hx_e1 = _hx_e
            e1 = _hx_e1
            y_off = None
        target_x = (self.x + x_off)
        target_y = (self.y + y_off)
        if (not Tool.valid_position(target_x,target_y)):
            return
        _g = 0
        _g1 = self.checklist
        while (_g < len(_g1)):
            delta = (_g1[_g] if _g >= 0 and _g < len(_g1) else None)
            _g = (_g + 1)
            x2 = ((self.x + x_off) + (delta[0] if 0 < len(delta) else None))
            y = ((self.y + y_off) + (delta[1] if 1 < len(delta) else None))
            if Tool.valid_position(x2,y):
                self.owner.push_dot(x2,y)
        ToolHx.broadcast_hx(self.manager,["!6B", 11, self.owner.id, self.x, self.y, target_x, target_y])

    def destroy(self):
        print("Pillar destroy")
        python_internal_ArrayImpl.remove(Pillar._registry,self)
        python_internal_ArrayImpl.remove(self.owner.pillars,self)
        ToolHx.broadcast_hx(self.manager,["!4B", 10, 0, self.x, self.y])



class python_Boot:
    _hx_class_name = "python.Boot"
    __slots__ = ()
    _hx_statics = ["keywords", "toString1", "fields", "simpleField", "field", "getInstanceFields", "getSuperClass", "getClassFields", "prefixLength", "unhandleKeywords"]

    @staticmethod
    def toString1(o,s):
        if (o is None):
            return "null"
        if isinstance(o,str):
            return o
        if (s is None):
            s = ""
        if (len(s) >= 5):
            return "<...>"
        if isinstance(o,bool):
            if o:
                return "true"
            else:
                return "false"
        if isinstance(o,int):
            return str(o)
        if isinstance(o,float):
            try:
                if (o == int(o)):
                    return str(Math.floor((o + 0.5)))
                else:
                    return str(o)
            except Exception as _hx_e:
                _hx_e1 = _hx_e
                e = _hx_e1
                return str(o)
        if isinstance(o,list):
            o1 = o
            l = len(o1)
            st = "["
            s = (("null" if s is None else s) + "\t")
            _g1 = 0
            _g = l
            while (_g1 < _g):
                i = _g1
                _g1 = (_g1 + 1)
                prefix = ""
                if (i > 0):
                    prefix = ","
                st = (("null" if st is None else st) + HxOverrides.stringOrNull(((("null" if prefix is None else prefix) + HxOverrides.stringOrNull(python_Boot.toString1((o1[i] if i >= 0 and i < len(o1) else None),s))))))
            st = (("null" if st is None else st) + "]")
            return st
        try:
            if hasattr(o,"toString"):
                return o.toString()
        except Exception as _hx_e:
            _hx_e1 = _hx_e
            pass
        if (python_lib_Inspect.isfunction(o) or python_lib_Inspect.ismethod(o)):
            return "<function>"
        if hasattr(o,"__class__"):
            if isinstance(o,_hx_AnonObject):
                toStr = None
                try:
                    fields = python_Boot.fields(o)
                    _g2 = []
                    _g11 = 0
                    while (_g11 < len(fields)):
                        f = (fields[_g11] if _g11 >= 0 and _g11 < len(fields) else None)
                        _g11 = (_g11 + 1)
                        x = ((("" + ("null" if f is None else f)) + " : ") + HxOverrides.stringOrNull(python_Boot.toString1(python_Boot.simpleField(o,f),(("null" if s is None else s) + "\t"))))
                        _g2.append(x)
                    fieldsStr = _g2
                    toStr = (("{ " + HxOverrides.stringOrNull(", ".join([x1 for x1 in fieldsStr]))) + " }")
                except Exception as _hx_e:
                    _hx_e1 = _hx_e
                    e2 = _hx_e1
                    return "{ ... }"
                if (toStr is None):
                    return "{ ... }"
                else:
                    return toStr
            if isinstance(o,Enum):
                o2 = o
                l1 = len(o2.params)
                hasParams = (l1 > 0)
                if hasParams:
                    paramsStr = ""
                    _g12 = 0
                    _g3 = l1
                    while (_g12 < _g3):
                        i1 = _g12
                        _g12 = (_g12 + 1)
                        prefix1 = ""
                        if (i1 > 0):
                            prefix1 = ","
                        paramsStr = (("null" if paramsStr is None else paramsStr) + HxOverrides.stringOrNull(((("null" if prefix1 is None else prefix1) + HxOverrides.stringOrNull(python_Boot.toString1((o2.params[i1] if i1 >= 0 and i1 < len(o2.params) else None),s))))))
                    return (((HxOverrides.stringOrNull(o2.tag) + "(") + ("null" if paramsStr is None else paramsStr)) + ")")
                else:
                    return o2.tag
            if hasattr(o,"_hx_class_name"):
                if (o.__class__.__name__ != "type"):
                    fields1 = python_Boot.getInstanceFields(o)
                    _g4 = []
                    _g13 = 0
                    while (_g13 < len(fields1)):
                        f1 = (fields1[_g13] if _g13 >= 0 and _g13 < len(fields1) else None)
                        _g13 = (_g13 + 1)
                        x1 = ((("" + ("null" if f1 is None else f1)) + " : ") + HxOverrides.stringOrNull(python_Boot.toString1(python_Boot.simpleField(o,f1),(("null" if s is None else s) + "\t"))))
                        _g4.append(x1)
                    fieldsStr1 = _g4
                    toStr1 = (((HxOverrides.stringOrNull(o._hx_class_name) + "( ") + HxOverrides.stringOrNull(", ".join([x1 for x1 in fieldsStr1]))) + " )")
                    return toStr1
                else:
                    fields2 = python_Boot.getClassFields(o)
                    _g5 = []
                    _g14 = 0
                    while (_g14 < len(fields2)):
                        f2 = (fields2[_g14] if _g14 >= 0 and _g14 < len(fields2) else None)
                        _g14 = (_g14 + 1)
                        x2 = ((("" + ("null" if f2 is None else f2)) + " : ") + HxOverrides.stringOrNull(python_Boot.toString1(python_Boot.simpleField(o,f2),(("null" if s is None else s) + "\t"))))
                        _g5.append(x2)
                    fieldsStr2 = _g5
                    toStr2 = (((("#" + HxOverrides.stringOrNull(o._hx_class_name)) + "( ") + HxOverrides.stringOrNull(", ".join([x1 for x1 in fieldsStr2]))) + " )")
                    return toStr2
            if (o == str):
                return "#String"
            if (o == list):
                return "#Array"
            if callable(o):
                return "function"
            try:
                if hasattr(o,"__repr__"):
                    return o.__repr__()
            except Exception as _hx_e:
                _hx_e1 = _hx_e
                pass
            if hasattr(o,"__str__"):
                return o.__str__([])
            if hasattr(o,"__name__"):
                return o.__name__
            return "???"
        else:
            return str(o)

    @staticmethod
    def fields(o):
        a = []
        if (o is not None):
            if hasattr(o,"_hx_fields"):
                fields = o._hx_fields
                return list(fields)
            if isinstance(o,_hx_AnonObject):
                d = o.__dict__
                keys = d.keys()
                handler = python_Boot.unhandleKeywords
                for k in keys:
                    a.append(handler(k))
            elif hasattr(o,"__dict__"):
                d1 = o.__dict__
                keys1 = d1.keys()
                for k in keys1:
                    a.append(k)
        return a

    @staticmethod
    def simpleField(o,field):
        if (field is None):
            return None
        field1 = (("_hx_" + field) if ((field in python_Boot.keywords)) else (("_hx_" + field) if (((((len(field) > 2) and ((ord(field[0]) == 95))) and ((ord(field[1]) == 95))) and ((ord(field[(len(field) - 1)]) != 95)))) else field))
        if hasattr(o,field1):
            return getattr(o,field1)
        else:
            return None

    @staticmethod
    def field(o,field):
        if (field is None):
            return None
        field1 = field
        _hx_local_0 = len(field1)
        if (_hx_local_0 == 10):
            if (field1 == "charCodeAt"):
                if isinstance(o,str):
                    s1 = o
                    def _hx_local_1(a11):
                        return HxString.charCodeAt(s1,a11)
                    return _hx_local_1
        elif (_hx_local_0 == 11):
            if (field1 == "lastIndexOf"):
                if isinstance(o,str):
                    s3 = o
                    def _hx_local_2(a15):
                        return HxString.lastIndexOf(s3,a15)
                    return _hx_local_2
                elif isinstance(o,list):
                    a4 = o
                    def _hx_local_3(x4):
                        return python_internal_ArrayImpl.lastIndexOf(a4,x4)
                    return _hx_local_3
            elif (field1 == "toLowerCase"):
                if isinstance(o,str):
                    s7 = o
                    def _hx_local_4():
                        return HxString.toLowerCase(s7)
                    return _hx_local_4
            elif (field1 == "toUpperCase"):
                if isinstance(o,str):
                    s9 = o
                    def _hx_local_5():
                        return HxString.toUpperCase(s9)
                    return _hx_local_5
        elif (_hx_local_0 == 9):
            if (field1 == "substring"):
                if isinstance(o,str):
                    s6 = o
                    def _hx_local_6(a19):
                        return HxString.substring(s6,a19)
                    return _hx_local_6
        elif (_hx_local_0 == 4):
            if (field1 == "copy"):
                if isinstance(o,list):
                    def _hx_local_7():
                        return list(o)
                    return _hx_local_7
            elif (field1 == "join"):
                if isinstance(o,list):
                    def _hx_local_8(sep):
                        return sep.join([python_Boot.toString1(x1,'') for x1 in o])
                    return _hx_local_8
            elif (field1 == "push"):
                if isinstance(o,list):
                    x7 = o
                    def _hx_local_9(e):
                        return python_internal_ArrayImpl.push(x7,e)
                    return _hx_local_9
            elif (field1 == "sort"):
                if isinstance(o,list):
                    x11 = o
                    def _hx_local_10(f2):
                        python_internal_ArrayImpl.sort(x11,f2)
                    return _hx_local_10
        elif (_hx_local_0 == 5):
            if (field1 == "shift"):
                if isinstance(o,list):
                    x9 = o
                    def _hx_local_11():
                        return python_internal_ArrayImpl.shift(x9)
                    return _hx_local_11
            elif (field1 == "slice"):
                if isinstance(o,list):
                    x10 = o
                    def _hx_local_12(a16):
                        return python_internal_ArrayImpl.slice(x10,a16)
                    return _hx_local_12
            elif (field1 == "split"):
                if isinstance(o,str):
                    s4 = o
                    def _hx_local_13(d):
                        return HxString.split(s4,d)
                    return _hx_local_13
        elif (_hx_local_0 == 7):
            if (field1 == "indexOf"):
                if isinstance(o,str):
                    s2 = o
                    def _hx_local_14(a13):
                        return HxString.indexOf(s2,a13)
                    return _hx_local_14
                elif isinstance(o,list):
                    a = o
                    def _hx_local_15(x1):
                        return python_internal_ArrayImpl.indexOf(a,x1)
                    return _hx_local_15
            elif (field1 == "reverse"):
                if isinstance(o,list):
                    a5 = o
                    def _hx_local_16():
                        python_internal_ArrayImpl.reverse(a5)
                    return _hx_local_16
            elif (field1 == "unshift"):
                if isinstance(o,list):
                    x14 = o
                    def _hx_local_17(e2):
                        python_internal_ArrayImpl.unshift(x14,e2)
                    return _hx_local_17
        elif (_hx_local_0 == 3):
            if (field1 == "map"):
                if isinstance(o,list):
                    x5 = o
                    def _hx_local_18(f1):
                        return python_internal_ArrayImpl.map(x5,f1)
                    return _hx_local_18
            elif (field1 == "pop"):
                if isinstance(o,list):
                    x6 = o
                    def _hx_local_19():
                        return python_internal_ArrayImpl.pop(x6)
                    return _hx_local_19
        elif (_hx_local_0 == 8):
            if (field1 == "iterator"):
                if isinstance(o,list):
                    x3 = o
                    def _hx_local_20():
                        return python_internal_ArrayImpl.iterator(x3)
                    return _hx_local_20
            elif (field1 == "toString"):
                if isinstance(o,str):
                    s8 = o
                    def _hx_local_21():
                        return HxString.toString(s8)
                    return _hx_local_21
                elif isinstance(o,list):
                    x13 = o
                    def _hx_local_22():
                        return python_internal_ArrayImpl.toString(x13)
                    return _hx_local_22
        elif (_hx_local_0 == 6):
            if (field1 == "charAt"):
                if isinstance(o,str):
                    s = o
                    def _hx_local_23(a1):
                        return HxString.charAt(s,a1)
                    return _hx_local_23
            elif (field1 == "concat"):
                if isinstance(o,list):
                    a12 = o
                    def _hx_local_24(a2):
                        return python_internal_ArrayImpl.concat(a12,a2)
                    return _hx_local_24
            elif (field1 == "filter"):
                if isinstance(o,list):
                    x = o
                    def _hx_local_25(f):
                        return python_internal_ArrayImpl.filter(x,f)
                    return _hx_local_25
            elif (field1 == "insert"):
                if isinstance(o,list):
                    a3 = o
                    def _hx_local_26(a14,x2):
                        python_internal_ArrayImpl.insert(a3,a14,x2)
                    return _hx_local_26
            elif (field1 == "length"):
                if isinstance(o,str):
                    return len(o)
                elif isinstance(o,list):
                    return len(o)
            elif (field1 == "remove"):
                if isinstance(o,list):
                    x8 = o
                    def _hx_local_27(e1):
                        return python_internal_ArrayImpl.remove(x8,e1)
                    return _hx_local_27
            elif (field1 == "splice"):
                if isinstance(o,list):
                    x12 = o
                    def _hx_local_28(a17,a21):
                        return python_internal_ArrayImpl.splice(x12,a17,a21)
                    return _hx_local_28
            elif (field1 == "substr"):
                if isinstance(o,str):
                    s5 = o
                    def _hx_local_29(a18):
                        return HxString.substr(s5,a18)
                    return _hx_local_29
        else:
            pass
        field2 = (("_hx_" + field) if ((field in python_Boot.keywords)) else (("_hx_" + field) if (((((len(field) > 2) and ((ord(field[0]) == 95))) and ((ord(field[1]) == 95))) and ((ord(field[(len(field) - 1)]) != 95)))) else field))
        if hasattr(o,field2):
            return getattr(o,field2)
        else:
            return None

    @staticmethod
    def getInstanceFields(c):
        f = (c._hx_fields if (hasattr(c,"_hx_fields")) else [])
        if hasattr(c,"_hx_methods"):
            f = (f + c._hx_methods)
        sc = python_Boot.getSuperClass(c)
        if (sc is None):
            return f
        else:
            scArr = python_Boot.getInstanceFields(sc)
            scMap = set(scArr)
            _g = 0
            while (_g < len(f)):
                f1 = (f[_g] if _g >= 0 and _g < len(f) else None)
                _g = (_g + 1)
                if (not (f1 in scMap)):
                    scArr.append(f1)
            return scArr

    @staticmethod
    def getSuperClass(c):
        if (c is None):
            return None
        try:
            if hasattr(c,"_hx_super"):
                return c._hx_super
            return None
        except Exception as _hx_e:
            _hx_e1 = _hx_e
            pass
        return None

    @staticmethod
    def getClassFields(c):
        if hasattr(c,"_hx_statics"):
            x = c._hx_statics
            return list(x)
        else:
            return []

    @staticmethod
    def unhandleKeywords(name):
        if (HxString.substr(name,0,python_Boot.prefixLength) == "_hx_"):
            real = HxString.substr(name,python_Boot.prefixLength,None)
            if (real in python_Boot.keywords):
                return real
        return name


class python_HaxeIterator:
    _hx_class_name = "python.HaxeIterator"
    __slots__ = ("it", "x", "has", "checked")
    _hx_fields = ["it", "x", "has", "checked"]
    _hx_methods = ["next", "hasNext"]

    def __init__(self,it):
        self.checked = False
        self.has = False
        self.x = None
        self.it = it

    def next(self):
        if (not self.checked):
            self.hasNext()
        self.checked = False
        return self.x

    def hasNext(self):
        if (not self.checked):
            try:
                self.x = self.it.__next__()
                self.has = True
            except Exception as _hx_e:
                _hx_e1 = _hx_e
                if isinstance(_hx_e1, StopIteration):
                    s = _hx_e1
                    self.has = False
                    self.x = None
                else:
                    raise _hx_e
            self.checked = True
        return self.has



class python_internal_ArrayImpl:
    _hx_class_name = "python.internal.ArrayImpl"
    __slots__ = ()
    _hx_statics = ["concat", "iterator", "indexOf", "lastIndexOf", "toString", "pop", "push", "unshift", "remove", "shift", "slice", "sort", "splice", "map", "filter", "insert", "reverse", "_get"]

    @staticmethod
    def concat(a1,a2):
        return (a1 + a2)

    @staticmethod
    def iterator(x):
        return python_HaxeIterator(x.__iter__())

    @staticmethod
    def indexOf(a,x,fromIndex = None):
        _hx_len = len(a)
        l = (0 if ((fromIndex is None)) else ((_hx_len + fromIndex) if ((fromIndex < 0)) else fromIndex))
        if (l < 0):
            l = 0
        _g1 = l
        _g = _hx_len
        while (_g1 < _g):
            i = _g1
            _g1 = (_g1 + 1)
            if (a[i] == x):
                return i
        return -1

    @staticmethod
    def lastIndexOf(a,x,fromIndex = None):
        _hx_len = len(a)
        l = (_hx_len if ((fromIndex is None)) else (((_hx_len + fromIndex) + 1) if ((fromIndex < 0)) else (fromIndex + 1)))
        if (l > _hx_len):
            l = _hx_len
        while True:
            l = (l - 1)
            tmp = l
            if (not ((tmp > -1))):
                break
            if (a[l] == x):
                return l
        return -1

    @staticmethod
    def toString(x):
        return (("[" + HxOverrides.stringOrNull(",".join([python_Boot.toString1(x1,'') for x1 in x]))) + "]")

    @staticmethod
    def pop(x):
        if (len(x) == 0):
            return None
        else:
            return x.pop()

    @staticmethod
    def push(x,e):
        x.append(e)
        return len(x)

    @staticmethod
    def unshift(x,e):
        x.insert(0, e)

    @staticmethod
    def remove(x,e):
        try:
            x.remove(e)
            return True
        except Exception as _hx_e:
            _hx_e1 = _hx_e
            e1 = _hx_e1
            return False

    @staticmethod
    def shift(x):
        if (len(x) == 0):
            return None
        return x.pop(0)

    @staticmethod
    def slice(x,pos,end = None):
        return x[pos:end]

    @staticmethod
    def sort(x,f):
        x.sort(key= python_lib_Functools.cmp_to_key(f))

    @staticmethod
    def splice(x,pos,_hx_len):
        if (pos < 0):
            pos = (len(x) + pos)
        if (pos < 0):
            pos = 0
        res = x[pos:(pos + _hx_len)]
        del x[pos:(pos + _hx_len)]
        return res

    @staticmethod
    def map(x,f):
        return list(map(f,x))

    @staticmethod
    def filter(x,f):
        return list(filter(f,x))

    @staticmethod
    def insert(a,pos,x):
        a.insert(pos, x)

    @staticmethod
    def reverse(a):
        a.reverse()

    @staticmethod
    def _get(x,idx):
        if ((idx > -1) and ((idx < len(x)))):
            return x[idx]
        else:
            return None


class HxOverrides:
    _hx_class_name = "HxOverrides"
    __slots__ = ()
    _hx_statics = ["eq", "stringOrNull"]

    @staticmethod
    def eq(a,b):
        if (isinstance(a,list) or isinstance(b,list)):
            return a is b
        return (a == b)

    @staticmethod
    def stringOrNull(s):
        if (s is None):
            return "null"
        else:
            return s


class HxString:
    _hx_class_name = "HxString"
    __slots__ = ()
    _hx_statics = ["split", "charCodeAt", "charAt", "lastIndexOf", "toUpperCase", "toLowerCase", "indexOf", "toString", "substring", "substr"]

    @staticmethod
    def split(s,d):
        if (d == ""):
            return list(s)
        else:
            return s.split(d)

    @staticmethod
    def charCodeAt(s,index):
        if ((((s is None) or ((len(s) == 0))) or ((index < 0))) or ((index >= len(s)))):
            return None
        else:
            return ord(s[index])

    @staticmethod
    def charAt(s,index):
        if ((index < 0) or ((index >= len(s)))):
            return ""
        else:
            return s[index]

    @staticmethod
    def lastIndexOf(s,_hx_str,startIndex = None):
        if (startIndex is None):
            return s.rfind(_hx_str, 0, len(s))
        else:
            i = s.rfind(_hx_str, 0, (startIndex + 1))
            startLeft = (max(0,((startIndex + 1) - len(_hx_str))) if ((i == -1)) else (i + 1))
            check = s.find(_hx_str, startLeft, len(s))
            if ((check > i) and ((check <= startIndex))):
                return check
            else:
                return i

    @staticmethod
    def toUpperCase(s):
        return s.upper()

    @staticmethod
    def toLowerCase(s):
        return s.lower()

    @staticmethod
    def indexOf(s,_hx_str,startIndex = None):
        if (startIndex is None):
            return s.find(_hx_str)
        else:
            return s.find(_hx_str, startIndex)

    @staticmethod
    def toString(s):
        return s

    @staticmethod
    def substring(s,startIndex,endIndex = None):
        if (startIndex < 0):
            startIndex = 0
        if (endIndex is None):
            return s[startIndex:]
        else:
            if (endIndex < 0):
                endIndex = 0
            if (endIndex < startIndex):
                return s[endIndex:startIndex]
            else:
                return s[startIndex:endIndex]

    @staticmethod
    def substr(s,startIndex,_hx_len = None):
        if (_hx_len is None):
            return s[startIndex:]
        else:
            if (_hx_len == 0):
                return ""
            return s[startIndex:(startIndex + _hx_len)]

Math.NEGATIVE_INFINITY = float("-inf")
Math.POSITIVE_INFINITY = float("inf")
Math.NaN = float("nan")
Math.PI = python_lib_Math.pi

CST.MESSAGE = 0
CST.CONNECTION = 1
CST.DOT_COLOR = 2
CST.RANKING = 3
CST.MAP = 4
CST.DISCONNECTION = 5
CST.UPDATE = 6
CST.TOWER = 7
CST.FULL = 8
CST.WIN = 9
CST.PILLAR = 10
CST.PILLAR_ATTACK = 11
CST.SIZE = 27
CST.DOT_COST = 1
CST.DOT_REGEN = 3
CST.SECTOR_COST = 25
CST.ENERGY_DEFAULT = 100
Pillar._registry = list()
python_Boot.keywords = set(["and", "del", "from", "not", "with", "as", "elif", "global", "or", "yield", "assert", "else", "if", "pass", "None", "break", "except", "import", "raise", "True", "class", "exec", "in", "return", "False", "continue", "finally", "is", "try", "def", "for", "lambda", "while"])
python_Boot.prefixLength = len("_hx_")

ServerHelpers.main()