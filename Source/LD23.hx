
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
import openfl.utils.Endian;
import Std;

import motion.Actuate;

import Common.CST;


class TextBlock extends Sprite {
    private var text:openfl.text.TextField;
    private var color:Int;

    public function new(y:Int, msg:String, color:Int, nick:String)
    {
        super();
        this.color = color;

        // NICKNAME
        nick = nick.substr(0, 1);  // KEEP ONLY FIRST NICKNAME LETTER
        var textNick = createText(10 , nick);
        textNick.transform.colorTransform = new openfl.geom.ColorTransform(0.7, 0.7, 0.7);
        this.addChild(textNick);

        // MESSAGE
        var textMsg = createText(35, msg);
        textMsg.transform.colorTransform = new openfl.geom.ColorTransform(0.6, 0.6, 0.6);
        this.addChild(textMsg);

        // CONTAINER
        this.graphics.beginFill(color);
        this.graphics.drawRect(0, 0, Game.COLUMN_WIDTH, Chat.HEIGHT);
        this.graphics.endFill();
        this.y = openfl.Lib.current.stage.stageHeight - Chat.DY - Chat.HEIGHT;
    }

    private function createText(x:Int, content:String)
    {
        var text = Tool.getTextField(x, 0, content, 26);
        text.selectable = false;
        text.textColor = color;
        text.width = Game.COLUMN_WIDTH;
        text.height = Chat.HEIGHT;

        return text;
    }

    public function moveUp() {
        this.y -= this.height - 1;
    }
}


class Chat extends Sprite {
    private var msg:openfl.text.TextField = new openfl.text.TextField();
    private var socket:Socket;
    private var messages:Array<TextBlock>;

    public static var HEIGHT:Int = 48;
    public static var DY:Int = 50;

    public function new(socket, color:Int)
    {
        super();
        this.socket = socket;  // Has nothing to do here
        this.messages = new Array();

        // TEXT
        var msgY = openfl.Lib.current.stage.stageHeight - DY;
        this.msg = Tool.getTextField(0, msgY, "HELLO !", 26);
        this.msg.type = openfl.text.TextFieldType.INPUT;
        this.msg.wordWrap = true;
        this.msg.maxChars = 15;
        this.msg.height = HEIGHT;
        this.msg.width = Game.COLUMN_WIDTH;
        this.msg.textColor = color;
        this.msg.transform.colorTransform = new openfl.geom.ColorTransform(0.6, 0.6, 0.6);

        // INPUT BOX COLOR
        var inputBox = new Shape();
        inputBox.graphics.clear();
        inputBox.graphics.beginFill(color);
        inputBox.graphics.drawRect(msg.x, msg.y, msg.width, msg.height);
        inputBox.graphics.endFill();
        inputBox.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 64, 64, 64);


        this.addChild(inputBox);
        this.addChild(this.msg);

        this.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

        // CONTOUR
        // this.graphics.clear();
        // this.graphics.beginFill(0xd95b43);
        // this.graphics.drawRect(msg.x, msg.y, msg.width, msg.height);
        // this.graphics.endFill();

