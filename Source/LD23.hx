
package;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.display.StageAlign;
import openfl.Assets;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.text.TextFieldAutoSize;
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
import motion.easing.Cubic;

import Common.CST;


class TextBlock extends Sprite
{
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


class Chat extends Sprite
{
    private var msg:openfl.text.TextField = new openfl.text.TextField();
    private var socket:Socket;
    private var messages:Array<TextBlock>;

    public static var HEIGHT:Int = 48;
    public static var DY:Int = 50;
    public static var MARGIN_LEFT:Int = 10;

    public function new(socket, color:Int)
    {
        super();
        this.socket = socket;  // Has nothing to do here
        this.messages = new Array();
        this.x = MARGIN_LEFT;
        this.y -= 10;
        var msgY = openfl.Lib.current.stage.stageHeight - DY;

        // INPUT BOX COLOR
        var borderSize = 2;
        var inputBox = new Shape();
        inputBox.graphics.clear();
        inputBox.graphics.lineStyle(borderSize, color);
        inputBox.graphics.beginFill(color, 0);
        inputBox.graphics.drawRect(borderSize / 2, msgY + borderSize / 2,
                                    Game.COLUMN_WIDTH - borderSize, HEIGHT - borderSize);
        inputBox.graphics.endFill();
        inputBox.transform.colorTransform = new openfl.geom.ColorTransform(0.6, 0.6, 0.6);

        // TEXT
        this.msg = Tool.getTextField(10, msgY + 5, "HELLO !", 26);
        this.msg.type = openfl.text.TextFieldType.INPUT;
        this.msg.wordWrap = true;
        this.msg.maxChars = 15;
        this.msg.height = HEIGHT;
        this.msg.width = Game.COLUMN_WIDTH;
        this.msg.textColor = color;
        this.msg.transform.colorTransform = new openfl.geom.ColorTransform(0.6, 0.6, 0.6);


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
        this.x = Chat.MARGIN_LEFT;
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

    public function updateProgression(numDots:Int)
    {
        var pc = (numDots / CST.WIN_DOTS) * 100;

        this.rankText.text = this.nick + " : " + Std.int(pc) + "%";
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
        trace("Attack");
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
    static inline public function ToPixelX2(tileX:Int)
        return tileX * Dot.SIZE;

    static inline public function ToPixelY2(tileY:Int)
        return tileY * Dot.SIZE;

    static inline public function ToPixelX(tileX:Int)
        return Game.BOARD_MARGIN_X + tileX * Dot.SIZE;

    static inline public function ToPixelY(tileY:Int)
        return Game.BOARD_MARGIN_Y + tileY * Dot.SIZE;

    static inline public function ToTileX(x:Float):Int
        return Std.int((x - Game.BOARD_MARGIN_X) / Dot.SIZE);

    static inline public function ToTileY(y:Float):Int
        return Std.int((y - Game.BOARD_MARGIN_Y) / Dot.SIZE);

    static inline public function getTextField(x:Float, y:Float,
                                               text:String, size:Int,
                                               align = TextFormatAlign.LEFT)
    {
        var font = Assets.getFont(Game.FONT);
        var format = new TextFormat(font.fontName); 
        format.size = size;
        format.align = align;

        var textField = new TextField();
        textField.defaultTextFormat = format;
        textField.embedFonts = true;
        textField.text = text;
        textField.x = x;
        textField.y = y;

        return textField;
    }
}


class Color
{
    public static inline function toRGB(color:Int)
    {
        var r = ((color >> 16) & 255) / 255;
        var g = ((color >> 8) & 255) / 255;
        var b = (color & 255) / 255;
        
        return [r, g, b];
    }

    public static inline function shade(color:Int, factor:Float)
    {
        var rgb:Array<Float> = toRGB(color);

        var newR = rgb[0] * (1 - factor);
        var newG = rgb[1] * (1 - factor);
        var newB = rgb[2] * (1 - factor);

        return toInt(newR, newG, newB);
    }
    
    public static inline function toInt(r:Float, g:Float, b:Float)
    {
        return (Math.round(r * 255) << 16) | (Math.round(g * 255) << 8) | Math.round(b * 255);
    }
}


class Dot extends Sprite
{
    public static inline var DEFAULT_COLOR = 0x542437;
    public static inline var SIZE = 16;
    public var id:Int = -1;
    private var color:Int;

    public function new(tileX, tileY) {
        super();
        this.createDot(DEFAULT_COLOR);
        this.x = Tool.ToPixelX2(tileX);
        this.y = Tool.ToPixelY2(tileY);
    }

    function animate(y:Int)
    {
        this.graphics.clear();
        this.graphics.beginFill(color);
        this.graphics.drawRect(0, y, SIZE, SIZE);
        this.graphics.endFill();
        this.graphics.beginFill(Color.shade(color, 0.5));
        this.graphics.drawRect(0, y + SIZE, SIZE, y*-1);
        this.graphics.endFill();
    }

    private function createDot(color:Int)
    {
        Actuate.update(animate, 2, [-10], [0]);

        // CLIENT-SIDE PREDICTION
        Actuate.stop(this.transform.colorTransform, null, false, false);
        this.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 50, 50 ,50);
        Actuate.tween(this.transform.colorTransform, 2, {redOffset:0, greenOffset:0, blueOffset:0});
    }

    public function createTower()
    {
        this.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 32, 32 ,32);
    }

