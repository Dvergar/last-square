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


class Manager
{
	public var connections:python.Dict<Int, Connection> = new python.Dict();

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
    public function push_dot(x:Int, y:Int):Bool;
    public function send(data:String):Void;
}


class Pillar
{
	public static var _registry:Array<Pillar> = new Array();
	private var owner:Connection;
	private var world:Dynamic;
	private var x:Int;
	private var y:Int;
	private var checklist:Array<Array<Int>>;
	private var manager:Manager;

	public function new(manager:Manager, x:Int, y:Int, world:Dynamic, owner:Connection)
	{
		this.manager = manager;
		_registry.push(this);
		this.owner = owner;
		this.world = world;
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