package;

import backend.*;
import flixel.util.FlxSignal;

class NightManager
{
	// ---------- config ---------- //
	public static var batteryMaxByNight:Array<Float> = [117, 100, 83, 67, 50, 50];
	public static inline var BATTERY_BARS:Int = 5;
	public static inline var CAMERA_FLASH_COST:Float = 0.5;

	public static var night:Int = 1;
	public static var batteryMax:Float = 50;
	public static var batteryRemaining(default, set):Float = 0;
	public static var flashlightDisabledTimer:Float = 0;
	public static var flashlightOn:Bool = false;
	public static var flashlightDisabled:Bool = false;
	public static var batteryDepleted:Bool = false;

	public static var animatronics:Array<Animatronic> = [];

	public static var onBatteryChanged = new FlxTypedSignal<(Float, Float)->Void>();
	public static var onBatteryDepleted = new FlxTypedSignal<Void->Void>();
	//public static var onFlashUsed = new FlxTypedSignal<Void->Void>();

	// ---------- functions ---------- //
	public static function init(n:Int):Void
	{
		night = Std.int(Math.min(Math.max(n, 1), batteryMaxByNight.length));

		batteryMax = batteryMaxByNight[night - 1];
		batteryRemaining = batteryMax;
		flashlightOn = false;
		flashlightDisabled = false;
		flashlightDisabledTimer = 0;
		batteryDepleted = false;

		animatronics = [
			new Animatronic("toy-bonnie", [])
		];

		_triggerBatteryChanged();
	}

	public static function update(dt:Float):Void
	{
		if (flashlightDisabledTimer > 0)
		{
			flashlightDisabledTimer -= dt;
			if (flashlightDisabledTimer <= 0)
			{
				flashlightDisabledTimer = 0;
				flashlightDisabled = false;
			}
		}

		if (flashlightOn && !flashlightDisabled && !batteryDepleted)
			set_batteryRemaining(batteryRemaining - dt);

		for (a in animatronics) a.update(dt);

		if (!batteryDepleted && batteryRemaining <= 0)
		{
			batteryDepleted = true;
			flashlightOn = false;
			onBatteryDepleted.dispatch();
		}
	}


	public static function setFlashOn(on:Bool):Void
	{
		// won't allow if its over/depleted!
		if (on && (flashlightDisabled || batteryDepleted)) {
			flashlightOn = false;
			return;
		}
		flashlightOn = on;
	}

	public static function disableFlashFor(seconds:Float):Void
	{
		flashlightDisabled = true;
		flashlightDisabledTimer = Math.max(0, seconds);
		flashlightOn = false;
	}

	public static function getBatteryBars():Int
	{
		if (batteryRemaining <= 0) return 0;
		// ratio + L + bozo... damn 
		final ratio = batteryRemaining / batteryMax;
		final bars:Int = Std.int(Math.ceil(ratio * BATTERY_BARS));
		return Std.int(Math.max(0, Math.min(bars, BATTERY_BARS)));
	}

	public static function refillBattery():Void {
		batteryRemaining = batteryMax;
		batteryDepleted = false;
		_triggerBatteryChanged();
	}

	// ---------- internals ---------- //
	static function set_batteryRemaining(v:Float):Float
	{
		var prev = batteryRemaining;
		batteryRemaining = Math.max(0, Math.min(v, batteryMax));
		if (Math.abs(batteryRemaining - prev) > 0.0001) _triggerBatteryChanged();
		return batteryRemaining;
	}

	static function _triggerBatteryChanged():Void
		onBatteryChanged.dispatch(batteryRemaining, batteryMax);
}