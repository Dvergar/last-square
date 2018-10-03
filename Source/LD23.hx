
package;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.display.StageAlign;
import openfl.Assets;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.ui.Keyboard;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.Socket;
import openfl.events.ProgressEvent;
import openfl.external.ExternalInterface;
import openfl.utils.Endian;
import Std;

import motion.Actuate;

import Common.CST;


class TextBlock extends Sprite {
    private var text:openfl.text.TextField;

    public function new(y, msg:String, color:Int, nick:String) {
        super();

        nick = nick.substr(0, 1);
        var textMsg = createText(color, 1, msg);
        textMsg.x = 35;
        textMsg.transform.colorTransform = new openfl.geom.ColorTransform(0.6, 0.6, 0.6);
        this.addChild(textMsg);

        var textNick = createText(color, 1, nick);
        textNick.x = 10;
        textNick.transform.colorTransform = new openfl.geom.ColorTransform(0.7, 0.7, 0.7);
        this.addChild(textNick);

        this.graphics.beginFill(color);
        this.graphics.drawRect(0, 0, Chat.WIDTH, Chat.HEIGHT);
        this.graphics.endFill();
        this.y = openfl.Lib.current.stage.stageHeight - Chat.DY - Chat.HEIGHT;
    }

    private function createText(color, offset, content) {
        var font = Assets.getFont(Game.FONT); 
        var format = new TextFormat (font.fontName); 
        format.size = 26;
        var text:TextField = new TextField();
        text.defaultTextFormat = format;
        text.embedFonts = true;
        text.text = content;
        text.textColor = color;
        // text.y = offset;
        // text.x = offset;
        text.selectable = false;

        text.height = Chat.HEIGHT;
        text.width = Chat.WIDTH;
        return text;
    }

    public function moveUp() {
        this.y -= this.height - 1;
    }
}


class Chat extends Sprite {
    private var text:openfl.text.TextField;
    private var socket:Socket;
    private var messages:Array<TextBlock>;
    public static var WIDTH:Int = 180;
    public static var HEIGHT:Int = 48;
    public static var DY:Int = 50;

    public function new(socket, color:Int) {
        super();
        this.socket = socket;  // Has nothing to do here
        this.messages = new Array();

        var font = Assets.getFont(Game.FONT); 
        var format = new TextFormat (font.fontName); 
        format.size = 26;

        this.text = new openfl.text.TextField();
        this.text.embedFonts = true;
        this.text.defaultTextFormat = format;
        this.text.x = 0;
        this.text.y = openfl.Lib.current.stage.stageHeight - DY;
        this.text.height = Chat.HEIGHT;
        this.text.width = WIDTH;
        // this.text.background = true;
        // this.text.backgroundColor = color;

        // INPUT BOX COLOR
        var s = new Shape();
        s.graphics.clear();
        s.graphics.beginFill(color);
        s.graphics.drawRect(text.x, text.y, text.width, text.height);
        s.graphics.endFill();
        s.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 64, 64, 64);
        addChild(s);

        // CONTOUR
        // this.graphics.clear();
        // this.graphics.beginFill(0xd95b43);
        // this.graphics.drawRect(text.x, text.y, text.width, text.height);
        // this.graphics.endFill();

        // DEBUG
        // this.text.border = true;
        // this.text.borderColor = 0xf44242;

        this.text.wordWrap = true;
        this.text.type = openfl.text.TextFieldType.INPUT;
        this.text.text = "HELLO !";
        this.text.maxChars = 28;
        this.addChild(this.text);

        this.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    private function onKeyDown(event:KeyboardEvent) {
        switch(event.keyCode){
            case Keyboard.ENTER:
                if(this.text.text.length > 0){
                    socket.writeByte(CST.MESSAGE);
                    socket.writeUTF(this.text.text);
                    this.text.text = "";
                }
        }
    }

