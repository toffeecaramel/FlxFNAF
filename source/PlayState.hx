package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import obj.*;

class PlayState extends FlxState
{
	// -- GAME PROPERTIES -- //
	// camera speed btw
	final speed:Float = 325;

	// camera movement stuff
	// green zone is low speed
	// and orange zone is high speed
	// thanks to LunaMyria for telling me how it works :]
	final orangeZone:Float = 164;
	final greenZone:Float = 132;

	// -- GAME OBJECTS -- //
	public static var instance:PlayState;
	public var office:FlxSprite;
	public var cam:FlxSprite;
	public var mask:FlxSprite;

	public var camBtn:ButtonInteract;
	public var maskBtn:ButtonInteract;

	// cams
	public var camHUD:FlxCamera = new FlxCamera();
	public var camALT:FlxCamera = new FlxCamera();
	public var camGAME:FlxCamera = new FlxCamera();

	override public function create():Void
	{
		super.create();

		camGAME.bgColor = 0xFF000000;
		camHUD.bgColor = 0x00000000;
		camALT.bgColor = 0x00000000;

		FlxG.cameras.add(camGAME, true);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camALT, false);

		office = new FlxSprite(0, 0, "assets/images/game/office.png");
		office.screenCenter(Y);
		add(office);

		mask = new FlxSprite().loadGraphic('assets/images/game/UI/mask.png', true, 1024, 768);
		mask.animation.add('down', [0,1,2,3,4,5,6,7,8], false);
		mask.camera = camHUD;
		mask.screenCenter();
		mask.visible = false;
		mask.animation.onFinish.add(_ -> mask.visible = maskBool);
		add(mask);

		camBtn = new ButtonInteract();
		camBtn.camera = camHUD;
		add(camBtn);
		camBtn.setPosition(FlxG.width - camBtn.width, FlxG.height - camBtn.height);
		camBtn.onHover.add(openCamera);

		maskBtn = new ButtonInteract();
		maskBtn.camera = camHUD;
		maskBtn.color = 0xFFf292a6;
		add(maskBtn);
		maskBtn.setPosition(0, FlxG.height - camBtn.height);
		maskBtn.onHover.add(openMask);

		cam = new FlxSprite().loadGraphic('assets/images/game/UI/camera.png', true, 1024, 768);
		cam.animation.add('appear', [0,1,2,3,4,5,6,7,8,9,10], false);
		cam.camera = camHUD; //lol cam.camera
		cam.screenCenter();
		cam.visible = false;
		cam.animation.onFinish.add(_ -> cam.visible = false);
		add(cam);

		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;

		camGAME.setScrollBoundsRect(0, 0, office.width, FlxG.height);
	}

	public var camBool:Bool = false;
	public var maskBool:Bool = false;
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		final mx = FlxG.mouse.viewX;
		var s = 0.0;

		if (mx < orangeZone)
			s = -speed * 2.3;
		else if (mx < greenZone + orangeZone)
			s = -speed;
		else if (mx > FlxG.width - orangeZone)
			s = speed * 2.3;
		else if (mx > FlxG.width - (greenZone + orangeZone))
			s = speed;

		//if(FlxG.keys.justPressed.C)
		//	openCamera();

		camGAME.scroll.x += s * elapsed;
		// FlxG.camera.scroll.x = FlxMath.bound(FlxG.camera.scroll.x, 0, office.width - FlxG.width);
	}

	public function openCamera()
	{
		camBool = !camBool;
		maskBtn.interactable = !camBool;
		cam.animation.play('appear', true, !camBool);
		cam.visible = true;
		FlxG.sound.play('assets/sounds/UI/cam_${(camBool) ? 'enter' : 'leave'}.wav');
	}

	public function openMask()
	{
		maskBool = !maskBool;
		camBtn.interactable = !maskBool;
		mask.animation.play('down', true, !maskBool);
		mask.visible = true;
		FlxG.sound.play('assets/sounds/UI/mask_${(maskBool) ? 'enter' : 'leave'}.wav');
	}

	override public function draw():Void
	{
		super.draw();

		//because why not?
		#if debug
		var gfx = camGAME.debugLayer.graphics;

		gfx.clear();

		// LEFT ORANGE
		gfx.beginFill(FlxColor.ORANGE, 0.2);
		gfx.drawRect(0, 0, orangeZone, FlxG.height);
		gfx.endFill();

		// LEFT GREEN
		gfx.beginFill(FlxColor.LIME, 0.15);
		gfx.drawRect(orangeZone, 0, greenZone, FlxG.height);
		gfx.endFill();

		// RIGHT ORANGE
		gfx.beginFill(FlxColor.ORANGE, 0.2);
		gfx.drawRect(FlxG.width - orangeZone, 0, orangeZone, FlxG.height);
		gfx.endFill();

		// RIGHT GREEN
		gfx.beginFill(FlxColor.LIME, 0.15);
		gfx.drawRect(FlxG.width - orangeZone - greenZone, 0, greenZone, FlxG.height);
		gfx.endFill();
		#end
	}
}