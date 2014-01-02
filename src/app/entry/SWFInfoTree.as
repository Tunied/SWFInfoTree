package app.entry
{
	import flash.desktop.NativeApplication;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.UncaughtErrorEvent;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;

	import app.configuration.ConfigMeta;
	import app.configuration.ConfigMetaNodeFile;
	import app.debug.APPLog;
	import app.displayTree.DisplayTreeBuildManger;

	import copyengine.ui.starling.component.meta.CESMetaFacade;

	import org.as3commons.lang.StringUtils;

	public class SWFInfoTree extends Sprite
	{
		private var displayTreeBuildManger:DisplayTreeBuildManger;


		public function SWFInfoTree()
		{
			this.addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
			this.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onGlobalError);
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

		private function onGlobalError(e:Event):void
		{
			APPLog.err(e.toString());
			e.preventDefault();
			e.stopImmediatePropagation();
			e.stopPropagation();
		}

		private function onConfigMetaInitComplate():void
		{
			displayTreeBuildManger=new DisplayTreeBuildManger();
			displayTreeBuildManger.initialize();

			APPLog.log("Tool start...");
			var allFileNodeMetaVector:Vector.<ConfigMetaNodeFile>=ConfigMeta.instance.allNodeFileVector;
			for each (var nodeConfigFile:ConfigMetaNodeFile in allFileNodeMetaVector)
			{
				APPLog.log("Start anylise file : " + nodeConfigFile.inputFile);
				var resultObj:Object=separateMaskPHAndNormalSymbol(nodeConfigFile.domain);

				//=====Push所有的Mask
				for each (var reMc:DisplayObject in resultObj["rectangleMcArray"])
				{
					displayTreeBuildManger.setMaskMc(reMc);
				}
				//======Push所有的PH
				for each (var phMc:DisplayObject in resultObj["phMcArray"])
				{
					displayTreeBuildManger.setPHMc(phMc);
				}
				//=======Push所有的BitmapData
				for (var bitmapDataKey:String in resultObj["bitmapDataDic"])
				{
					displayTreeBuildManger.pushExtarBitmapDataToTextureDic(resultObj["bitmapDataDic"][bitmapDataKey], bitmapDataKey);
				}

				displayTreeBuildManger.anyliseFile(resultObj["normalSymbolDic"], nodeConfigFile);

				APPLog.log("End anylise file");
			}

			APPLog.log("all finish!");
			NativeApplication.nativeApplication.exit();
		}

		/**
		 *区分开当前Domain下的导出元件类型</br>
		 *
		 * @param _domain
		 * @return obj["rectangleMcArray"]	所有MaskMc
		 * 				  obj["phMcArray"] 所有PlaceHolderMc
		 * 				  obj["normalSymbolDic"] 所有普通Mc
		 * 				  obj["bitmapDataArray"]	所有
		 *
		 */
		private function separateMaskPHAndNormalSymbol(_domain:ApplicationDomain):Object
		{
			var returnObj:Object={};
			returnObj["rectangleMcArray"]=[];
			returnObj["phMcArray"]=[];
			returnObj["normalSymbolDic"]=new Dictionary();
			returnObj["bitmapDataDic"]=new Dictionary();

			var allOutputKeys:Vector.<String>=_domain.getQualifiedDefinitionNames();
			for each (var key:String in allOutputKeys)
			{
				var MCCLASS:Class=_domain.getDefinition(key) as Class;
				var mc:Object=new MCCLASS();

				if (StringUtils.startsWithIgnoreCase(key, "RE_") || StringUtils.startsWithIgnoreCase(key, "MASK_"))
				{
					returnObj["rectangleMcArray"].push(mc);
				}
				else if (StringUtils.startsWithIgnoreCase(key, "PH_"))
				{
					returnObj["phMcArray"].push(mc);
				}
				else if (mc is BitmapData)
				{
					returnObj["bitmapDataDic"][key]=mc;
				}
				else
				{
					returnObj["normalSymbolDic"][key]=mc;
				}
			}
			return returnObj;
		}


	}
}
