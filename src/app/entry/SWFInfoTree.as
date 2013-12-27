package app.entry
{
	import flash.desktop.NativeApplication;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	
	import app.configuration.ConfigMeta;
	import app.configuration.ConfigMetaNodeFile;
	import app.debug.APPLog;
	import app.displayTree.DisplayTreeAnyliser;
	import app.displayTree.DisplayTreeOptimizer;
	import app.utils.AppFileUtils;
	
	import copyengine.ui.starling.component.meta.CESDisplayObjectMeta;
	import copyengine.ui.starling.component.meta.CESFileMeta;
	import copyengine.ui.starling.component.meta.CESMetaFacade;
	
	import org.as3commons.lang.StringUtils;

	public class SWFInfoTree extends Sprite
	{
		private var displayTreeAnyliser:DisplayTreeAnyliser;
		private var displayTreeOptimizer:DisplayTreeOptimizer;

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
			//初始化Optimizer
			displayTreeOptimizer=new DisplayTreeOptimizer();


			APPLog.log("Tool start...");
			var allFileNodeMetaVector:Vector.<ConfigMetaNodeFile>=ConfigMeta.instance.allNodeFileVector;
			for each (var nodeConfigFile:ConfigMetaNodeFile in allFileNodeMetaVector)
			{
				APPLog.log("Start anylise file : " + nodeConfigFile.inputFile);
				var resultObj:Object=separateMaskPHAndNormalSymbol(nodeConfigFile.domain);

				//初始化Anyliser 每个文件导出一份纹理
				displayTreeAnyliser=new DisplayTreeAnyliser();
				displayTreeAnyliser.initialize();
				displayTreeAnyliser.setTextrueFileName(nodeConfigFile.fileName);

				//=====Push所有的Mask
				for each (var maskMc:DisplayObject in resultObj["maskMcArray"])
				{
					displayTreeAnyliser.setMaskMc(maskMc);
				}
				//======Push所有的PH
				for each (var phMc:DisplayObject in resultObj["phMcArray"])
				{
					displayTreeAnyliser.setPHMc(maskMc);
				}
				//=======Push所有的BitmapData
				for each (var bitmapDataKey:String in resultObj["bitmapDataDic"])
				{
					displayTreeAnyliser.pushBitmapDataToTextureDic(resultObj["bitmapDataDic"][bitmapDataKey], bitmapDataKey);
				}

				//=======分析每个Mc
				var fileMeta:CESFileMeta=new CESFileMeta();
				fileMeta.allSubSymbolDic={};
				for (var normalMcKey:String in resultObj["normalSymbolDic"])
				{
					fileMeta.allSubSymbolDic[normalMcKey]=displayTreeAnyliser.anylise(resultObj["normalSymbolDic"][normalMcKey]);
				}
				//========优化显示树节点
				fileMeta=displayTreeOptimizer.optimize(fileMeta);

				//=======序列化并导出File文件
				AppFileUtils.exportFileMeta(fileMeta, nodeConfigFile);
				//=======导出纹理信息
				AppFileUtils.exportTextureFile(displayTreeAnyliser.getAllTextureDic(), nodeConfigFile);

				APPLog.log("End anylise file");
			}

			APPLog.log("all finish!");
			NativeApplication.nativeApplication.exit();
		}

		/**
		 *区分开当前Domain下的导出元件类型</br>
		 *
		 * @param _domain
		 * @return obj["maskMcArray"]	所有MaskMc
		 * 				  obj["phMcArray"] 所有PlaceHolderMc
		 * 				  obj["normalSymbolDic"] 所有普通Mc
		 * 				  obj["bitmapDataArray"]	所有
		 *
		 */
		private function separateMaskPHAndNormalSymbol(_domain:ApplicationDomain):Object
		{
			var returnObj:Object={};
			returnObj["maskMcArray"]=[];
			returnObj["phMcArray"]=[];
			returnObj["normalSymbolDic"]=new Dictionary();
			returnObj["bitmapDataDic"]=new Dictionary();

			var allOutputKeys:Vector.<String>=_domain.getQualifiedDefinitionNames();
			for each (var key:String in allOutputKeys)
			{
				var MCCLASS:Class=_domain.getDefinition(key) as Class;
				var mc:Object=new MCCLASS();

				if (StringUtils.startsWithIgnoreCase(key, "mask_"))
				{
					returnObj["maskMcArray"].push(mc);
				}
				else if (StringUtils.startsWithIgnoreCase(key, "ph_"))
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