    public function message(nick:String, msg:String, color:Int) {
        var block = new TextBlock(openfl.Lib.current.stage.stageHeight, msg, color, nick);
        this.addChild(block);

        var i = 0;
        var nbMessages = this.messages.length;
        for(textBlock in this.messages) {
            textBlock.alpha = 1 - (nbMessages - i)*0.1;
            textBlock.moveUp();
            if(textBlock.y < 0) {
                this.removeChild(textBlock);
                this.messages.remove(textBlock);
            }

            i++;
        }
        this.messages.push(block);
    }
}


class Player extends Sprite {
    public var id:Int;
    public var nick:String;
    public var color:Int;
    private var rankText:TextField;
    private var rankText2:TextField;
    public static var HEIGHT:Int = 30;

    public function new(id, nick, color) {
        super();
        this.id = id;
        this.nick = nick.toUpperCase();
        this.color = color;
        this.y = -100;
        // background
        this.graphics.clear();
        this.graphics.beginFill(this.color);
        this.graphics.drawRect(0, 0, Chat.WIDTH, HEIGHT);
        this.graphics.endFill();  

        this.rankText = createText();
        this.addChild(rankText);
        // this.rankText2 = createText(0x000000, 1);
        // this.addChild(rankText2);

        this.addChild(this.rankText);
    }

    private function createText() {
        var font = Assets.getFont(Game.FONT); 
        var format = new TextFormat (font.fontName);
        format.size = 16;
        var text:TextField = new TextField();
        text.defaultTextFormat = format;
        text.embedFonts = true;
        text.text = this.nick;
        text.textColor = color;
        text.x = 10;
        text.y = 6;
        // text.alpha = 0.5;
        text.selectable = false;
        text.transform.colorTransform = new openfl.geom.ColorTransform(0.6, 0.6, 0.6);
        return text;
    }

    public function moveText(y) {
        this.y = y;
    }
}


class Tile extends Sprite {
    public function new(tileX, tileY, color, dx:Int = 0, dy:Int = 0)
    {
        super();
        this.x = tileX * Dot.DOT_SIZE + dx;
        this.y = tileY * Dot.DOT_SIZE + dy;

        this.graphics.clear();
        this.graphics.beginFill(0xd95b43);
        this.graphics.drawRect(0, 0, Dot.DOT_SIZE, Dot.DOT_SIZE);
        this.graphics.endFill();
    }
}


class TileBMP extends Sprite {
    public function new(tileX, tileY, image:String, dx:Int = 0, dy:Int = 0)
    {
        super();
        this.x = tileX * Dot.DOT_SIZE + dx;
        this.y = tileY * Dot.DOT_SIZE + dy;

        addChild(new Bitmap(Assets.getBitmapData("assets/" + image)));
    }

    public function flipX()
    {
        scaleX = -1;
        this.x += this.width;
    }

    public function flipY()
    {
        scaleY = -1;
        this.y += this.height;
    }
}



class Pillar extends Sprite {
    public function new(x, y, color)
    {
        super();
        this.x = Game.BOARD_MARGIN_X + x * Dot.DOT_SIZE;
        this.y = Game.BOARD_MARGIN_Y + y * Dot.DOT_SIZE;

        this.graphics.beginFill(color);
        this.graphics.drawCircle(8, 8, 8);
        this.graphics.endFill();

        this.transform.colorTransform = new openfl.geom.ColorTransform(0.6, 0.6, 0.6);
    }

