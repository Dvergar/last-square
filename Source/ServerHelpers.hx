import python.Dict;
import python.Tuple;

import Common;


class ServerHelpers {
    public static function main() {}
}


class Tool
{
	public static function valid_position(x:Int, y:Int)
	{
	    if(x < 0) return false;
	    if(y < 0) return false;

	    if(x >= CST.SIZE) return false;
	    if(y >= CST.SIZE) return false;

	    return true;
	}
}


typedef World = Dict<Tuple2<Int, Int>, Int>;


class Manager
{
	public var connections:Dict<Int, Connection> = new Dict();
	public var world:World = new Dict();

    function new() {}

    public function broadcast(data)
    {
        for(connection in this.connections.values())
            connection.send(data);
    }
}


@:pythonImport("server", "ToolHx")
extern class ToolHx
{
    public static function broadcast_hx(manager:Manager, args:Array<Dynamic>):Void;
    public static function debug_broadcast(manager:Manager):Void;
    public static function broadcast_pillar_attack_hx(f:String, c:Int, id:Int, x:Int, y:Int, tx:Int, ty:Int):Void;
}


@:pythonImport("server", "Connection")
extern class Connection
{
	public var _ids:Array<Int>;
	public var id:Int;
    public var pillars:Array<Dynamic>;
    public var towers:Array<Dynamic>;
    public function push_dot(x:Int, y:Int):Bool;
    public function send(data:String):Void;
}


class Tower
{
	public static var _registry:Array<Tower> = new Array();
	private var manager:Manager;
	private var owner:Connection;
	private var x:Int;
	private var y:Int;
	private var left:Tuple2<Int, Int>;
	private var right:Tuple2<Int, Int>;
	private var up:Tuple2<Int, Int>;
	private var down:Tuple2<Int, Int>;

	public function new(manager:Manager, x:Int, y:Int, owner:Connection)
	{
		_registry.push(this);
		this.manager = manager;
		this.owner = owner;
		this.x = x;
		this.y = y;
		this.left = Tuple2.make(x, y);
		this.right = Tuple2.make(x, y);
		this.up = Tuple2.make(x, y);
		this.down = Tuple2.make(x, y);
	}

	public function propagate()
	{

		// WHY A TUPLE THEN ?
        this.left = Tuple2.make(left._1 - 1, left._2);
        this.right = Tuple2.make(right._1 + 1, right._2);
        this.up = Tuple2.make(up._1, up._2 + 1);
        this.down = Tuple2.make(down._1, down._2 - 1);


        var propagating = 4;

        if(manager.world.hasKey(this.left))
        {
            this.owner.push_dot(this.left._1, this.left._2);
        }
        else
        {
            propagating -= 1;
        }

        if(manager.world.hasKey(this.right))
        {
            this.owner.push_dot(this.right._1, this.right._2);
        }
        else
        {
            propagating -= 1;
        }

        if(manager.world.hasKey(this.up))
        {
            this.owner.push_dot(this.up._1, this.up._2);
        }
        else
        {
            propagating -= 1;
        }

        if(manager.world.hasKey(this.down))
        {
            this.owner.push_dot(this.down._1, this.down._2);
        }
        else
        {
            propagating -= 1;
        }

        if(propagating <= 0)
            this.destroy();
	}

	public function destroy()
	{
        trace("Tower destroy");
        _registry.remove(this);
        this.owner.towers.remove(this);
        ToolHx.broadcast_hx(this.manager, ["!4B", CST.TOWER, 0, this.x, this.y]);
	}
}



class Pillar
{
	public static var _registry:Array<Pillar> = new Array();
	private var manager:Manager;
	private var owner:Connection;
	private var x:Int;
	private var y:Int;
	private var checklist:Array<Array<Int>>;

	public function new(manager:Manager, x:Int, y:Int, owner:Connection)
	{
		_registry.push(this);
		this.manager = manager;
		this.owner = owner;
		this.x = x;
		this.y = y;
		this.checklist = [
                        [-1, 0],
                        [-1, 1],
                        [0, 1],
                        [1, 1],
                        [0, 0],
                        [1, 0],
                        [1, -1],
                        [0, -1],
                        [-1, -1]
                        ];
	}

	public function attack()
	{
        var angle:Float = Math.random() * 2 * Math.PI;
        var distance_max:Int = 8;
        var distance:Float = 1 + (distance_max - 1) * Math.random();
        var x_off:Int = Std.int(Math.cos(angle) * distance);
        var y_off:Int = Std.int(Math.sin(angle) * distance);
        var target_x:Int = this.x + x_off;
        var target_y:Int = this.y + y_off;

        if(!Tool.valid_position(target_x, target_y))
            return;

        for(delta in this.checklist)
        {        	
            var x = this.x + x_off + delta[0];
            var y = this.y + y_off + delta[1];
            if(Tool.valid_position(x, y))
                this.owner.push_dot(x, y);
        }

        ToolHx.broadcast_hx(this.manager, ["!6B", CST.PILLAR_ATTACK, this.owner.id, this.x, this.y, target_x, target_y]);
    }

    public function destroy()
    {
        trace("Pillar destroy");
        _registry.remove(this);
        this.owner.pillars.remove(this);
        ToolHx.broadcast_hx(this.manager, ["!4B", CST.PILLAR, 0, this.x, this.y]);
    }
}