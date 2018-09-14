package;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.Assets;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.Keyboard;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.Socket;
import flash.events.ProgressEvent;
import flash.external.ExternalInterface;
import Std;


class TextBlock extends Sprite {
    private var text:openfl.text.TextField;

    public function new(y, msg:String, color:Int, nick:String) {
        super();
        // var font = Assets.getFont("assets/FFFFT___.TTF"); 
        // var format = new TextFormat (font.fontName); 
        // var text:TextField = new TextField();
        // text.defaultTextFormat = format;
        // text.embedFonts = true;
        // text.text = msg;
        // text.textColor = 0x000000;

        nick = nick.substr(0, 3);
        var textMsg = createText(0xDEDEDE, 1, msg);
        textMsg.x = 35;
        this.addChild(textMsg);
        var textMsg2 = createText(0x000000, 0, msg);
        textMsg2.x = 35;
        this.addChild(textMsg2);
        var textNick = createText(0x000000, 1, nick);
        this.addChild(textNick);
        var textNick2 = createText(0xDEDEDE, 0, nick);
        this.addChild(textNick2);

        this.graphics.beginFill(color);
        this.graphics.drawRect(0, 0, 230, 20);
        this.graphics.endFill();
        this.y = openfl.Lib.current.stage.stageHeight - 40;
        // this.width = 500;
    }


