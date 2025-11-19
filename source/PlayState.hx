package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	var office:FlxSprite;
	final speed:Float = 300;

	final orangeZone:Float = 130;
	final greenZone:Float = 110;

	override public function create():Void
	{
		super.create();

		office = new FlxSprite(0, 0, "assets/images/game/office.png");
		add(office);

		FlxG.camera.setScrollBoundsRect(0, 0, office.width, FlxG.height);
		office.screenCenter(Y);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		final mx = FlxG.mouse.viewX;
		var s = 0.0;

		if (mx < orangeZone)
			s = -speed * 2;
		else if (mx < greenZone + orangeZone)
			s = -speed;
		else if (mx > FlxG.width - orangeZone)
			s = speed * 2;
		else if (mx > FlxG.width - (greenZone + orangeZone))
			s = speed;

		FlxG.camera.scroll.x += s * elapsed;
		// FlxG.camera.scroll.x = FlxMath.bound(FlxG.camera.scroll.x, 0, office.width - FlxG.width);
	}

	override public function draw():Void
	{
		super.draw();

		#if debug
		var gfx = FlxG.camera.debugLayer.graphics;

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