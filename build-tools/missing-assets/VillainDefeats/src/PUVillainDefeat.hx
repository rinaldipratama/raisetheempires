import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.GradientType;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.geom.Matrix;
import flash.system.ApplicationDomain;

/**
 * Stand-in for lost villain defeat clips (assets/game/villains/defeats/*, Campaign02_Defeats/*).
 *
 * BattleBasePopup loads the defeat SWF and adds its root clip to the victory popup. The original
 * clips showed the beaten villain in a round frame (about 180x240 px from the clip origin). This
 * draws a similar frame and fills it with the villain's portrait from the game's own villain SWF
 * (e.g. "assets/game/villains/Villains01.swf/VP_04.png"). No game art is copied into this SWF.
 *
 * The game loads every asset SWF with Loader.loadBytes and no LoaderContext, so each one gets its
 * own child ApplicationDomain: the portrait classes are not visible from here. The portrait is
 * fetched the way the game's SWFImageLoader does it, through the game's (cached) resource manager
 * and SWFResource.getAssetClass. The game classes are reachable because their domain is our parent.
 */
class PUVillainDefeat {
	static inline var CENTER_X = 115;
	static inline var CENTER_Y = 165;
	static inline var OUTER_RADIUS = 90;
	static inline var INNER_RADIUS = 78;

	public static function draw(clip:MovieClip, portraitUrl:String):Void {
		var frame = new Shape();
		frame.graphics.beginFill(0x5A3A1E);
		frame.graphics.drawCircle(CENTER_X, CENTER_Y, OUTER_RADIUS);
		frame.graphics.beginFill(0xD9822B);
		frame.graphics.drawCircle(CENTER_X, CENTER_Y, OUTER_RADIUS - 4);
		var gradient = new Matrix();
		gradient.createGradientBox(INNER_RADIUS * 2, INNER_RADIUS * 2, 0, CENTER_X - INNER_RADIUS, CENTER_Y - INNER_RADIUS);
		frame.graphics.beginGradientFill(GradientType.RADIAL, [0xFFF6B0, 0xF2C230], [1, 1], [0, 255], gradient);
		frame.graphics.drawCircle(CENTER_X, CENTER_Y, INNER_RADIUS);
		frame.graphics.endFill();
		clip.addChild(frame);

		loadPortrait(portraitUrl, function(portrait:BitmapData) {
			var bitmap = new Bitmap(portrait, flash.display.PixelSnapping.AUTO, true);
			var scale = INNER_RADIUS * 2 / Math.min(portrait.width, portrait.height);
			bitmap.scaleX = bitmap.scaleY = scale;
			bitmap.x = CENTER_X - portrait.width * scale / 2;
			bitmap.y = CENTER_Y - portrait.height * scale / 2;
			var mask = new Shape();
			mask.graphics.beginFill(0);
			mask.graphics.drawCircle(CENTER_X, CENTER_Y, INNER_RADIUS);
			mask.graphics.endFill();
			bitmap.mask = mask;
			clip.addChild(mask);
			clip.addChild(bitmap);
		});
	}

	/** Same steps as the game's displays.SWFImageLoader; leaves the frame empty if anything is missing. */
	static function loadPortrait(url:String, onLoaded:BitmapData->Void):Void {
		var domain = ApplicationDomain.currentDomain;
		var swfEnd = url.indexOf(".swf/") + 4;
		if (swfEnd < 4 || !domain.hasDefinition("zlabs.Zlab") || !domain.hasDefinition("Engine.Managers.AssetUrlManager")) {
			return;
		}
		var imageName = url.substr(swfEnd + 1);
		var zlab:Dynamic = domain.getDefinition("zlabs.Zlab");
		var assetUrls:Dynamic = domain.getDefinition("Engine.Managers.AssetUrlManager");
		var swfResource:Dynamic = domain.getDefinition("zlabs.resource.SWFResource");
		zlab.resourceManager.load(assetUrls.instance.lookUpUrl(url.substr(0, swfEnd)), swfResource, function(resource:Dynamic) {
			var portraitClass:Dynamic = resource.getAssetClass(imageName);
			if (portraitClass != null) {
				onLoaded(Type.createInstance(portraitClass, [1, 1]));
			}
		});
	}
}
