package obj;

import flixel.*;
import flixel.util.FlxSignal;

class ButtonInteract extends FlxSprite
{
	public var interactable:Bool = true;
	public final onHover:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		loadGraphic('assets/images/game/UI/interactbtn.png');
		updateHitbox();
	}

	private var _inHover:Bool = false;
	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		visible = interactable;
		if(!visible) return;

		if(FlxG.mouse.overlaps(this, this.camera) && !_inHover)
		{
			_inHover = true;
			onHover.dispatch();
		}
		else if(!FlxG.mouse.overlaps(this, this.camera) && _inHover)
			_inHover = false;
	}
}