    public static function attack(color:Int, pillarX:Int, pillarY:Int, attackX:Int, attackY:Int)
    {
        trace("attack");
        var sourcePos = Tool.boardPosition(pillarX, pillarY);
        var targetPos = Tool.boardPosition(attackX, attackY);
        var line = new Shape();
        line.graphics.lineStyle (2, color, 1);
        line.graphics.beginFill(color);
        line.graphics.moveTo(sourcePos[0] + Dot.DOT_SIZE / 2, sourcePos[1] + Dot.DOT_SIZE / 2);
        line.graphics.lineTo(targetPos[0] + Dot.DOT_SIZE / 2, targetPos[1] + Dot.DOT_SIZE / 2);
        line.graphics.endFill();

        line.transform.colorTransform = new openfl.geom.ColorTransform(0.6, 0.6, 0.6);
        openfl.Lib.current.stage.addChild(line);

        Actuate.tween(line, 4, {alpha:0}).onComplete(function() {
            openfl.Lib.current.stage.removeChild(line);
        });
    }
}


class Tool
{
    static public function boardPosition(posx:Int, posy:Int):Array<Int>
    {
        return [Game.BOARD_MARGIN_X + posx * Dot.DOT_SIZE,
                Game.BOARD_MARGIN_Y + posy * Dot.DOT_SIZE];
    }
}

class Dot extends Sprite {
    public static var DEFAULT_COLOR = 0x542437;
    public static var DEFAULT_BORDER_COLOR = 0xE8E8E8;
    public static var DEFAULT_BORDER_SIZE = 1;
    public static var DOT_SIZE = 16;
    public var id:Int;
    private var color:Int;
    private var towerTimer:haxe.Timer;
    private var dotTimer:haxe.Timer;


    public function new(x, y) {
        super();
        this.createDot(DEFAULT_COLOR, DEFAULT_BORDER_COLOR, DEFAULT_BORDER_SIZE);
        this.x = Game.BOARD_MARGIN_X + x * DOT_SIZE;
        this.y = Game.BOARD_MARGIN_Y + y * DOT_SIZE;
        this.id = 0;
        this.color = DEFAULT_COLOR;
        this.dotTimer = new haxe.Timer(1);
    }

    private function createDot(color:Int, borderColor:Int, borderSize:Int) {
        this.graphics.clear();
        // this.graphics.lineStyle(borderSize, borderColor);
        this.graphics.beginFill(color);
        this.graphics.drawRect(0, 0, DOT_SIZE, DOT_SIZE);
        this.graphics.endFill();
        // this.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 0, 0 ,0);
        Actuate.stop(this.transform.colorTransform, null, false, false);
        this.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 14, 14 ,14);
        Actuate.tween(this.transform.colorTransform, 4, {redOffset:0, greenOffset:0, blueOffset:0});
    }

    // public function createPillar() {
    //     this.graphics.beginFill(0xf44542);
    //     this.graphics.drawCircle(8, 8, 8);
    //     this.graphics.endFill();
    //     // this.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 64, 64 ,64);
    // }

    public function createTower() {
        createDot(this.color, 0x1C1C1C, 4);
        this.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 32, 32 ,32);
    }

    public function destroyTower() {
        createDot(this.color, DEFAULT_BORDER_COLOR, DEFAULT_BORDER_SIZE);
    }
    public function focusDot(color:Int) {
        createDot(color, DEFAULT_BORDER_COLOR, DEFAULT_BORDER_SIZE);
        // if(Game.LAGFREE) {
            this.alpha = 0.5;
            this.dotTimer = new haxe.Timer(2000);
            this.dotTimer.run = this.resetDot;
        // }
    }

    private function resetDot() {
        this.alpha = 1;
        this.dotTimer.stop();
        createDot(this.color, DEFAULT_BORDER_COLOR, DEFAULT_BORDER_SIZE);
    }

    public function changeColor(_id:Int, color:Int) {
        if(Game.LAGFREE) {
            this.alpha = 1;
            this.dotTimer.stop();
        }
        createDot(color, DEFAULT_BORDER_COLOR, DEFAULT_BORDER_SIZE);
        this.id = _id;
        this.alpha = 1;
        this.color = color;
    }
}


class Bar extends Sprite {
    private var content:Sprite;
    private var line:Sprite;
    private var realWidth:Int;
    private var skill_cross:Bitmap;
    private var skill_tower:Bitmap;

