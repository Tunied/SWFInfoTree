package app.debug
{
	import com.junkbyte.console.Cc;

	import flash.display.Stage;

	public final class APPLog
	{
		public static function log(... args):void
		{
			Cc.info(args);
		}

		public static function err(... args):void
		{
			Cc.stack("Error:------------->\n" + args);
		}

		public static function initialize(_stage:Stage):void
		{
			Cc.config.commandLineAllowed=true;
			Cc.config.tracing=true;
			Cc.x=0;
			Cc.y=0;
			Cc.width=1000;
			Cc.height=500;
			Cc.startOnStage(_stage);
		}


		public function APPLog()
		{
		}
	}
}
