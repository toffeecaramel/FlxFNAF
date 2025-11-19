package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;

class PlayState extends FlxState
{
	var office:FlxSprite;
	var scrollSpeed:Float = 500;
	var edgeThreshold:Float = 100;

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
		if (FlxG.mouse.viewX < edgeThreshold)
			FlxG.camera.scroll.x -= scrollSpeed * elapsed;
		else if (FlxG.mouse.viewX > FlxG.width - edgeThreshold)
			FlxG.camera.scroll.x += scrollSpeed * elapsed;

		FlxG.camera.scroll.x = FlxMath.bound(FlxG.camera.scroll.x, 0, office.width - FlxG.width);
	}
}