    public function destroyTower()
    {
        this.transform.colorTransform = new openfl.geom.ColorTransform(1, 1, 1, 1, 0, 0 ,0);
    }

    public function changeColor(_id:Int, newColor:Int)
    {
        if(Game.LAGFREE) {
            this.alpha = 1;
            Actuate.stop(this);
        }
        createDot(newColor);
        this.id = _id;
        this.alpha = 1;
        this.color = newColor;
    }
}


class Bar extends Sprite
{
    var content:Sprite;
    var line:Sprite;
    var realWidth:Int;
    public var skills:Array<SkillIcon> = new Array();

    public function new(color:Int)
    {
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
        // this.content.x = pad / 2;
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

        // POSITION SKILLS
        function makeSkillIcon(skillNum:Int, bmpPath:String):Sprite
        {
            var sprite = new Sprite();
            sprite.x = skillNum * xTower;
            sprite.y = yTower + 55;

            var bmp = new Bitmap(Assets.getBitmapData(bmpPath));
            bmp.x -= bmp.width / 2;
            bmp.y -= bmp.height / 2;

            sprite.addChild(bmp);
            this.addChild(sprite);

            return sprite;
        }

        this.skills = [new SkillIcon(1, "cross", xTower, yTower),
                       new SkillIcon(2, "tower", xTower, yTower)];

        for(skill in skills) addChild(skill);
    }

    public function update(energy:Int, energyMax:Int)
    {
        this.content.scaleX = energy / 100;
        this.line.x = this.realWidth / 100 * energyMax;

        for(skill in skills) skill.update(energy, energyMax);
    }
}


class SkillIcon extends Sprite
{
    public var description:String;
    var skillName:String;
    var num:Int;
    var unlocked = false;
    var available = false;

    public function new(num:Int, skillName:String, x:Float, y:Float)
    {
        super();

        this.skillName = skillName;
        this.num = num;
        this.x = num * x;
        this.y = y + 55;

        this.addChild(getBitmap(skillName));

        // MOVE THIS TO DATA CLASS
        if(num == 1)
            this.description = "Skill that allow you to fire a dot line in 4 directions. 3x3 square needed";
        if(num == 2)
            this.description = "Skill that create a tower and will fire dot every X seconds";
    }

    function getBitmap(imageName:String)
    {
        var bmpPath = "assets/" + imageName + ".png";
        var bmp = new Bitmap(Assets.getBitmapData(bmpPath));
        bmp.x -= bmp.width / 2;
        bmp.y -= bmp.height / 2;

        return bmp;
    }

    public function update(energy:Float, energyMax:Float)
    {
        if(energyMax > 25 * num)
        {
            if(!unlocked)
            {
                this.addChild(getBitmap(skillName + "_unlocked"));
                unlocked = true;
            }
        }
        
        if(energy > 25 * num)
        {
            if(!available)
            {
                Actuate.stop(this);
                Actuate.tween(this, 0.5, {scaleX: 1.2, scaleY: 1.2}).repeat().reflect().ease(Cubic.easeInOut);
                available = true;
            }
        }

        if(energy < 25)
        {
            if(available)
            {
                Actuate.stop(this);
                Actuate.tween(this, 0.5, {scaleX: 1, scaleY: 1}).ease(Cubic.easeInOut);
                available = false;
            }
        }   
    }
}


class Player
{
    public var id:Int;
    public var nick:String;
    public var color:Int;
    public var dots:Int = 0;