        // DEBUG
        // this.msg.border = true;
        // this.msg.borderColor = 0xf44242;
    }

    private function onKeyDown(event:KeyboardEvent)
    {
        switch(event.keyCode){
            case Keyboard.ENTER:
                if(this.msg.text.length > 0){
                    socket.writeByte(CST.MESSAGE);
                    socket.writeUTF(this.msg.text);
                    this.msg.text = "";
                }
        }
    }

    public function message(nick:String, text:String, color:Int)
    {
        var block = new TextBlock(openfl.Lib.current.stage.stageHeight, text, color, nick);
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


class Rank extends Sprite
{
    public var id:Int;
    public var nick:String;
    public var color:Int;
    private var rankText:TextField;
    private static inline var HEIGHT:Int = 30;

    public function new(id:Int, nick:String, color:Int)
    {
        super();
        this.id = id;
        this.nick = nick.toUpperCase();
        this.color = color;
        this.y = 0;

        // BACKGROUND
        this.graphics.clear();
        this.graphics.beginFill(this.color);
        this.graphics.drawRect(0, 0, Game.COLUMN_WIDTH, HEIGHT);
        this.graphics.endFill();  

        this.rankText = createText();
        this.addChild(rankText);
    }

    private function createText()
    {
        trace("Rank ceratetext");
        var text = Tool.getTextField(10, 6, this.nick, 16);
        text.selectable = false;
        text.textColor = color;
        text.transform.colorTransform = new openfl.geom.ColorTransform(0.6, 0.6, 0.6);

        return text;
    }

    public function moveText(k)
    {
        this.y = k * HEIGHT;
    }
}


class Tile extends Sprite
{
    public function new(tileX:Int, tileY:Int, color:Int, dx:Int = 0, dy:Int = 0)
    {
        super();
        this.x = tileX * Dot.SIZE + dx;
        this.y = tileY * Dot.SIZE + dy;

        this.graphics.clear();
        this.graphics.beginFill(0xd95b43);
        this.graphics.drawRect(0, 0, Dot.SIZE, Dot.SIZE);
        this.graphics.endFill();
    }
}


class TileBMP extends Sprite
{
    public function new(tileX:Int, tileY:Int, image:String, dx:Int = 0, dy:Int = 0)
    {
        super();
        this.x = tileX * Dot.SIZE + dx;
        this.y = tileY * Dot.SIZE + dy;

        this.addChild(new Bitmap(Assets.getBitmapData("assets/" + image)));
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



class Pillar extends Sprite
{
    public var ownerId:Int;

    public function new(ownerId:Int, tileX:Int, tileY:Int, color:Int)
    {
        super();
        this.ownerId = ownerId;
        this.x = Tool.ToPixelX(tileX);
        this.y = Tool.ToPixelY(tileY);

        // TOWER GRAPHICS
        this.graphics.beginFill(color);
        this.graphics.drawCircle(8, 8, 8);
        this.graphics.endFill();
        this.transform.colorTransform = new openfl.geom.ColorTransform(0.6, 0.6, 0.6);
    }

    public static function attack(color:Int, sourceTileX:Int, sourceTileY:Int,
                                            targetTileX:Int, targetTileY:Int)
    {
        var sourceX = Tool.ToPixelX(sourceTileX) + Dot.SIZE / 2;
        var sourceY = Tool.ToPixelY(sourceTileY) + Dot.SIZE / 2;
        var targetX = Tool.ToPixelX(targetTileX) + Dot.SIZE / 2;
        var targetY = Tool.ToPixelY(targetTileY) + Dot.SIZE / 2;

        // LINE BETWEEN PILLAR AND ATTACK BLOCK
        var line = new Shape();
        line.graphics.lineStyle (2, color, 1);
        line.graphics.beginFill(color);
        line.graphics.moveTo(sourceX, sourceY);
        line.graphics.lineTo(targetX, targetY);
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
    static inline public inline function ToPixelX(tileX:Int)
        return Game.BOARD_MARGIN_X + tileX * Dot.SIZE;

    static inline public function ToPixelY(tileY:Int)
        return Game.BOARD_MARGIN_Y + tileY * Dot.SIZE;

    static inline public function getTextField(x:Float, y:Float, text:String, size:Int)
    {
        var font = Assets.getFont(Game.FONT);
        var format = new TextFormat (font.fontName); 
        format.size = size;

        var textField = new TextField();
        textField.defaultTextFormat = format;
        textField.embedFonts = true;
        textField.text = text;
        textField.x = x;
        textField.y = y;

        return textField;
    }
}


class Dot extends Sprite
{
    public static inline var DEFAULT_COLOR = 0x542437;
    public static inline var SIZE = 16;
    public var id:Int;
    private var color:Int;
    private var towerTimer:haxe.Timer;
    private var dotTimer:haxe.Timer;


    public function new(tileX, tileY) {
        super();
        this.createDot(DEFAULT_COLOR);
        this.id = 0;
        this.x = Tool.ToPixelX(tileX);
        this.y = Tool.ToPixelY(tileY);
        // this.color = DEFAULT_COLOR;
        this.dotTimer = new haxe.Timer(1);
    }

    private function createDot(color:Int) {
        this.graphics.clear();
        this.graphics.beginFill(color);
        this.graphics.drawRect(0, 0, SIZE, SIZE);
        this.graphics.endFill();

        // CLIENT-SIDE PREDICTION
        // this.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 0, 0 ,0);
        Actuate.stop(this.transform.colorTransform, null, false, false);
        this.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 14, 14 ,14);
        Actuate.tween(this.transform.colorTransform, 4, {redOffset:0, greenOffset:0, blueOffset:0});
    }

    public function createTower()
    {
        // createDot(this.color);
        this.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 32, 32 ,32);
    }

    public function destroyTower()
    {
        // createDot(this.color, DEFAULT_BORDER_COLOR, DEFAULT_BORDER_SIZE);
    }

    public function focusDot(newColor:Int)
    {
        createDot(newColor);
        // if(Game.LAGFREE) {
            this.alpha = 0.5;
            this.dotTimer = new haxe.Timer(2000);
            this.dotTimer.run = this.resetDot;
        // }
    }

    private function resetDot()
    {
        this.alpha = 1;
        this.dotTimer.stop();
        createDot(this.color);
    }

    public function changeColor(_id:Int, newColor:Int)
    {
        if(Game.LAGFREE) {
            this.alpha = 1;
            this.dotTimer.stop();
        }
        createDot(newColor);
        this.id = _id;
        this.alpha = 1;
        this.color = newColor;
    }
}


class Bar extends Sprite
{
    private var content:Sprite;
    private var line:Sprite;
    private var realWidth:Int;
    private var skill_cross:Bitmap;
    private var skill_tower:Bitmap;

    public function new(color:Int) {
        super();
        var WIDTH = CST.SIZE * Dot.SIZE;
        var HEIGHT = 2 * 16;
        var pad = 10;
        this.realWidth = WIDTH - 2 * pad;
        var yOffset = 2*Dot.SIZE;
        this.x = Game.BOARD_MARGIN_X;
        this.y = Game.BOARD_MARGIN_Y + CST.SIZE * Dot.SIZE + yOffset;

        // // Border
        // this.graphics.lineStyle(bsize, 0xE8E8E8);
        // this.graphics.beginFill(0xD1D1D1);
        // this.graphics.drawRect(0, 0, width, Height);
        // this.graphics.endFill();

        // TILES
        for(tileX in 0...CST.SIZE){
            this.addChild(new Tile(tileX, 0, 0xd95b43));
            this.addChild(new Tile(tileX, 1, 0xd95b43));
        }

        // CORNERS
        var cornerTopLeft = new TileBMP(-1, 0, "corner.png");
        this.addChild(cornerTopLeft);

        var cornerTopRight = new TileBMP(CST.SIZE, 0, "corner.png");
        cornerTopRight.flipX();
        this.addChild(cornerTopRight);

        var cornerBottomLeft = new TileBMP(-1, 1, "corner.png");
        cornerBottomLeft.flipY();
        this.addChild(cornerBottomLeft);

        var cornerBottomRight= new TileBMP(CST.SIZE, 1, "corner.png");
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
        for(i in 1...4)
        {
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

    public function update(energy:Int, energyMax:Int)
    {
        this.content.scaleX = energy / 100;
        this.line.x = this.realWidth / 100 * energyMax;
    }
}


class Player
{
    public var id:Int;
    public var nick:String;
    public var color:Int;

    public function new(id:Int, nick:String, color:Int)
    {
        this.id = id;
        this.nick = nick;
        this.color = color;
    }
}


class Game extends Sprite
{
    public static var COLUMN_WIDTH = 230;
    public static var LAGFREE = true;
    public static var BOARD_MARGIN_X = 300;
    public static var BOARD_MARGIN_Y = 50;
    public static var FONT = "assets/hello-world.ttf";

    // PLAYER
    private var nick:String;
    private var id:Int = 0;
    private var color:Int;
    private var energy:Int = CST.ENERGY_DEFAULT;
    private var LFenergy:Float = CST.ENERGY_DEFAULT;
    private var energyMax:Int;

    // UI
    private var energyBar:Bar;
    private var energyBarLF:Bar;
    private var ranks:Map<Int, Rank> = new Map();
    private var chat:Chat;
    
    // SOUND
    private var tick:openfl.media.Sound = Assets.getSound("assets/sound/click1.wav");
    private var vlam:openfl.media.Sound = Assets.getSound("assets/sound/click1.wav");

    // WORLD
    private var players:Map<Int, Player> = new Map();
    private var dots:Array<Array<Dot>>;
    private var pillars:Array<Pillar> = new Array();
    
    // MISC
    private var socket:Socket;
    private var startTime:Int;
    private var winTimer:haxe.Timer;
    private var winText:TextField;

    public function new(nick:String)
    {
        super();
        this.nick = nick;

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


    private function popWin(nick:String)
    {
        var winX = openfl.Lib.current.stage.stageWidth / 2 - 100;
        var winY = openfl.Lib.current.stage.stageHeight / 2;

        this.winText = Tool.getTextField(winX, winY, nick + " Won", 50);
        this.winText.width = 800;
        this.addChild(this.winText);

        this.winTimer = new haxe.Timer(3000);
        this.winTimer.run = dePopWin;
    }

    private function dePopWin()
    {
        this.winTimer.stop();
        this.removeChild(this.winText);
    }

    private function popEnergyBar(color:Int)
    {
        this.energyBarLF = new Bar(color);
        this.addChild(this.energyBarLF);

        // if(Game.LAGFREE) {
        //     // this.energyBarLF = new Bar(0x333132, 358, 20);  // Debug
        //     this.energyBarLF = new Bar(color, 358, 40);
        //     this.energyBarLF.x = 260;
        //     this.energyBarLF.y = openfl.Lib.current.stage.stageHeight - this.energyBarLF.height;
        //     this.addChild(this.energyBarLF);
        // }
    }

    private function rankingRefresh(ranking:Array<Int>)
    {
        var count = 0;
        for(_id in ranking)
        {
            var rank:Rank = this.ranks.get(_id);
            rank.moveText(count);
            count += 1;
        }
    }

    private function createDots(SIZE:Int)
    {
        // BOARD DOTS
        var xArray:Array<Array<Dot>> = new Array();
        for(x in 0...SIZE)
        {
            var yArray:Array<Dot> = new Array();
            xArray.push(yArray);
            for(y in 0...SIZE)
            {
                var dot:Dot = new Dot(x, y);
                this.addChild(dot);
                yArray.push(dot);
            }
        }

        // CONTOUR IMAGES
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

        // CONTOUR SHAPES
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

    private function onMouseOver(event:MouseEvent)
    {
        for(posx in 0...this.dots.length)
        {
            for(posy in 0...this.dots[posx].length)
            {
                var dot = this.dots[posx][posy];

                if(event.target == dot)
                {

                    // if(Game.LAGFREE) {
                        if(dot.id != this.id && this.LFenergy > CST.DOT_COST)
                        {
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

    private function onMouseDown(event:MouseEvent)
    {
        for(posx in 0...this.dots.length)
        {
            for(posy in 0...this.dots[posx].length)
            {
                var dot = this.dots[posx][posy];

                if(event.target == dot)  // PLEASE...
                {
                    if(dot.id == this.id)
                    {
                        socket.writeByte(CST.TOWER);
                        socket.writeByte(posx);
                        socket.writeByte(posy);
                    }
                }
            }
        }
    }

    private function onRightMouseDown(event:MouseEvent)
    {
        for(posx in 0...this.dots.length)
        {
            for(posy in 0...this.dots[posx].length)
            {
                var dot = this.dots[posx][posy];

                if(event.target == dot)  // PLEASE...
                {
                    if(dot.id == this.id)
                    {
                        socket.writeByte(CST.PILLAR);
                        socket.writeByte(posx);
                        socket.writeByte(posy);
                    }
                }
            }
        }
    }

    private function onEnterFrame(event:Event):Void
    {
        var elapsedTime:Float = Lib.getTimer() - this.startTime;

        if (elapsedTime > 1000 / 10)
        {
            // if(Game.LAGFREE) {
                if(this.id != 0)
                {
                    this.LFenergy += CST.DOT_REGEN * elapsedTime / 1000;
                    if(this.LFenergy > this.energyMax)
                    {
                        this.LFenergy = this.energyMax;
                    }

                    else if(this.LFenergy < 0)
                    {
                        this.LFenergy = 0;
                    }

                    this.energyBarLF.update(Std.int(this.LFenergy), Std.int(this.energyMax));
                }
            // }

            socket.flush();
            this.startTime = Lib.getTimer();
        }
    }

    private function dataHandler(event:ProgressEvent)
    {
        while(socket.bytesAvailable > 0) {
            var msgType = socket.readUnsignedByte();

            if(msgType == CST.CONNECTION)
            {
                var _id:Int = socket.readUnsignedByte();
                var nick:String = socket.readUTF();
                var color:Int = socket.readInt();
                var me:Int = socket.readUnsignedByte();

                var player = new Player(_id, nick, color);
                this.players.set(_id, player);
                var rank = new Rank(_id, nick, color);
                this.ranks.set(_id, rank);
                this.addChild(rank);

                if(me == 1) {
                    this.id = _id;
                    this.color = color;

                    popEnergyBar(color);

                    // SPAWN CHAT
                    this.chat = new Chat(this.socket, this.color);
                    this.addChild(this.chat);
                }

                trace("connection from " + nick);
                trace("Is it me ?" + me);
            }

            if(msgType == CST.DISCONNECTION)
            {
                var _id = socket.readUnsignedByte();
                for(player in this.players) {
                }
                var rank = this.ranks.get(_id);

                // Remove references
                this.removeChild(rank);
                this.ranks.remove(_id);
                this.players.remove(_id);
            }

            if(msgType == CST.TOWER)
            {
                var flag = socket.readUnsignedByte();
                var tileX = socket.readUnsignedByte();
                var tileY = socket.readUnsignedByte();

                if(flag == 1)
                {
                    this.dots[tileX][tileY].createTower();
                    this.vlam.play();
                }
                else
                {
                    this.dots[tileX][tileY].destroyTower();
                }
            }

            if(msgType == CST.PILLAR)
            {
                var flag = socket.readUnsignedByte();
                var ownerId = socket.readUnsignedByte();
                var player = this.players.get(ownerId);
                var tileX = socket.readUnsignedByte();
                var tileY = socket.readUnsignedByte();

                if(flag == 1)
                {
                    var newPillar = new Pillar(ownerId, tileX, tileY, player.color);
                    pillars.push(newPillar);
                    addChild(newPillar);
                }
                else
                {
                    var i = pillars.length;
                    while (i-- > 0)
                    {
                        if(pillars[i].ownerId == ownerId)
                        {
                            removeChild(pillars[i]);
                            pillars.remove(pillars[i]);
                        }
                    }
                }
            }

            if(msgType == CST.PILLAR_ATTACK)
            {
                var ownerId = socket.readUnsignedByte();
                var player = this.players.get(ownerId);
                var sourceX = socket.readUnsignedByte();
                var sourceY = socket.readUnsignedByte();
                var targetX = socket.readUnsignedByte();
                var targetY = socket.readUnsignedByte();
                Pillar.attack(player.color, sourceX, sourceY, targetX, targetY);
            }

            if(msgType == CST.UPDATE)
            {
                var energy = socket.readUnsignedByte();
                this.energyMax = socket.readUnsignedByte();

                this.energy = energy;
                this.LFenergy = energy;
                this.energyBarLF.update(energy, this.energyMax);

                if(this.energy > 25) energyBarLF.unlockSkill(1);
            }

            if(msgType == CST.MAP)
            {
                var SIZE:Int = socket.readUnsignedByte();
                this.dots = createDots(SIZE);

                for(x in 0...SIZE) {
                    for(y in 0...SIZE)
                    {
                        var _id = socket.readUnsignedByte();

                        if(_id != 0)
                        {
                            var player = this.players.get(_id);
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
            }

            if(msgType == CST.DOT_COLOR)
            {
                var _id = socket.readUnsignedByte();
                var posx = socket.readUnsignedByte();
                var posy = socket.readUnsignedByte();

                // IF PLAYER PLAY
                if(_id != 0)
                {
                    var player = this.players.get(_id);
                    var color:Int = player.color;
                    this.dots[posx][posy].changeColor(_id, color);

                    // IF MYSELF
                    if(_id == this.id)
                    {
                        this.tick.play();
                    }
                }
                // IF BACK TO DEFAULT DOT
                else {
                    this.dots[posx][posy].changeColor(_id, Dot.DEFAULT_COLOR);
                }
            }

            if(msgType == CST.MESSAGE)
            {
                var _id = socket.readUnsignedByte();
                var chatMsg = socket.readUTF().toUpperCase();
                trace("Message from " + _id);

                var nick = this.players.get(_id).nick;
                var color = this.players.get(_id).color;

                this.chat.message(nick, chatMsg, color);
            }

            if(msgType == CST.WIN)
            {
                var _id = socket.readUnsignedByte();
                var nick = this.players.get(_id).nick;
                popWin(nick);
            }

            // CLIENT-SIDE ?
            if(msgType == CST.RANKING)
            {
                var rankNb = socket.readUnsignedByte();
                var ranking = new Array();

                for(i in 0...rankNb)
                {
                    var _id = socket.readUnsignedByte();
                    ranking.push(_id);
                    this.rankingRefresh(ranking);
                }
            }

            if(msgType == CST.FULL)
            {
                trace("SERVER FULL");
            }

        }
    }

    private function onConnect(event:Event)
    {
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
        popLogin();
    }

    private function popLogin() {
        var background = new Bitmap(Assets.getBitmapData("assets/login.png"));
        this.addChild(background);

        this.login = Tool.getTextField(0, 0, "Guest", 10);
        this.login.type = openfl.text.TextFieldType.INPUT;
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

    private function popGame()
    {
        this.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        Lib.current.removeChild(this);
        Lib.current.addChild(new Game(this.login.text));
    }

    private function onMouseClick(event:MouseEvent) {
        // DEBUG
        popGame();
    }

    private function onKeyDown(event:KeyboardEvent) {
        switch(event.keyCode)
        {
            case Keyboard.ENTER:
                popGame();
        }
    }

    public static function main() {
        Lib.current.addChild(new LD23());
    }
}
