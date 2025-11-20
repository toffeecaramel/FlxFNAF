package;

import backend.*;
import flixel.util.FlxSignal;
import haxe.ds.StringMap;

/**
 * NightManager (extended)
 * - roomOccupants: single-occupancy map roomName -> Animatronic
 * - waitQueues: map roomName -> Array<Animatronic>
 */
class NightManager
{
	// ---------- config ---------- //
	public static var batteryMaxByNight:Array<Float> = [117, 100, 83, 67, 50, 50];
	public static inline var BATTERY_BARS:Int = 5;
	public static inline var CAMERA_FLASH_COST:Float = 0.5;

	public static inline var BASE_MOVE_TIME:Float = 16.0;

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

	// ---------- ROOM / OCCUPANCY ----------
	// single occupant per room (null = free)
	static var roomOccupants:StringMap<Animatronic> = new StringMap<Animatronic>();
	// queues for rooms where anims wait: roomName -> Array<Animatronic>
	static var waitQueues:StringMap<Array<Animatronic>> = new StringMap<Array<Animatronic>>();

	// optional signals
	public static var onRoomEntered = new FlxTypedSignal<(String, Animatronic)->Void>();
	public static var onRoomLeft = new FlxTypedSignal<(String, Animatronic)->Void>();

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

		// register rooms uhh
		final rooms = ['stage', 'game-area', 'prize-corner', 'kids-cove', 
		'main-hall', 'parts&services', 'p4', 'p3', 'p2', 'p1', 'office-hall',
		'left-vent', 'right-vent', 'office'];
		for(room in rooms)
			registerRoom(room);

		animatronics = [
			new Animatronic("toffee", ["stage","game-area","main-hall","p2", "right-vent", "office"], 1)
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

	// ---------- flash / battery ----------
	public static function setFlashOn(on:Bool):Void
	{
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
		final ratio = batteryRemaining / batteryMax;
		final bars:Int = Std.int(Math.ceil(ratio * BATTERY_BARS));
		return Std.int(Math.max(0, Math.min(bars, BATTERY_BARS)));
	}

	public static function refillBattery():Void {
		batteryRemaining = batteryMax;
		batteryDepleted = false;
		_triggerBatteryChanged();
	}

	// ---------- rooms API ----------
	public static function registerRoom(room:String):Void
	{
		if (!roomOccupants.exists(room)) roomOccupants.set(room, null);
		if (!waitQueues.exists(room)) waitQueues.set(room, []);
	}

	/**
	 * Requests entry to a room! If free, grant and return true.
	 */
	public static function requestRoomEntry(anim:Animatronic, room:String):Bool
	{
		trace('${anim.name} requested a room entry at $room!');
		if (!roomOccupants.exists(room)) registerRoom(room);

		if (roomOccupants.get(room) == null) {
			roomOccupants.set(room, anim);
			onRoomEntered.dispatch(room, anim);
			return true;
		}

		// already occupied
		if (anim.waitIfBusy) {
			waitQueues.get(room).push(anim);
			anim.state = WAITING;
			return false;
		}

		// try to find next free in path
		var alt = findNextFreeInPath(anim, room);
		if (alt != null) {
			// let the anim attempt alt instead
			anim.pathIndex = anim.path.indexOf(alt);
			// request alt (this may grant or queue)
			return requestRoomEntry(anim, alt);
		}

		// fallbacks to queuee
		waitQueues.get(room).push(anim);
		anim.state = WAITING;
		return false;
	}

	public static function leaveRoom(room:String, anim:Animatronic):Void
	{
		if (!roomOccupants.exists(room)) return;

		trace('${anim.name} is leaving $room!');

		final occupant = roomOccupants.get(room);
		if (occupant == anim) roomOccupants.set(room, null);

		onRoomLeft.dispatch(room, anim);

		// if queue exists and has waiting anims, pop first and give entry
		final q = waitQueues.get(room);
		if (q != null && q.length > 0) {
			var next = q.shift();
			// assign occupant and notify
			roomOccupants.set(room, next);
			next._onGrantedRoom(room);
			onRoomEntered.dispatch(room, next);
		}
	}

	static function findNextFreeInPath(anim:Animatronic, blockedRoom:String):String
	{
		for (i in anim.pathIndex + 1 ... anim.path.length)
		{
			final r = anim.path[i];
			final occ = roomOccupants.get(r);
			if (occ == null) return r;
		}
		return null;
	}

	// ---------- internals ----------
	static function set_batteryRemaining(v:Float):Float
	{
		final prev = batteryRemaining;
		batteryRemaining = Math.max(0, Math.min(v, batteryMax));
		if (Math.abs(batteryRemaining - prev) > 0.0001) _triggerBatteryChanged();
		return batteryRemaining;
	}

	static function _triggerBatteryChanged():Void
		onBatteryChanged.dispatch(batteryRemaining, batteryMax);
}
