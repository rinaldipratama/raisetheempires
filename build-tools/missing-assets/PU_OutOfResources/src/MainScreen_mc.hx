import flash.display.MovieClip;
import flash.system.ApplicationDomain;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

/**
 * Stand-in for the lost Zynga asset assets/displays/dialogs/PU_OutOfResources.swf.
 *
 * The game's RequirementsPopup (population cap) and OutOfUnitsPopup instantiate the exported
 * class MainScreen_mc and look up the children below by name. All texts and icons are filled
 * in by the game, so this only provides the layout.
 *
 * Asset SWFs are loaded into the game's ApplicationDomain, so class names here must not clash
 * with the game's (hence the PUOutOfResources prefix on the helper classes).
 */
class MainScreen_mc extends MovieClip {
	public static inline var WIDTH = 600;
	public static inline var HEIGHT = 420;
	public static inline var ICON_SIZE = 96;
	static inline var MARGIN = 40;

	public var frame_mc:MovieClip;
	public var exit_bt:MovieClip;
	public var accept_bt:PUOutOfResourcesButton;
	public var title_tf:TextField;
	public var bubble_tf:TextField;
	public var desc_tf:TextField;
	public var steps_2_mc:PUOutOfResourcesSteps;
	public var steps_3_mc:PUOutOfResourcesSteps;

	public function new() {
		super();

		frame_mc = new MovieClip();
		frame_mc.graphics.beginFill(0x7A4A1C);
		frame_mc.graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, 36, 36);
		frame_mc.graphics.endFill();
		frame_mc.graphics.beginFill(0xF5EBD7);
		frame_mc.graphics.drawRoundRect(8, 8, WIDTH - 16, HEIGHT - 16, 28, 28);
		frame_mc.graphics.endFill();
		addChild(frame_mc);

		title_tf = createText(MARGIN, 22, WIDTH - 2 * MARGIN, 44, "CCSmash", 28, 0x7A3B10);
		bubble_tf = createText(MARGIN, 72, WIDTH - 2 * MARGIN, 70, "Futura Std Medium", 16, 0x4A2A10);
		desc_tf = createText(MARGIN, 262, WIDTH - 2 * MARGIN, 70, "Futura Std Medium", 16, 0x4A2A10);

		steps_2_mc = new PUOutOfResourcesSteps(2, WIDTH, 150);
		steps_3_mc = new PUOutOfResourcesSteps(3, WIDTH, 150);
		addChild(steps_2_mc);
		addChild(steps_3_mc);

		accept_bt = new PUOutOfResourcesButton(200, 48);
		accept_bt.x = (WIDTH - 200) / 2;
		accept_bt.y = HEIGHT - 75;
		addChild(accept_bt);

		exit_bt = createExitButton();
		exit_bt.x = WIDTH - 50;
		exit_bt.y = 14;
		addChild(exit_bt);
	}

	function createText(x:Float, y:Float, width:Float, height:Float, font:String, size:Int, color:Int):TextField {
		// Not embedFonts: the game's TextFieldUtil maps these font names to its embedded fonts.
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(font, size, color, null, null, null, null, null, TextFormatAlign.CENTER);
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = false;
		addChild(field);
		return field;
	}

	static function createExitButton():MovieClip {
		var button = new MovieClip();
		button.graphics.beginFill(0xB3261E);
		button.graphics.drawRoundRect(0, 0, 36, 36, 10, 10);
		button.graphics.endFill();
		button.graphics.lineStyle(4, 0xFFFFFF);
		button.graphics.moveTo(11, 11);
		button.graphics.lineTo(25, 25);
		button.graphics.moveTo(25, 11);
		button.graphics.lineTo(11, 25);
		button.buttonMode = true;
		return button;
	}

	public static function createIconLoader():Dynamic {
		// The popups pass the icons to methods typed fl.containers.UILoader, so they must be
		// instances of the game's own UILoader class.
		var domain = ApplicationDomain.currentDomain;
		if (domain.hasDefinition("fl.containers.UILoader")) {
			var loader:Dynamic = Type.createInstance(cast domain.getDefinition("fl.containers.UILoader"), []);
			loader.setSize(ICON_SIZE, ICON_SIZE);
			return loader;
		}
		return new MovieClip();
	}
}
