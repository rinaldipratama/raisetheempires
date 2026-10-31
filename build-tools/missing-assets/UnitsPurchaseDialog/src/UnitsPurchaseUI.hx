import flash.display.MovieClip;
import flash.system.ApplicationDomain;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

/** Drawing helpers shared by MainScreen_mc and PremiumUnitCard. */
class UnitsPurchaseUI {
	public static function createText(parent:MovieClip, x:Float, y:Float, width:Float, height:Float, font:String, size:Int, color:Int):TextField {
		// Not embedFonts: the game's TextFieldUtil maps these font names to its embedded fonts.
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(font, size, color, null, null, null, null, null, TextFormatAlign.CENTER);
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		parent.addChild(field);
		return field;
	}

	public static function createIconLoader(parent:MovieClip, x:Float, y:Float, size:Int):Dynamic {
		// ImageLoaderFactory.CreateImageLoader takes a fl.containers.UILoader, so icons must be
		// instances of the game's own UILoader class.
		var domain = ApplicationDomain.currentDomain;
		var loader:Dynamic;
		if (domain.hasDefinition("fl.containers.UILoader")) {
			loader = Type.createInstance(cast domain.getDefinition("fl.containers.UILoader"), []);
			loader.setSize(size, size);
		} else {
			loader = new MovieClip();
		}
		loader.x = x;
		loader.y = y;
		parent.addChild(loader);
		return loader;
	}

	public static function createRect(parent:MovieClip, x:Float, y:Float, width:Float, height:Float, color:Int, alpha:Float = 1):MovieClip {
		var clip = new MovieClip();
		clip.graphics.beginFill(color, alpha);
		clip.graphics.drawRect(0, 0, width, height);
		clip.graphics.endFill();
		clip.x = x;
		clip.y = y;
		parent.addChild(clip);
		return clip;
	}

	public static function createBorder(parent:MovieClip, width:Float, height:Float, color:Int, thickness:Float):MovieClip {
		var clip = new MovieClip();
		clip.graphics.lineStyle(thickness, color);
		clip.graphics.drawRoundRect(0, 0, width, height, 16, 16);
		clip.mouseEnabled = false;
		parent.addChild(clip);
		return clip;
	}
}