    public function new(color:Int, board_size:Int) {
        super();
        var WIDTH = board_size * Dot.DOT_SIZE;
        var HEIGHT = 2 * 16;
        var pad = 10;
        this.realWidth = WIDTH - 2 * pad;
        var yOffset = 2*Dot.DOT_SIZE;
        this.x = Game.BOARD_MARGIN_X;
        this.y = Game.BOARD_MARGIN_Y + board_size * Dot.DOT_SIZE + yOffset;

        // // Border
        // this.graphics.lineStyle(bsize, 0xE8E8E8);
        // this.graphics.beginFill(0xD1D1D1);
        // this.graphics.drawRect(0, 0, width, Height);
        // this.graphics.endFill();

        // TILES
        for(x in 0...board_size) {
            this.addChild(new Tile(x, 0, 0xd95b43));
            this.addChild(new Tile(x, 1, 0xd95b43));
        }

        // CORNERS
        var cornerTopLeft = new TileBMP(-1, 0, "corner.png");
        this.addChild(cornerTopLeft);

        var cornerTopRight = new TileBMP(board_size, 0, "corner.png");
        cornerTopRight.flipX();
        this.addChild(cornerTopRight);

        var cornerBottomLeft = new TileBMP(-1, 1, "corner.png");
        cornerBottomLeft.flipY();
        this.addChild(cornerBottomLeft);

        var cornerBottomRight= new TileBMP(board_size, 1, "corner.png");
        cornerBottomRight.flipX();
        cornerBottomRight.flipY();
        this.addChild(cornerBottomRight);

        // Content
        this.content = new Sprite();
        this.content.graphics.beginFill(color);
        this.content.graphics.drawRect(0, pad / 2,
                    realWidth, HEIGHT - pad);
        this.content.graphics.endFill();
        // Positioning from container because scaling is buggy
        this.content.x = pad / 2;
        this.addChild(this.content);

        // Line
        this.line = new Sprite();
        this.line.graphics.beginFill(0xCC2525);
        this.line.graphics.drawRect(pad / 2, pad / 2,
                        3, HEIGHT - pad);
        this.line.graphics.endFill();
        this.addChild(this.line);

        // Tower lines
        var xTower = 25 * realWidth / 100;
        var yTower = pad / 2;
        for(i in 1...4) {
            var tline = new Sprite();
            tline.graphics.beginFill(0xffe17561);
            tline.graphics.drawRect(i * xTower, yTower,
                            3, HEIGHT - pad);
            tline.graphics.endFill();
            this.addChild(tline);
        }

        // PLACE SKILLS
        this.skill_cross = new Bitmap(Assets.getBitmapData("assets/cross.png"));
        skill_cross.x = xTower - skill_cross.width / 2;
        skill_cross.y = yTower + 38;
        this.addChild(skill_cross);

        this.skill_tower = new Bitmap(Assets.getBitmapData("assets/tower.png"));
        skill_tower.x = 2 * xTower - skill_tower.width / 2;
        skill_tower.y = yTower + 38;
        this.addChild(skill_tower);
    }

    var skill1Unlocked = false;
    var skill2Unlocked = false;

    public function unlockSkill(skillNum:Int)
    {
        if(skillNum == 1 && !skill1Unlocked)
        {
            skill_cross.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 64, 64, 64);
            skill1Unlocked = true;
        }
    }

    public function update(energy:Int, energyMax:Int) {
        this.content.scaleX = energy / 100;
        this.line.x = this.realWidth / 100 * energyMax;
    }
}



class Game extends Sprite {
    public static var LAGFREE = true;
    public static var BOARD_MARGIN_X = 250;
    public static var BOARD_MARGIN_Y = 50;
    public static var FONT = "assets/hello-world.ttf";

