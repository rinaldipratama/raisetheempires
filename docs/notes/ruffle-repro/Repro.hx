import flash.events.NetStatusEvent;
import flash.external.ExternalInterface;
import flash.net.NetConnection;
import flash.net.Responder;
import flash.text.TextField;

/**
 * Minimal Flash Remoting client for two Ruffle bugs.
 *
 * FlashVar gateway: URL passed to NetConnection.connect(), e.g. "gateway" (relative) or
 * "http://127.0.0.1:8765/gateway" (absolute). The server's Echo.shared reply is an object whose
 * "first" and "second" properties are the same object, so an AMF0 encoder writes "second" as a
 * reference (type marker 0x07) to "first".
 */
class Repro {
	static var output:TextField;

	static function main() {
		output = new TextField();
		output.width = 760;
		output.height = 560;
		flash.Lib.current.addChild(output);

		var gateway:String = flash.Lib.current.loaderInfo.parameters.gateway;
		var connection = new NetConnection();
		connection.addEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent) report("netStatus " + e.info.code));
		connection.connect(gateway);
		report("connect(" + gateway + ") done, calling Echo.shared");
		connection.call("Echo.shared", new Responder(function(result:Dynamic) {
			report("result: first.name=" + result.first.name + ", second=" + result.second
				+ (result.second == null ? "" : ", second.name=" + result.second.name));
		}, function(fault:Dynamic) report("fault " + fault)));
		report("call() returned");
	}

	static function report(line:String) {
		output.appendText(line + "\n");
		if (ExternalInterface.available) {
			ExternalInterface.call("reproLog", line);
		}
	}
}
