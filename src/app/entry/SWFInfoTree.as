package app.entry
{
	import flash.display.Sprite;
	import flash.events.Event;

	import app.configuration.ConfigMeta;
	import app.debug.APPLog;

	import copyengine.ui.starling.component.meta.CESMetaFacade;

	public class SWFInfoTree extends Sprite
	{
		public function SWFInfoTree()
		{
			this.addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
		}

		private function onAddToStage(e:Event):void
		{
			//初始化Log
			APPLog.initialize(this.stage);
			//Import所有Meta
			CESMetaFacade.initialize();
			//初始化Config信息
			ConfigMeta.instance.initialize(onConfigMetaInitComplate);
		}

		private function onConfigMetaInitComplate():void
		{
			APPLog.log("tool start...");
		}

	}
}
