import flash.display.MovieClip;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

/** Green button for the game's ZGameButton, which requires a generic_tf TextField for its label. */
class PUOutOfResourcesButton extends MovieClip {
	public var generic_tf:TextField;

	public function new(width:Int, height:Int) {
		super();
		graphics.lineStyle(3, 0x3E7A1E);
		graphics.beginFill(0x6DB33F);
		graphics.drawRoundRect(0, 0, width, height, 18, 18);
		graphics.endFill();

		generic_tf = new TextField();
		generic_tf.defaultTextFormat = new TextFormat("CCSmash", 22, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER);
		generic_tf.width = width;
		generic_tf.height = height - 10;
		generic_tf.y = 9;
		generic_tf.selectable = false;
		addChild(generic_tf);
	}

	// ZGameButton switches between up/over/down frames; this clip has a single frame.
	override public function gotoAndStop(frame:Dynamic, ?scene:String):Void {}
}
