import flash.display.MovieClip;
import flash.text.TextField;

/**
 * Stand-in for the lost Zynga asset assets/displays/screens/UnitsPurchaseDialog.swf.
 *
 * The game's UnitsPurchaseDialog ("Buy Units" in battle setup) instantiates the exported class
 * MainScreen_mc and hands it to ChallengePremiumUnitsGrid, a 5 x 2 GridScreen of cards made from
 * the exported class PremiumUnitCard. All texts, icons and prices are filled in by the game, so
 * this only provides the layout.
 */
class MainScreen_mc extends MovieClip {
	public static inline var COLUMNS = 5;
	public static inline var ROWS = 2;
	static inline var SIDE = 60;
	static inline var TOP = 70;
	public static inline var WIDTH = SIDE * 2 + COLUMNS * PremiumUnitCard.WIDTH;
	public static inline var HEIGHT = TOP + ROWS * PremiumUnitCard.HEIGHT + 30;

	public var background_mc:MovieClip;
	public var caption_tf:TextField;
	public var header_tf:TextField;
	public var exit_bt:MovieClip;
	public var origin_mc:MovieClip;
	public var anchor_mc:MovieClip;
	public var mask_mc:MovieClip;
	public var arrowLt_bt:MovieClip;
	public var arrowRt_bt:MovieClip;

	public function new() {
		super();

		background_mc = new MovieClip();
		background_mc.graphics.beginFill(0x7A4A1C);
		background_mc.graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, 36, 36);
		background_mc.graphics.endFill();
		background_mc.graphics.beginFill(0xF5EBD7);
		background_mc.graphics.drawRoundRect(8, 8, WIDTH - 16, HEIGHT - 16, 28, 28);
		background_mc.graphics.endFill();
		addChild(background_mc);

		caption_tf = UnitsPurchaseUI.createText(this, SIDE, 18, WIDTH - 2 * SIDE, 40, "CCSmash", 28, 0x7A3B10);
		// Only filled by grids that override fillOutHeader, not by ChallengePremiumUnitsGrid
		header_tf = UnitsPurchaseUI.createText(this, SIDE, 48, WIDTH - 2 * SIDE, 20, "Futura Std Medium", 13, 0x4A2A10);

		// The grid places anchor_mc at origin_mc and slides it a page at a time, clipped by mask_mc
		origin_mc = UnitsPurchaseUI.createRect(this, SIDE, TOP, 1, 1, 0x000000, 0);
		anchor_mc = new MovieClip();
		addChild(anchor_mc);
		mask_mc = UnitsPurchaseUI.createRect(this, SIDE, TOP, COLUMNS * PremiumUnitCard.WIDTH, ROWS * PremiumUnitCard.HEIGHT, 0x000000);

		var arrowY = TOP + PremiumUnitCard.HEIGHT - 24;
		arrowLt_bt = createArrow(false);
		arrowLt_bt.x = 14;
		arrowLt_bt.y = arrowY;
		arrowRt_bt = createArrow(true);
		arrowRt_bt.x = WIDTH - 50;
		arrowRt_bt.y = arrowY;

		exit_bt = createExitButton();
		exit_bt.x = WIDTH - 50;
		exit_bt.y = 14;
		addChild(exit_bt);
	}

	function createArrow(right:Bool):MovieClip {
		var arrow = new MovieClip();
		arrow.graphics.beginFill(0xE67E22);
		arrow.graphics.drawRoundRect(0, 0, 36, 48, 10, 10);
		arrow.graphics.endFill();
		arrow.graphics.beginFill(0xFFFFFF);
		if (right) {
			arrow.graphics.moveTo(12, 12);
			arrow.graphics.lineTo(26, 24);
			arrow.graphics.lineTo(12, 36);
		} else {
			arrow.graphics.moveTo(24, 12);
			arrow.graphics.lineTo(10, 24);
			arrow.graphics.lineTo(24, 36);
		}
		arrow.graphics.endFill();
		arrow.buttonMode = true;
		addChild(arrow);
		return arrow;
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
}
