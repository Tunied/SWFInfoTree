package app.displayTree
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;

	import app.configuration.ConfigMetaNodeFile;
	import app.utils.AppFileUtils;

	import copyengine.ui.starling.component.meta.CESFileMeta;
	import app.displayTree.anyliser.DisplayTreeAnyliser;
	import app.displayTree.optimizer.DisplayTreeOptimizer;
	import app.displayTree.fixer.DisplayTreeShapeFixer;

	public final class DisplayTreeBuildManger
	{
		private var anylister:DisplayTreeAnyliser;
		private var optimizer:DisplayTreeOptimizer;
		private var shapeFixer:DisplayTreeShapeFixer;

		public function DisplayTreeBuildManger()
		{
		}

		public function initialize():void
		{
			anylister=new DisplayTreeAnyliser();
			optimizer=new DisplayTreeOptimizer();
			shapeFixer=new DisplayTreeShapeFixer();
		}

		public function setMaskMc(_maskMc:DisplayObject):void  { anylister.setMaskMc(_maskMc); }

		public function setPHMc(_phMc:DisplayObject):void  { anylister.setPHMc(_phMc); }

		public function pushBitmapDataToTextureDic(_bitmapData:BitmapData, _uniqueKey:String):void  { anylister.pushBitmapDataToTextureDic(_bitmapData, _uniqueKey); }

		public function anyliseFile(_allSymbolMcDic:Dictionary, _configNodeFile:ConfigMetaNodeFile):void
		{
			//======写入导出纹理名称
			anylister.setTextrueFileName(_configNodeFile.fileName);

			//=======分析每个Mc
			var fileMeta:CESFileMeta=new CESFileMeta();
			fileMeta.allSubSymbolDic={};
			for (var normalMcKey:String in _allSymbolMcDic)
			{
				fileMeta.allSubSymbolDic[normalMcKey]=anylister.anylise(_allSymbolMcDic[normalMcKey]);
			}

			//=====修正所有Shap信息
			shapeFixer.fixShapeMetaProperty(anylister.getAllShapeMetaWarpVector());

			//========优化显示树节点
			fileMeta=optimizer.optimize(fileMeta);

			//=======序列化并导出File文件
			AppFileUtils.exportFileMeta(fileMeta, _configNodeFile);
			//=======导出纹理信息
			AppFileUtils.exportTextureFile(anylister.getAllTextureDic(), _configNodeFile);
		}

	}
}