    private var socket:Socket;
    private var nick:String;
    private var startTime:Int;
    private var id:Int;
    private var myPlayer:Player;
    private var players:Map<String, Player>;
    private var dots:Array<Array<Dot>>;
    private var pillars:Array<Pillar> = new Array();
    private var square:Sprite;
    private var theDot:Dot;
    private var winTimer:haxe.Timer;
    private var energyBar:Bar;
    private var energyBarLF:Bar;
    private var energy:Int = CST.ENERGY_DEFAULT;
    private var energyMax:Int;
    private var LFenergy:Float;
    private var chat:Chat;
    private var winText:TextField;
    private var tick:openfl.media.Sound;
    private var vlam:openfl.media.Sound;
    private var color:Int;

    public function new(nick:String) {
        super();
        this.nick = nick;
        this.id = 0;
        this.players = new Map();
        // this.dots = createDots();
        // this.energy = 0;
        this.LFenergy = this.energy;
        this.tick = Assets.getSound("assets/sound/click1.wav");
        this.vlam = Assets.getSound("assets/sound/click1.wav");
        
        // FPS
        // var fps = new nme.display.FPS();
        // fps.x = 50;
        // this.addChild(fps);

        // SOCKET
        this.socket = new Socket();
        this.socket.endian = BIG_ENDIAN;
        // this.socket.connect("caribou.servebeer.com", 9999);
        // this.socket.connect("carib0u.dyndns.org", 9999);
        this.socket.connect("127.0.0.1", 9999);
        this.socket.addEventListener(Event.CONNECT, onConnect);
        this.socket.addEventListener(ProgressEvent.SOCKET_DATA, dataHandler); 
        this.socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError);
        this.socket.addEventListener(Event.CLOSE, onClose);
        this.socket.addEventListener(IOErrorEvent.IO_ERROR, onError);

