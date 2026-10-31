import flash.display.MovieClip;

/**
 * One unit card of the grid. GridSlot.createSlot does `new PremiumUnitCard().card_mc`, and the
 * slot classes (GridSlot, UnitSlot, PremiumUnitSlot, PremiumUnitSlotV2) fill in its children.
 *
 * card_mc and unitCard_mc are plain (dynamic) MovieClips with their children set as dynamic
 * properties: the game also probes optional children like unitCard_mc.tierRating_mc, which
 * would throw on a sealed Haxe class but are simply undefined on a dynamic one.
 */
class PremiumUnitCard extends MovieClip {
	public static inline var WIDTH = 132;
	public static inline var HEIGHT = 184;

	public var card_mc:MovieClip;

	public function new() {
		super();
		card_mc = new MovieClip();
		addChild(card_mc);

		// Grid spacing comes from sizer_mc (hidden by GridSlot)
		set(card_mc, "sizer_mc", UnitsPurchaseUI.createRect(card_mc, 0, 0, WIDTH, HEIGHT, 0x000000, 0));

		var frame = new MovieClip();
		frame.graphics.lineStyle(2, 0x7A4A1C);
		frame.graphics.beginFill(0xFFFDF6);
		frame.graphics.drawRoundRect(4, 4, WIDTH - 8, HEIGHT - 8, 16, 16);
		frame.graphics.endFill();
		card_mc.addChild(frame);

		var unitCard = new MovieClip();
		card_mc.addChild(unitCard);
		set(card_mc, "unitCard_mc", unitCard);

		var secondary = UnitsPurchaseUI.createBorder(unitCard, WIDTH - 12, HEIGHT - 12, 0xF39C12, 4);
		secondary.x = secondary.y = 6;
		set(unitCard, "secondaryCard_mc", secondary);

		set(unitCard, "itemName_tf", UnitsPurchaseUI.createText(unitCard, 8, 8, WIDTH - 16, 20, "Futura Std Medium", 12, 0x4A2A10));
		set(unitCard, "icon", UnitsPurchaseUI.createIconLoader(unitCard, (WIDTH - 80) / 2, 28, 80));
		set(unitCard, "discount_tf", UnitsPurchaseUI.createText(unitCard, 8, 28, WIDTH - 16, 18, "CCSmash", 13, 0xC0392B));

		// Shown with levelInfo_tf when the player's level is too low for this unit
		var locked = UnitsPurchaseUI.createRect(unitCard, (WIDTH - 80) / 2, 28, 80, 80, 0x333333, 0.45);
		locked.mouseEnabled = false;
		set(unitCard, "locked_mc", locked);
		set(unitCard, "levelInfo_tf", UnitsPurchaseUI.createText(unitCard, 8, 128, WIDTH - 16, 18, "Futura Std Medium", 11, 0xC0392B));

		set(unitCard, "strengthIcon_mc", UnitsPurchaseUI.createIconLoader(unitCard, 12, 110, 20));
		set(unitCard, "strengthValue_tf", UnitsPurchaseUI.createText(unitCard, 32, 111, 34, 18, "Futura Std Medium", 13, 0x4A2A10));
		set(unitCard, "energyIcon_mc", UnitsPurchaseUI.createIconLoader(unitCard, 70, 110, 20));
		set(unitCard, "energyValue_tf", UnitsPurchaseUI.createText(unitCard, 90, 111, 30, 18, "Futura Std Medium", 13, 0x4A2A10));
		set(unitCard, "strengthBar_mc", UnitsPurchaseUI.createRect(unitCard, 12, 131, 54, 3, 0xE67E22));
		set(unitCard, "cashIcon_mc", UnitsPurchaseUI.createIconLoader(unitCard, 40, 134, 18));
		set(unitCard, "cost_tf", UnitsPurchaseUI.createText(unitCard, 58, 134, 36, 18, "Futura Std Medium", 13, 0x2E7D32));

		var buy = new UnitsPurchaseButton(WIDTH - 28, 26, 13);
		buy.x = 14;
		buy.y = HEIGHT - 36;
		card_mc.addChild(buy);
		set(card_mc, "buy_bt", buy);

		set(card_mc, "highlightSelect_mc", UnitsPurchaseUI.createBorder(card_mc, WIDTH - 4, HEIGHT - 4, 0xFFD54F, 3));
		set(card_mc, "selected_mc", UnitsPurchaseUI.createBorder(card_mc, WIDTH - 4, HEIGHT - 4, 0x2E86C1, 3));
	}

	static inline function set(clip:MovieClip, name:String, child:Dynamic):Void {
		Reflect.setField(clip, name, child);
	}
}
