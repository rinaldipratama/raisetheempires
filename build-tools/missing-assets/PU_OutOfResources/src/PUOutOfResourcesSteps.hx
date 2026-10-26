import flash.display.MovieClip;

/** Row of icon slots (steps_2_mc / steps_3_mc); the game loads icons into icon0_mc, icon1_mc, icon2_mc. */
class PUOutOfResourcesSteps extends MovieClip {
	static inline var GAP = 40;

	public var icon0_mc:Dynamic;
	public var icon1_mc:Dynamic;
	public var icon2_mc:Dynamic;

	public function new(count:Int, frameWidth:Int, top:Float) {
		super();
		var size = MainScreen_mc.ICON_SIZE;
		var left = (frameWidth - (count * size + (count - 1) * GAP)) / 2;
		y = top;
		for (i in 0...count) {
			var slotX = left + i * (size + GAP);
			graphics.beginFill(0xE6D3B3);
			graphics.drawRoundRect(slotX - 4, -4, size + 8, size + 8, 14, 14);
			graphics.endFill();

			var icon:Dynamic = MainScreen_mc.createIconLoader();
			icon.x = slotX;
			addChild(icon);
			Reflect.setField(this, "icon" + i + "_mc", icon);
		}
	}
}