        // Events listeners
        this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }


    private function popWin(nick:String) {
        var font = Assets.getFont(Game.FONT); 
        var format = new TextFormat (font.fontName); 
        format.size = 50;
        this.winText = new TextField();
        this.winText.defaultTextFormat = format;
        this.winText.embedFonts = true;
        this.winText.text = nick + " Won";
        this.winText.width = 800;
        this.winText.x = openfl.Lib.current.stage.stageWidth / 2 - 100;
        this.winText.y = openfl.Lib.current.stage.stageHeight / 2;
        this.addChild(this.winText);

        this.winTimer = new haxe.Timer(3000);
        this.winTimer.run = dePopWin;
    }

    private function dePopWin() {
        this.winTimer.stop();
        this.removeChild(this.winText);
    }

    private function popEnergyBar(color:Int, boardSize:Int) {
        this.energyBarLF = new Bar(color, boardSize);
        // this.energyBar.x = 260;
        // this.energyBar.y = openfl.Lib.current.stage.stageHeight - this.energyBar.height;
        this.addChild(this.energyBarLF);

        // if(Game.LAGFREE) {
        //     // this.energyBarLF = new Bar(0x333132, 358, 20);  // Debug
        //     this.energyBarLF = new Bar(color, 358, 40);
        //     this.energyBarLF.x = 260;
        //     this.energyBarLF.y = openfl.Lib.current.stage.stageHeight - this.energyBarLF.height;
        //     this.addChild(this.energyBarLF);
        // }


    }

    private function rankingRefresh(ranking:Array<Int>) {
        var count = 0;
        for(_id in ranking) {
            var player:Player = this.players.get(Std.string(_id));
            player.moveText(count * Player.HEIGHT);
            count += 1;
        }
    }

    var a:Array<Sprite> = new Array();

    private function createDots(SIZE:Int) {
        var xArray:Array<Array<Dot>> = new Array();
        for(x in 0...SIZE) {
            var yArray:Array<Dot> = new Array();
            xArray.push(yArray);
            for(y in 0...SIZE) {
                var dot:Dot = new Dot(x, y);
                this.addChild(dot);
                yArray.push(dot);
            }
        }

        // CONTOUR
        var cornerTopLeft = new TileBMP(-1, -1, "corner.png", Game.BOARD_MARGIN_X, Game.BOARD_MARGIN_Y);
        this.addChild(cornerTopLeft);

        var cornerTopRight = new TileBMP(SIZE, -1, "corner.png", Game.BOARD_MARGIN_X, Game.BOARD_MARGIN_Y);
        cornerTopRight.flipX();
        this.addChild(cornerTopRight);

        var cornerBottomLeft = new TileBMP(-1, SIZE, "corner.png", Game.BOARD_MARGIN_X, Game.BOARD_MARGIN_Y);
        cornerBottomLeft.flipY();
        this.addChild(cornerBottomLeft);

        var cornerBottomRight = new TileBMP(SIZE, SIZE, "corner.png", Game.BOARD_MARGIN_X, Game.BOARD_MARGIN_Y);
        cornerBottomRight.flipX();
        cornerBottomRight.flipY();
        this.addChild(cornerBottomRight);

        for(x in 0...SIZE) {
            this.addChild(new Tile(x, -1, 0xd95b43, Game.BOARD_MARGIN_X, Game.BOARD_MARGIN_Y));
            this.addChild(new Tile(x, SIZE, 0xd95b43, Game.BOARD_MARGIN_X, Game.BOARD_MARGIN_Y));
        }

        for(y in 0...SIZE) {
            this.addChild(new Tile(-1, y, 0xd95b43, Game.BOARD_MARGIN_X, Game.BOARD_MARGIN_Y));
            this.addChild(new Tile(SIZE, y, 0xd95b43, Game.BOARD_MARGIN_X, Game.BOARD_MARGIN_Y));
        }

        return xArray;
    }

    private function onMouseOver(event:MouseEvent) {
        trace("mouseover");
        for(posx in 0...this.dots.length) {
            for(posy in 0...this.dots[posx].length) {
                var dot = this.dots[posx][posy];
                if(event.target == dot){

                    // if(Game.LAGFREE) {
                        if(dot.id != this.id && this.LFenergy > CST.DOT_COST) {
                            // this.LFenergy -= CST.DOT_COST;
                            dot.focusDot(this.color);
                            socket.writeByte(CST.DOT_COLOR);
                            socket.writeByte(posx);
                            socket.writeByte(posy);
                        }
                    // }
                    // else {
                        // if(dot.id != this.id && this.energy > DOT_COST) {
                    //         socket.writeByte(DOT_COLOR);
                    //         socket.writeByte(posx);
                    //         socket.writeByte(posy);
                    //     }
                    // }
                }
            }
        }
    }

    private function onMouseDown(event:MouseEvent) {
        // trace(event);
        for(posx in 0...this.dots.length) {
            for(posy in 0...this.dots[posx].length) {
                var dot = this.dots[posx][posy];
                if(event.target == dot){  // PLEASE...
                    if(dot.id == this.id) {
                        socket.writeByte(CST.TOWER);
                        socket.writeByte(posx);
                        socket.writeByte(posy);
                    }
                }
            }
        }
    }

    private function onRightMouseDown(event:MouseEvent) {
        trace(event);
        for(posx in 0...this.dots.length) {
            for(posy in 0...this.dots[posx].length) {
                var dot = this.dots[posx][posy];
                if(event.target == dot){  // PLEASE...
                    if(dot.id == this.id) {
                        socket.writeByte(CST.PILLAR);
                        socket.writeByte(posx);
                        socket.writeByte(posy);
                    }
                }
            }
        }
    }

    private function onEnterFrame(event:Event):Void {
        var elapsedTime:Float = Lib.getTimer() - this.startTime;

        if (elapsedTime > 1000 / 10) {
            // if(Game.LAGFREE) {
                if(this.id != 0) {
                    this.LFenergy += CST.DOT_REGEN * elapsedTime / 1000;
                    if(this.LFenergy > this.energyMax) {
                        this.LFenergy = this.energyMax;
                    }

                    else if(this.LFenergy < 0) {
                        this.LFenergy = 0;
                    }
                    this.energyBarLF.update(Std.int(this.LFenergy), Std.int(this.energyMax));
                }
            // }

            socket.flush();
            this.startTime = Lib.getTimer();
        }
    }

    private function dataHandler(event:ProgressEvent) {
        while(socket.bytesAvailable > 0) {
            var msgType = socket.readUnsignedByte();

            if(msgType == CST.CONNECTION) {
                var _id = socket.readUnsignedByte();
                trace("bytesavailable " + socket.bytesAvailable);
                var nick = socket.readUTF();
                trace("bytesavailable " + socket.bytesAvailable);
                var color = socket.readInt();
                var me = socket.readUnsignedByte();
                trace("color is " + color);

                var player = new Player(_id, nick, color);
                this.addChild(player);

                if(me == 1) {
                    this.id = _id;
                    this.myPlayer = player;
                    this.color = color;
                }
                this.players.set(Std.string(_id), player);

                // SPAWN CHAT
                this.chat = new Chat(this.socket, this.color);
                this.addChild(this.chat);

                trace("connection from " + _id);
                trace("connection from " + nick);
                trace("Is it me ?" + me);
            }

            if(msgType == CST.DISCONNECTION) {
                var _id = socket.readUnsignedByte();
                for(player in this.players) {
                }
                var player = this.players.get(Std.string(_id));

                // Remove references
                this.removeChild(player);
                this.players.remove(Std.string(_id));
            }

            if(msgType == CST.TOWER) {
                var flag = socket.readUnsignedByte();
                var posx = socket.readUnsignedByte();
                var posy = socket.readUnsignedByte();
                if(flag == 1) {
                    this.dots[posx][posy].createTower();
                    this.vlam.play();
                }
                else {
                    this.dots[posx][posy].destroyTower();
                }
            }

            if(msgType == CST.PILLAR) {
                var flag = socket.readUnsignedByte();
                var ownerId = socket.readUnsignedByte();
                var player = this.players.get(Std.string(ownerId));
                var posx = socket.readUnsignedByte();
                var posy = socket.readUnsignedByte();
                if(flag == 1) {
                    var pillar = new Pillar(posx, posy, player.color);
                    addChild(pillar);
                    pillars.push(pillar);
                    // this.dots[posx][posy].createPillar();
                    // this.vlam.play();
                }
                // else {
                //     this.dots[posx][posy].destroyTower();
                // }
            }

            if(msgType == CST.PILLAR_ATTACK) {
                var ownerId = socket.readUnsignedByte();
                var player = this.players.get(Std.string(ownerId));
                var pillarX = socket.readUnsignedByte();
                var pillarY = socket.readUnsignedByte();
                var attackX = socket.readUnsignedByte();
                var attackY = socket.readUnsignedByte();
                Pillar.attack(player.color, pillarX, pillarY, attackX, attackY);
            }

            if(msgType == CST.UPDATE) {
                var energy = socket.readUnsignedByte();
                this.energyMax = socket.readUnsignedByte();
                this.energy = energy;
                this.LFenergy = energy;
                this.energyBarLF.update(energy, this.energyMax);

                if(this.energy > 25) energyBarLF.unlockSkill(1);
            }

            if(msgType == CST.MAP) {
                var SIZE:Int = socket.readUnsignedByte();
                this.dots = createDots(SIZE);

                for(x in 0...SIZE) {
                    for(y in 0...SIZE) {
                        var _id = socket.readUnsignedByte();
                        if(_id != 0) {
                            var player = this.players.get(Std.string(_id));
                            var color = player.color;
                            this.dots[x][y].changeColor(_id, color);
                        }
                        else {
                            this.dots[x][y].changeColor(_id, Dot.DEFAULT_COLOR);
                        }
                    }
                }

                // ATTACH EVENTS
                Lib.current.stage.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
                Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
                Lib.current.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);

                // AWFUL BUT LET'S JUST PROTOTYPE FOR NOW
                if(this.id != 0) // aka me aka first connection, differentiate from new map from win
                {
                    popEnergyBar(color, SIZE);
                }
            }

            if(msgType == CST.DOT_COLOR) {
                trace("dot_color");
                var _id = socket.readUnsignedByte();
                var posx = socket.readUnsignedByte();
                var posy = socket.readUnsignedByte();
                if(_id != 0) {
                    var player = this.players.get(Std.string(_id));
                    var color:Int = player.color;
                    this.dots[posx][posy].changeColor(_id, color);
                    if(_id == this.id){
                        this.tick.play();
                    }
                }
                else {
                    this.dots[posx][posy].changeColor(_id, Dot.DEFAULT_COLOR);
                }
            }

            if(msgType == CST.MESSAGE) {
                var _id = socket.readUnsignedByte();
                trace("message from " + _id);
                var chatMsg = socket.readUTF().toUpperCase ();

                var nick = this.players.get(Std.string(_id)).nick;
                var color = this.players.get(Std.string(_id)).color;

                this.chat.message(nick, chatMsg, color);
            }

            if(msgType == CST.WIN) {
                var _id = socket.readUnsignedByte();
                var nick = this.players.get(Std.string(_id)).nick;
                popWin(nick);
            }

            if(msgType == CST.RANKING) {
                var rankNb = socket.readUnsignedByte();
                var ranking = new Array();
                for(i in 0...rankNb) {
                    var _id = socket.readUnsignedByte();
                    ranking.push(_id);
                    this.rankingRefresh(ranking);
                }
            }

            if(msgType == CST.FULL) {
                trace("SERVER FULL");
            }

        }
    }

    private function onConnect(event:Event) {

        socket.writeByte(CST.CONNECTION);
        socket.writeUTF(this.nick);
    }

    private function onClose(event:Event) {
        trace("disconnected");
    }

    private function onError(event:Event) {
        trace("socket error");
    }

    private function onSecError(event:Event) {
        trace("socket security error");
    }
}