    private function createText(color, offset, content) {
        var font = Assets.getFont("assets/FFFFT___.TTF"); 
        var format = new TextFormat (font.fontName); 
        format.size = 10;
        var text:TextField = new TextField();
        text.defaultTextFormat = format;
        text.embedFonts = true;
        text.text = content;
        text.textColor = color;
        text.y = offset;
        text.x = offset;
        text.selectable = false;

        text.height = 20;
        text.width = 230;
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

    public function new(socket) {
        super();
        this.socket = socket;
        this.messages = new Array();

        var font = Assets.getFont("assets/FFFFT___.TTF"); 
        var format = new TextFormat (font.fontName); 
        format.size = 10;

        this.text = new openfl.text.TextField();
        this.text.defaultTextFormat = format;
        this.text.embedFonts = true;
        this.text.x = 0;
        this.text.height = 20;
        this.text.width = 230;
        this.text.y = openfl.Lib.current.stage.stageHeight - this.text.height;
        this.text.border = true;
        this.text.borderColor = 0x000000;
        this.text.wordWrap = true;
        this.text.type = openfl.text.TextFieldType.INPUT;
        this.text.text = "Hello !";
        this.text.maxChars = 28;
        this.addChild(this.text);

        this.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    private function onKeyDown(event:KeyboardEvent) {
        switch(event.keyCode){
            case Keyboard.ENTER:
                if(this.text.text.length > 0){
                    socket.writeByte(Game.MESSAGE);
                    socket.writeUTF(this.text.text);
                    this.text.text = "";
                }
        }
    }

    public function message(nick:String, msg:String, color:Int) {
        var block = new TextBlock(openfl.Lib.current.stage.stageHeight, msg, color, nick);
        this.addChild(block);

        for(textBlock in this.messages) {
            textBlock.moveUp();
            if(textBlock.y < 0) {
                this.removeChild(textBlock);
                this.messages.remove(textBlock);
            }
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

    public function new(id, nick, color) {
        super();
        this.id = id;
        this.nick = nick;
        this.color = color;
        this.y = -100;

        // background
        this.graphics.clear();
        // this.graphics.lineStyle(borderSize, borderColor);
        this.graphics.beginFill(this.color);
        this.graphics.drawRect(openfl.Lib.current.stage.stageWidth - 150,
                                                        0, 150, 20);
        this.graphics.endFill();  

        this.rankText = createText(0xDEDEDE, 0);
        this.addChild(rankText);
        this.rankText2 = createText(0x000000, 1);
        this.addChild(rankText2);

        // this.rankText.y = 400;
        this.addChild(this.rankText);
    }

    private function createText(color, offset) {
        var font = Assets.getFont("assets/FFFFT___.TTF"); 
        var format = new TextFormat (font.fontName); 
        var text:TextField = new TextField();
        text.defaultTextFormat = format;
        text.embedFonts = true;
        text.text = this.nick;
        text.textColor = color;
        text.x = openfl.Lib.current.stage.stageWidth - 120 - offset;
        text.y = offset;
        text.selectable = false;
        return text;
    }

    public function moveText(y) {
        this.y = y;
    }
}


class Dot extends Sprite {
    public static var DEFAULT_COLOR = 0x737373;
    public static var DEFAULT_BORDER_COLOR = 0xE8E8E8;
    public static var DEFAULT_BORDER_SIZE = 1;
    public var id:Int;
    private var color:Int;
    private var towerTimer:haxe.Timer;
    private var dotTimer:haxe.Timer;


    public function new(x, y) {
        super();
        this.createDot(DEFAULT_COLOR, DEFAULT_BORDER_COLOR, DEFAULT_BORDER_SIZE);
        this.x = 260 + x * 12;
        this.y = 100 + y * 12;
        this.id = 0;
        this.color = DEFAULT_COLOR;
        this.dotTimer = new haxe.Timer(1);
    }

    private function createDot(color:Int, borderColor:Int, borderSize:Int) {
        this.graphics.clear();
        this.graphics.lineStyle(borderSize, borderColor);
        this.graphics.beginFill(color);
        this.graphics.drawRect(0, 0, 8, 8);
        this.graphics.endFill();  
    }

    public function createTower() {
        createDot(this.color, 0x1C1C1C, 4);
    }

    public function destroyTower() {
        createDot(this.color, DEFAULT_BORDER_COLOR, DEFAULT_BORDER_SIZE);
    }
    public function focusDot(color:Int) {
        createDot(color, DEFAULT_BORDER_COLOR, DEFAULT_BORDER_SIZE);
        if(Game.LAGFREE) {
            this.alpha = 0.5;
            this.dotTimer = new haxe.Timer(2000);
            this.dotTimer.run = this.resetDot;
        }
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
    private var daWidth:Int;

    public function new(color:Int, width:Int, Height:Int) {
        super();
        var bsize:Int = 2;
        this.daWidth = width;

        // Border
        this.graphics.lineStyle(bsize, 0xE8E8E8);
        this.graphics.beginFill(0xD1D1D1);
        this.graphics.drawRect(0, 0, width, Height);
        this.graphics.endFill();

        // Content
        this.content = new Sprite();
        this.content.graphics.beginFill(color);
        this.content.graphics.drawRect(0, 0,
                    width - bsize, Height - bsize);
        this.content.graphics.endFill();
        this.content.x = bsize / 2;
        this.content.y = bsize / 2;
        this.addChild(this.content);

        // Line
        this.line = new Sprite();
        this.line.graphics.beginFill(0xCC2525);
        this.line.graphics.drawRect(0, bsize,
                        3, Height - bsize);
        this.line.graphics.endFill();
        this.addChild(this.line);

        // Tower lines
        for(i in 1...4) {
            var tline = new Sprite();
            tline.graphics.beginFill(0x3D3D3D);
            tline.graphics.drawRect(i * 25 * this.daWidth / 100, bsize,
                            3, Height - bsize);
            tline.graphics.endFill();
            this.addChild(tline);
        }
    }

    public function update(energy:Int, energyMax:Int) {
        this.content.scaleX = energy / 100;
        this.line.x = this.daWidth / 100 * energyMax;
    }
}


class Link extends Sprite {
    public function new() {
        super();
        this.graphics.beginFill(0x575757);
        this.graphics.drawRect(0, 0, 150, 40);
        this.graphics.endFill();

        var text1 = createText(0xB8B8B8, 1);
        this.addChild(text1);
        var text2 = createText(0x292929, 0);
        this.addChild(text2);
        this.buttonMode = true;
        this.useHandCursor = true;
        this.mouseChildren = false;
    }

    private function createText(color, offset) {
        var font = Assets.getFont("assets/FFFFT___.TTF"); 
        var format = new TextFormat(font.fontName); 
        format.size = 14;
        var text:TextField = new TextField();
        text.defaultTextFormat = format;
        text.embedFonts = true;
        text.text = "LD entry";
        text.height = 40;
        text.textColor = color;
        text.x = 30 + offset;
        text.y = 5 + offset;
        text.selectable = false;
        return text;
    }
}


class Game extends Sprite {
    public static var MESSAGE = 0;
    public static var CONNECTION = 1;
    public static var DOT_COLOR = 2;
    public static var RANKING = 3;
    public static var MAP = 4;
    public static var DISCONNECTION = 5;
    public static var UPDATE = 6;
    public static var TOWER = 7;
    public static var FULL = 8;
    public static var WIN = 9;
    private static var SIZE = 30;
    private static var DOT_COST = 10;
    public static var LAGFREE = true;

    private var socket:Socket;
    private var nick:String;
    private var startTime:Int;
    private var id:Int;
    private var myPlayer:Player;
    private var players:Map<String, Player>;
    private var dots:Array<Array<Dot>>;
    private var square:Sprite;
    private var theDot:Dot;
    private var winTimer:haxe.Timer;
    private var energyBar:Bar;
    private var energyBarLF:Bar;
    private var energy:Int;
    private var energyMax:Int;
    private var LFenergy:Float;
    private var chat:Chat;
    private var winText:TextField;
    private var tick:openfl.media.Sound;
    private var vlam:openfl.media.Sound;
    private var linkLD:Link;
    private var color:Int;

    public function new(nick:String) {
        super();
        this.nick = nick;
        this.id = 0;
        this.players = new Map();
        this.dots = createDots();
        this.energy = 0;
        this.LFenergy = 0;
        this.tick = Assets.getSound("assets/sound/Hit_Hurt5.wav");
        this.vlam = Assets.getSound("assets/sound/Explosion7.wav");
        this.linkLD = new Link();
        this.linkLD.x = 370;
        this.addChild(this.linkLD);
        // Fps
        // var fps = new nme.display.FPS();
        // fps.x = 50;
        // this.addChild(fps);

        // Socket
        this.socket = new Socket();
        // this.socket.connect("caribou.servebeer.com", 9999);
        // this.socket.connect("carib0u.dyndns.org", 9999);
        this.socket.connect("127.0.0.1", 9999);
        this.socket.addEventListener(Event.CONNECT, onConnect);
        this.socket.addEventListener(ProgressEvent.SOCKET_DATA, dataHandler); 
        this.socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError);
        this.socket.addEventListener(Event.CLOSE, onClose);
        this.socket.addEventListener(IOErrorEvent.IO_ERROR, onError);

        // Chat
        this.chat = new Chat(this.socket);
        this.addChild(this.chat);

        // Events listeners
        this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }


    private function popWin(nick:String) {
        var font = Assets.getFont("assets/FFFFT___.TTF"); 
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

    private function popEnergyBar(color:Int) {
        this.energyBar = new Bar(color, 358, 40);
        this.energyBar.x = 260;
        this.energyBar.y = openfl.Lib.current.stage.stageHeight - this.energyBar.height;
        this.addChild(this.energyBar);

        if(Game.LAGFREE) {
            // this.energyBarLF = new Bar(0x333132, 358, 20);  // Debug
            this.energyBarLF = new Bar(color, 358, 40);
            this.energyBarLF.x = 260;
            this.energyBarLF.y = openfl.Lib.current.stage.stageHeight - this.energyBarLF.height;
            this.addChild(this.energyBarLF);
        }
    }

    private function rankingRefresh(ranking:Array<Int>) {
        var count = 0;
        for(_id in ranking) {
            var player:Player = this.players.get(Std.string(_id));
            player.moveText(count * 20);
            count += 1;
        }
    }

    private function createDots() {
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
        return xArray;
    }

    private function onMouseOver(event:MouseEvent) {
        for(posx in 0...this.dots.length) {
            for(posy in 0...this.dots[posx].length) {
                var dot = this.dots[posx][posy];
                if(event.target == dot){

                    if(Game.LAGFREE) {
                        if(dot.id != this.id && this.LFenergy > DOT_COST) {
                            this.LFenergy -= 10;
                            dot.focusDot(this.color);
                            socket.writeByte(DOT_COLOR);
                            socket.writeByte(posx);
                            socket.writeByte(posy);
                        }
                    }
                    else {
                        if(dot.id != this.id && this.energy > DOT_COST) {
                            socket.writeByte(DOT_COLOR);
                            socket.writeByte(posx);
                            socket.writeByte(posy);
                        }
                    }
                }
            }
        }
    }

    private function onMouseDown(event:MouseEvent) {
        if(event.target == this.linkLD) {
            openfl.Lib.getURL(new flash.net.URLRequest("http://www.ludumdare.com/compo/ludum-dare-23/?action=preview&uid=4227"),"_blank");
        }

        for(posx in 0...this.dots.length) {
            for(posy in 0...this.dots[posx].length) {
                var dot = this.dots[posx][posy];
                if(event.target == dot){
                    if(dot.id == this.id) {
                        socket.writeByte(TOWER);
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
            if(Game.LAGFREE) {
                if(this.id != 0) {
                    this.LFenergy += 30 * elapsedTime / 1000;
                    if(this.LFenergy > this.energyMax) {
                        this.LFenergy = this.energyMax;
                    }

                    else if(this.LFenergy < 0) {
                        this.LFenergy = 0;
                    }
                    this.energyBarLF.update(Std.int(this.LFenergy), Std.int(this.energyMax));
                }
            }

            socket.flush();
            this.startTime = Lib.getTimer();
        }
    }

    private function dataHandler(event:ProgressEvent) {
        while(socket.bytesAvailable > 0) {
            var msgType = socket.readByte();

            if(msgType == CONNECTION) {
                var _id = socket.readByte();
                var nick = socket.readUTF();
                var color = socket.readInt();
                var me = socket.readByte();

                var player = new Player(_id, nick, color);
                this.addChild(player);

                if(me == 1) {
                    this.id = _id;
                    this.myPlayer = player;
                    this.color = color;
                    popEnergyBar(color);
                }
                this.players.set(Std.string(_id), player);
            }

            if(msgType == DISCONNECTION) {
                var _id = socket.readByte();
                for(player in this.players) {
                }
                var player = this.players.get(Std.string(_id));

                // Remove references
                this.removeChild(player);
                this.players.remove(Std.string(_id));
            }

            if(msgType == TOWER) {
                var flag = socket.readByte();
                var posx = socket.readByte();
                var posy = socket.readByte();
                if(flag == 1) {
                    this.dots[posx][posy].createTower();
                    this.vlam.play();
                }
                else {
                    this.dots[posx][posy].destroyTower();
                }

            }

            if(msgType == UPDATE) {
                var energy = socket.readByte();
                this.energyMax = socket.readByte();
                this.energy = energy;
                this.energyBar.update(energy, this.energyMax);
            }

            if(msgType == MAP) {
                for(x in 0...SIZE) {
                    for(y in 0...SIZE) {
                        var _id = socket.readByte();
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
            }

            if(msgType == DOT_COLOR) {
                var _id = socket.readByte();
                var posx = socket.readByte();
                var posy = socket.readByte();
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

                // var player = this.players.get(Std.string(_id));
                // this.dots[posx][posy].changeColor(player.color);
                // trace("dot" + Std.string(posx) + " " + Std.string(posy));
            }

            if(msgType == MESSAGE) {
                var _id = socket.readByte();
                var chatMsg = socket.readUTF();

                var nick = this.players.get(Std.string(_id)).nick;
                var color = this.players.get(Std.string(_id)).color;

                this.chat.message(nick, chatMsg, color);
            }

            if(msgType == WIN) {
                var _id = socket.readByte();
                var nick = this.players.get(Std.string(_id)).nick;
                popWin(nick);
            }

            if(msgType == RANKING) {
                var rankNb = socket.readByte();
                var ranking = new Array();
                for(i in 0...rankNb) {
                    var _id = socket.readByte();
                    ranking.push(_id);
                    this.rankingRefresh(ranking);
                }
            }

            if(msgType == FULL) {
                trace("SERVER FULL");
            }

        }
    }

    private function onConnect(event:Event) {
        socket.writeByte(CONNECTION);
        socket.writeUTF(this.nick);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
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
    private var button:Link;

    public function new() {
        super();
        this.intro = new Bitmap(Assets.getBitmapData("assets/intro.png"));
        this.addChild(this.intro);
        this.addEventListener(MouseEvent.CLICK, onMouseClick);
    }

    private function popLogin() {
        var bg = new Bitmap(Assets.getBitmapData("assets/login.png"));
        this.addChild(bg);
        var font = Assets.getFont("assets/FFFFT___.TTF"); 
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

        // this.button = new Link();
        // this.button.x = 370;
        // this.button.y = 100;
        // this.addChild(this.button);

        this.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    private function onMouseClick(event:MouseEvent) {
        // trace(event.target);
        // if(event.target == this.button) {
        //     this.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        //     Lib.current.removeChild(this);
        //     Lib.current.addChild(new Game(this.login.text));
        //     this.removeEventListener(MouseEvent.CLICK, onMouseClick);
        // }
        // else {
        this.removeChild(this.intro);
        this.removeEventListener(MouseEvent.CLICK, onMouseClick);
        popLogin();
        // }
    }

    private function onKeyDown(event:KeyboardEvent) {
        switch(event.keyCode){
            case Keyboard.ENTER:
                this.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
                Lib.current.removeChild(this);
                Lib.current.addChild(new Game(this.login.text));
        }
    }

    public static function main() {
        Lib.current.addChild(new LD23());
    }
}