    public function new(id:Int, nick:String, color:Int)
    {
        this.id = id;
        this.nick = nick;
        this.color = color;
    }
}



class Cursor extends Sprite
{
    var bitmaps = [new Bitmap(Assets.getBitmapData("assets/cursor_default.png")),
                   new Bitmap(Assets.getBitmapData("assets/cursor_cross.png")),
                   new Bitmap(Assets.getBitmapData("assets/cursor_pillar.png"))];

    var contour = new Shape();

    public function new()
    {
        super();

        this.mouseEnabled = false;
        this.addChild(contour);

        // BITMAPS POINTERS
        for(bitmap in bitmaps)
        {
            bitmap.alpha = 0;
            this.addChild(bitmap);
        }
    }

    function makeContour(color:Int)
    {
        Actuate.stop(contour);
        contour.visible = true;
        contour.alpha = 1;

        // CONTOUR GRAPHICS
        var contourSize = 3 * Dot.SIZE;
        contour.graphics.lineStyle(2, color);
        contour.graphics.beginFill(0xffffff, 0);
        contour.graphics.drawRect(-Dot.SIZE, -Dot.SIZE, contourSize, contourSize);
        contour.graphics.endFill();

        Actuate.tween(contour, 1, {alpha: 0});
    }

    public function cantBuild()
    {
        trace("cantBuild");
        makeContour(0xf44242);
    }

    public function canBuild()
    {
        trace("canBuild");
        makeContour(0xffffff);
    }

    public function switchTo(num:Int)
    {
        for(bitmap in bitmaps)
        {
            if(bitmap == bitmaps[num])
                bitmap.alpha = 1;
            else
                bitmap.alpha = 0;
        }
    }

    public function setPosition(tileX:Int, tileY:Int)
    {
        this.x = Tool.ToPixelX(tileX);
        this.y = Tool.ToPixelY(tileY);
    }
}



class Board extends Sprite
{
    public var dots:Array<Array<Dot>>;

    public function new()
    {
        super();
        this.x = Game.BOARD_MARGIN_X;
        this.y = Game.BOARD_MARGIN_Y;

        this.dots = createDots();
    }

    private function createDots()
    {
        // BOARD DOTS
        var xArray:Array<Array<Dot>> = new Array();
        for(x in 0...CST.SIZE)
        {
            var yArray:Array<Dot> = new Array();
            xArray.push(yArray);
            for(y in 0...CST.SIZE)
            {
                var dot:Dot = new Dot(x, y);
                this.addChild(dot);
                yArray.push(dot);
            }
        }

        // CONTOUR IMAGES
        var cornerTopLeft = new TileBMP(-1, -1, "corner.png");
        this.addChild(cornerTopLeft);

        var cornerTopRight = new TileBMP(CST.SIZE, -1, "corner.png");
        cornerTopRight.flipX();
        this.addChild(cornerTopRight);

        var cornerBottomLeft = new TileBMP(-1, CST.SIZE, "corner.png");
        cornerBottomLeft.flipY();
        this.addChild(cornerBottomLeft);

        var cornerBottomRight = new TileBMP(CST.SIZE, CST.SIZE, "corner.png");
        cornerBottomRight.flipX();
        cornerBottomRight.flipY();
        this.addChild(cornerBottomRight);

        // CONTOUR SHAPES
        for(x in 0...CST.SIZE) {
            this.addChild(new Tile(x, -1, 0xd95b43));
            this.addChild(new Tile(x, CST.SIZE, 0xd95b43));
        }

        for(y in 0...CST.SIZE) {
            this.addChild(new Tile(-1, y, 0xd95b43));
            this.addChild(new Tile(CST.SIZE, y, 0xd95b43));
        }

        return xArray;
    } 
}




class ToolTip extends TextField
{
    public function new()
    {
        super();

        var font = Assets.getFont(Game.FONT);
        var format = new TextFormat (font.fontName); 
        format.size = 20;

        this.defaultTextFormat = format;
        this.embedFonts = true;
        this.text = "";
        this.background = true;
        this.backgroundColor = 0xfff8a4a4;
        this.autoSize = TextFieldAutoSize.LEFT;
        this.multiline = true;
        this.border = true;
        this.wordWrap = true;
        this.width = 250;

        hide();
    }