class LD23 extends Sprite {
    private var login:TextField;
    private var intro:Bitmap;

    public function new() {
        super();
        this.intro = new Bitmap(Assets.getBitmapData("assets/intro.png"));
        popLogin();
    }

    private function popLogin() {
        var bg = new Bitmap(Assets.getBitmapData("assets/login.png"));
        this.addChild(bg);
        // var font = Assets.getFont("assets/FFFFT___.TTF");
        var font = Assets.getFont(Game.FONT);
        var format = new TextFormat (font.fontName); 
        format.size = 10;
        this.login = new TextField();
        this.login.defaultTextFormat = format;
        this.login.embedFonts = true;
        this.login.type = openfl.text.TextFieldType.INPUT;
        this.login.text = "Guest";
        this.login.maxChars = 8;
        this.login.height = 20;
        this.login.border = true;
        this.login.x = openfl.Lib.current.stage.stageWidth / 2 - this.login.width / 2;
        this.login.y = openfl.Lib.current.stage.stageWidth / 2 - 100;
        this.addChild(this.login);

        // PREVENT RIGHT CLICK
        openfl.Lib.current.stage.showDefaultContextMenu = false;

        this.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        this.addEventListener(MouseEvent.CLICK, onMouseClick);
    }

    private function popGame() {
        this.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        Lib.current.removeChild(this);
        Lib.current.addChild(new Game(this.login.text));
    }

    private function onMouseClick(event:MouseEvent) {
        // DEBUG
        popGame();
    }

    private function onKeyDown(event:KeyboardEvent) {
        switch(event.keyCode){
            case Keyboard.ENTER:
                popGame();
        }
    }

    public static function main() {
        Lib.current.addChild(new LD23());
    }
}
