package backend;

enum AIState {
	ROAMING;
	MOVING;
	WAITING;
	INROOM;
	ATTACKING;
}

class Animatronic
{
	public var name:String;
	public var position:String;
	public var isActive:Bool = true;
	public var stunTimer:Float = 0;

	// PATH related
	public var path:Array<String> = [];
	public var pathIndex:Int = 0;

	// AI / behavior
	public var aiLevel:Int = 1;
	public var waitIfBusy:Bool = true;
	public var roomTime:Float = 3.0;

	// runtime timers / state
	public var state(default, set):AIState = ROAMING;
	public var moveTimer:Float = 0;
	public var inRoomTimer:Float = 0;

	public function new(name:String, ?path:Array<String>, ?aiLevel:Int = 1)
	{
		this.name = name;
		this.position = "";
		this.isActive = true;

		this.stunTimer = 0;
		this.path = path == null ? [] : path;
		this.pathIndex = 0;
		this.aiLevel = aiLevel;
		this.waitIfBusy = true;
		this.roomTime = 2 + (1.0 / Math.max(1, aiLevel));
		this.state = ROAMING;
	}

	public function update(dt:Float):Void
	{
		// stun handling
		if (stunTimer > 0)
		{
			stunTimer -= dt;
			if (stunTimer <= 0) stunTimer = 0;
			return;
		}

		switch(state)
		{
			case MOVING:
				moveTimer -= dt;
				if (moveTimer <= 0) {
					// arrived, attempt to enter the target room
					final target = path[pathIndex];
					if (target != null)
					{
						final granted = NightManager.requestRoomEntry(this, target);
						if (granted)
						{
							// will be set into room by NightManager or immediately
							_onGrantedRoom(target);
						}
						else
						{
							// requestRoomEntry queued us or we are waiting already
							// uhhmmm so yeah
						}
					}
					else
					{
						// path ended, roam
						set_state(ROAMING);
					}
				}
			case WAITING:
				// just idle until a room is granted
			case INROOM:
				inRoomTimer -= dt;
				//trace('$name is at $position');
				if (inRoomTimer <= 0)
				{
					// leave room and move to next path index
					NightManager.leaveRoom(position, this);
					position = "";
					advancePathIndex();
					scheduleMoveToNext();
				}
			case ROAMING:
				// choose to start path movement occasionally
				if (path.length > 0)
					scheduleMoveToNext();
			case ATTACKING:
				// will be handled in playstate when on office!
		}
	}

	/** called when NightManager grants entry to a room (including instant grant) */
	public function _onGrantedRoom(room:String):Void
	{
		position = room;
		set_state(INROOM);
		inRoomTimer = roomTime;

		if (room == "office") {
			set_state(ATTACKING);
			trace('Got attacked by $name!');
		}
	}

	/** schedule movement to next path node, and compute travel time from aiLevel */
	public function scheduleMoveToNext():Void
	{
		if (path.length == 0) return;

		if (path[pathIndex] == null) {
			set_state(ROAMING);
			return;
		}
		set_state(MOVING);

		// travel time inversely proportional to aiLevel
		moveTimer = NightManager.BASE_MOVE_TIME / Math.max(1, aiLevel);
	}

	public function advancePathIndex():Void
	{
		pathIndex++;
		if (pathIndex >= path.length) pathIndex = 0;
	}

	public function stun(seconds:Float):Void
		stunTimer = Math.max(stunTimer, seconds);

	// internal setter helpers
	public function set_state(s:AIState):AIState {
		state = s;
		// maybe do some other things?
		return state;
	}
}
