package backend;

class Animatronic
{
	public var name:String;
	public var position:String;
	public var isActive:Bool = true;
	public var stunTimer:Float = 0;
	public var path:Array<String> = [];

	public function new(name:String, ?path:Array<String>)
	{
		this.name = name;
		this.position = "";
		this.isActive = true;
		this.stunTimer = 0;
		this.path = path;
	}

	public function update(dt:Float):Void
	{
		if (stunTimer > 0)
		{
			stunTimer -= dt;
			if (stunTimer <= 0) stunTimer = 0;
		}
		else
			_tryMove(dt);
	}

	public function stun(seconds:Float):Void
		stunTimer = Math.max(stunTimer, seconds);

	function _tryMove(dt:Float):Void {
		//TODO: SET ROOMS MOVEMENT
	}
}