    public function show(x:Float, y:Float, description:String)
    {
        this.x = x;
        this.y = y - 100;
        this.text = description;
        this.alpha = 1;
    }

    public function hide()
    {
        this.alpha = 0;
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
    private var cursor:Cursor = new Cursor();
    private var toolTip:ToolTip = new ToolTip();
    
    // SOUND
    // private var vlam:openfl.media.Sound = Assets.getSound("assets/sound/237422__plasterbrain__hover-1.ogg");
    // private var tick:openfl.media.Sound = Assets.getSound("assets/sound/237422__plasterbrain__hover-1.ogg");
    private var vlam:openfl.media.Sound = Assets.getSound("assets/sound/footstep09.ogg");
    private var tick:openfl.media.Sound = Assets.getSound("assets/sound/click1.wav");

    // WORLD
    private var players:Map<Int, Player> = new Map();
    private var pillars:Array<Pillar> = new Array();
    private var board:Board;
    
    // MISC
    private var socket:Socket;
    private var startTime:Int;
    private var winTimer:haxe.Timer;
    private var winText:TextField;

    // 3x3 CHECKLIST
    private var checklist:Array<Array<Int>> = [
                                                [-1, 0],
                                                [-1, 1],
                                                [0,  1],
                                                [1,  1],
                                                [1,  0],
                                                [1, -1],
                                                [0, -1],
                                                [-1,-1]
                                               ];

    public function new(nick:String)
    {
        super();

        this.nick = nick;

        // FPS
        // var fps = new nme.display.FPS();
        // fps.x = 50;
        // this.addChild(fps);
        // trace(haxe.Resource.getString("ip"));
        // trace(Assets.getText("assets/ip.txt"));

        // SOCKET
        this.socket = new Socket();
        this.socket.endian = BIG_ENDIAN;

        #if deploy
        trace("Deploy build");
        this.socket.connect("caribou.servegame.com", 9999);
        #else
        this.socket.connect("127.0.0.1", 9999);
        // this.socket.connect("192.168.1.42", 9999);
        #end

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
        trace("POP WIN");
        var winX = 50;
        var winY = openfl.Lib.current.stage.stageHeight / 2;

        this.winText = Tool.getTextField(winX, winY, nick + " Won", 50);
        this.winText.textColor = 0xfff8a4a4;
        // this.winText.width = 800;
        this.addChild(this.winText);

        Actuate.timer(3).onComplete(function() { dePopWin(); });

        // this.winTimer = new haxe.Timer(3000);
        // this.winTimer.run = dePopWin;
    }

    private function dePopWin()
    {
        // this.winTimer.stop();
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

    private function onMouseOver(event:MouseEvent)
    {
        for(skillIcon in energyBarLF.skills)
        {
            if(event.target == skillIcon)
            {
                var worldPoint = skillIcon.localToGlobal(new openfl.geom.Point(0, 0));
                this.toolTip.show(worldPoint.x, worldPoint.y, skillIcon.description);
            }
        }

        var tileX = Tool.ToTileX(event.stageX);
        var tileY = Tool.ToTileY(event.stageY);

        // BOARD ZONE
        // if(tileX >= 0 && tileX < CST.SIZE && tileY >= 0 && tileY < CST.SIZE)
        if(Std.is(event.target, Dot))
        {
            cursor.setPosition(tileX, tileY);
            var dot = this.board.dots[tileX][tileY];

            if(dot.id != this.id && this.LFenergy > CST.DOT_COST)
            {
                // this.LFenergy -= CST.DOT_COST;
                this.tick.play();
                socket.writeByte(CST.DOT_COLOR);
                socket.writeByte(tileX);
                socket.writeByte(tileY);
            }
        }
    }

    private function onMouseOut(event:MouseEvent) // MOVE TO ITS CLASS
    {
        for(skillIcon in energyBarLF.skills)
        {
            if(event.target == skillIcon)
            {
                this.toolTip.hide();
            }
        }
    }

    private function onMouseDown(event:MouseEvent)
    {
        var tileX = Tool.ToTileX(event.stageX);
        var tileY = Tool.ToTileY(event.stageY);

        // BOARD ZONE
        if(tileX >= 0 && tileX < CST.SIZE && tileY >= 0 && tileY < CST.SIZE)
        {
            var dot = this.board.dots[tileX][tileY];
            if(dot.id == this.id)
            {
                socket.writeByte(CST.TOWER);
                socket.writeByte(tileX);
                socket.writeByte(tileY);

                if(this.LFenergy < 25)
                    cursor.cantBuild();
                else
                    cursor.canBuild();
            }
        }
    }

    private function onRightMouseDown(event:MouseEvent)
    {
        var tileX = Tool.ToTileX(event.stageX);
        var tileY = Tool.ToTileY(event.stageY);

        // BOARD ZONE
        if(tileX >= 0 && tileX < CST.SIZE && tileY >= 0 && tileY < CST.SIZE)
        {
            var dot = this.board.dots[tileX][tileY];
            if(dot.id == this.id)
            {
                socket.writeByte(CST.PILLAR);
                socket.writeByte(tileX);
                socket.writeByte(tileY);
            }
        }
    }

    function valid3x3spot(tileX:Int, tileY:Int):Bool
    {
        // var buildable = true;

        for(delta in this.checklist)
        {
            var tileDx = tileX + delta[0];
            var tileDy = tileY + delta[1];

            if(this.board.dots[tileDx][tileDy].id != this.id)
                return false;
        }

        return true;
    }

    private function onEnterFrame(event:Event):Void
    {
        var elapsedTime:Float = Lib.getTimer() - this.startTime;

        if (elapsedTime > 1000 / 10)
        {
            // if(Game.LAGFREE) {
                if(this.id != 0)
                {
                    // CURSOR
                    if(energy > 25)
                        cursor.switchTo(1);
                    if(energy > 50)
                        cursor.switchTo(2);

                    // ENERGY REGEN
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

    inline function paintDot(ownerId:Int, tileX:Int, tileY:Int)
    {
        var oldDot = this.board.dots[tileX][tileY];

        // REMOVE DOT COUNT FROM OLD PLAYER
        if(oldDot.id != -1) players.get(oldDot.id).dots -= 1;

        // ADD DOT COUNT TO NEW PLAYER
        if(ownerId != -1) players.get(ownerId).dots += 1;

        // SWITCH COLOR
        var color = Dot.DEFAULT_COLOR;
        if(ownerId != -1) color = players.get(ownerId).color;
        oldDot.changeColor(ownerId, color);

        // UPDATE RANKS PROGRESSION
        if(ownerId != -1)
            this.ranks.get(ownerId).updateProgression(players.get(ownerId).dots);
    }


    private function dataHandler(event:ProgressEvent)
    {
        while(socket.bytesAvailable > 0)
        {
            var msgType = socket.readUnsignedByte();

            if(msgType == CST.CONNECTION)
            {
                trace("CONNECTION");
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
                trace(_id + " disconnected");
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
                    this.board.dots[tileX][tileY].createTower();
                    this.vlam.play();
                }
                else
                {
                    this.board.dots[tileX][tileY].destroyTower();
                }
            }

            if(msgType == CST.PILLAR)
            {
                trace("Pillar");

                var flag = socket.readUnsignedByte();
                var ownerId = socket.readUnsignedByte();
                var tileX = socket.readUnsignedByte();
                var tileY = socket.readUnsignedByte();

                var player = this.players.get(ownerId);

                if(flag == 1)
                {
                    trace("CREATE PILLAR");
                    var newPillar = new Pillar(ownerId, tileX, tileY, player.color);
                    pillars.push(newPillar);
                    addChild(newPillar);
                }
                else
                {
                    var i = pillars.length;
                    trace(pillars);
                    while (i-- > 0) // ???
                    {
                        trace(i);
                        if(pillars[i].ownerId == ownerId)
                        {
                            trace("DESTROYED PILLAR");
                            removeChild(pillars[i]);
                            pillars.remove(pillars[i]);
                        }
                    }
                }
                trace("bloup");
            }

            if(msgType == CST.PILLAR_ATTACK)
            {
                trace("PILLAR_ATTACK");
                var ownerId = socket.readUnsignedByte();
                var player = this.players.get(ownerId);
                var sourceX = socket.readUnsignedByte();
                var sourceY = socket.readUnsignedByte();
                var targetX = socket.readUnsignedByte();
                var targetY = socket.readUnsignedByte();
                Pillar.attack(player.color, sourceX, sourceY, targetX, targetY); // color of undefined
            }

            if(msgType == CST.UPDATE)
            {
                var energy = socket.readUnsignedByte();
                this.energyMax = socket.readUnsignedByte();

                this.energy = energy;
                this.LFenergy = energy;
                this.energyBarLF.update(energy, this.energyMax);
            }

            if(msgType == CST.MAP)
            {
                var SIZE:Int = socket.readUnsignedByte();
                this.board = new Board();
                addChild(this.board);

                for(tileX in 0...SIZE) {
                    for(tileY in 0...SIZE)
                    {
                        var _id = socket.readUnsignedByte();

                        if(_id != 0)
                        {
                            var player = this.players.get(_id);
                            var color = player.color;
                            // this.board.dots[x][y].changeColor(_id, color);
                            this.paintDot(_id, tileX, tileY);
                        }
                        else {
                            // this.board.dots[x][y].changeColor(_id, Dot.DEFAULT_COLOR);
                            this.paintDot(-1, tileX, tileY);
                        }
                    }
                }

                // SPAWN TOOLTIP
                addChildAt(this.toolTip, numChildren);

                // SPAWN MOUSE CURSOR
                this.cursor.switchTo(0);
                addChild(this.cursor);

                // ATTACH EVENTS
                stage.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
                stage.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
                stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
            }

            if(msgType == CST.DOT_COLOR)
            {
                var _id = socket.readUnsignedByte();
                var tileX = socket.readUnsignedByte();
                var tileY = socket.readUnsignedByte();

                // IF PLAYER PLAY
                if(_id != 0)
                {
                    // var player = this.players.get(_id);
                    this.paintDot(_id, tileX, tileY);
                    // var color:Int = player.color;
                    // this.board.dots[posx][posy].changeColor(_id, color);
                    // this.ranks.get(_id).updateProgression(50);

                    // IF MYSELF
                    if(_id == this.id)
                    {
                        // this.tick.play();
                    }
                }
                // IF BACK TO DEFAULT DOT
                else {
                    // this.board.dots[posx][posy].changeColor(_id, Dot.DEFAULT_COLOR);
                    this.paintDot(-1, tileX, tileY);
                }
            }

            if(msgType == CST.MESSAGE)
            {
                trace("MESSAGE");
                var _id = socket.readUnsignedByte();
                var chatMsg = socket.readUTF().toUpperCase();
                trace("Message from " + _id);

                var nick = this.players.get(_id).nick;
                var color = this.players.get(_id).color;

                this.chat.message(nick, chatMsg, color);
            }

            if(msgType == CST.WIN)
            {
                trace("PLAYER WON");
                var _id = socket.readUnsignedByte();
                var nick = this.players.get(_id).nick;
                popWin(nick);

                for(player in players) player.dots = 0;
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
        trace("onConnect");
        socket.writeByte(CST.CONNECTION);
        socket.writeUTF(this.nick);
    }

    private function onClose(event:Event) {
        trace("onClose");
    }

    private function onError(event:Event) {
        trace("socket error");
    }

    private function onSecError(event:Event) {
        trace("socket security error");
    }
}


class LD23 extends Sprite
{
    private var login:TextField;
    private var intro:Bitmap;

    public function new()
    {
        super();
        popLogin();
    }

    private function popLogin()
    {
        // BACKGROUND
        graphics.beginFill(0x3d314a);
        graphics.drawRect(0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
        graphics.endFill();

        // INPUT BOX GRAPHICS
        var inputBmp = new Bitmap(Assets.getBitmapData("assets/inputbox.png"));
        inputBmp.x = Lib.current.stage.stageWidth / 2 - inputBmp.width / 2;
        inputBmp.y = Lib.current.stage.stageHeight / 2 - inputBmp.height / 2;
        this.addChild(inputBmp);

        // INPUT TEXTFIELD
        this.login = Tool.getTextField(0, 0, "Guest", 80, TextFormatAlign.CENTER);
        this.login.type = openfl.text.TextFieldType.INPUT;
        this.login.maxChars = 8;
        this.login.height = inputBmp.height;
        this.login.width = inputBmp.width;
        this.login.textColor = 0xD95B43;
        this.login.x = Lib.current.stage.stageWidth / 2 - this.login.width / 2;
        this.login.y = Lib.current.stage.stageHeight / 2 - this.login.height / 2 + 10;
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
        #if deploy
        #else
        popGame();
        #end
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
