package app.displayTree
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;

	import app.configuration.ConfigMetaNodeFile;
	import app.debug.APPLog;
	import app.displayTree.anyliser.DisplayTreeAnyliser;
	import app.displayTree.fixer.DisplayTreeShapeFixer;
	import app.displayTree.optimizer.DisplayTreeOptimizer;
	import app.utils.AppFileUtils;
	import app.utils.DictionaryUtils;

	import copyengine.ui.starling.component.meta.CESFileMeta;

	public final class DisplayTreeBuildManger
	{
		private var anylister:DisplayTreeAnyliser;
		private var optimizer:DisplayTreeOptimizer;
		private var shapeFixer:DisplayTreeShapeFixer;

		private var extarImgDic:Dictionary;

		public function DisplayTreeBuildManger()
		{
		}

		public function initialize():void
		{
			anylister=new DisplayTreeAnyliser();
			optimizer=new DisplayTreeOptimizer();
			shapeFixer=new DisplayTreeShapeFixer();

			extarImgDic=new Dictionary();
		}

		public function setMaskMc(_maskMc:DisplayObject):void  { anylister.setRectangleMc(_maskMc); }

		public function setPHMc(_phMc:DisplayObject):void  { anylister.setPHMc(_phMc); }

		public function pushExtarBitmapDataToTextureDic(_bitmapData:BitmapData, _uniqueKey:String):void
		{
			extarImgDic[_uniqueKey]=_bitmapData;
		}

		public function anyliseFile(_allSymbolMcDic:Dictionary, _configNodeFile:ConfigMetaNodeFile):void
		{
			if (_configNodeFile.isShareTexture)
			{
				doAnyliseFileWithShareTexture(_allSymbolMcDic, _configNodeFile);
			}
			else
			{
				doAnyliseFileWithoutShareTexture(_allSymbolMcDic, _configNodeFile);
			}
			//=======导出额外的纹理信息
			if (!DictionaryUtils.isEmpty(extarImgDic))
			{
				AppFileUtils.exportTextureFile(extarImgDic, _configNodeFile.outputFilePath, "Extra_" + _configNodeFile.fileName);
			}
		}


		private function doAnyliseFileWithoutShareTexture(_allSymbolMcDic:Dictionary, _configNodeFile:ConfigMetaNodeFile):void
		{
			//=======分析每个Mc
			var fileMeta:CESFileMeta=new CESFileMeta();
			fileMeta.allSubSymbolDic={};
			for (var normalMcKey:String in _allSymbolMcDic)
			{
				APPLog.log("start anylise mc : " + normalMcKey);
				//======写入导出纹理名称(非Share的Texture为文件名_导出类名)
				anylister.setTextrueFileName(_configNodeFile.fileName + "_" + normalMcKey);

				fileMeta.allSubSymbolDic[normalMcKey]=anylister.anylise(_allSymbolMcDic[normalMcKey]);

				//=====修正所有Shap信息
				shapeFixer.fixShapeMetaProperty(anylister.getAllShapeMetaWarpVector());

				//========优化显示树节点
				fileMeta=optimizer.optimize(fileMeta);

				//=======序列化并导出File文件
				AppFileUtils.exportFileMeta(fileMeta, _configNodeFile.outputFilePath, anylister.getTextrueFileName());
				//=======导出纹理信息
				AppFileUtils.exportTextureFile(anylister.getAllTextureDic(), _configNodeFile.outputFilePath, anylister.getTextrueFileName());

				//清空当前Push进去的纹理信息
				anylister.cleanTextureDic();
			}
		}

		private function doAnyliseFileWithShareTexture(_allSymbolMcDic:Dictionary, _configNodeFile:ConfigMetaNodeFile):void
		{
			//======写入导出纹理名称
			anylister.setTextrueFileName(_configNodeFile.fileName);

			//=======分析每个Mc
			var fileMeta:CESFileMeta=new CESFileMeta();
			fileMeta.allSubSymbolDic={};
			for (var normalMcKey:String in _allSymbolMcDic)
			{
				APPLog.log("start anylise mc : " + normalMcKey);
				fileMeta.allSubSymbolDic[normalMcKey]=anylister.anylise(_allSymbolMcDic[normalMcKey]);
			}

			//=====修正所有Shap信息
			shapeFixer.fixShapeMetaProperty(anylister.getAllShapeMetaWarpVector());

			//========优化显示树节点
			fileMeta=optimizer.optimize(fileMeta);

			//=======序列化并导出File文件
			AppFileUtils.exportFileMeta(fileMeta, _configNodeFile.outputFilePath, anylister.getTextrueFileName());
			//=======导出纹理信息
			AppFileUtils.exportTextureFile(anylister.getAllTextureDic(), _configNodeFile.outputFilePath, anylister.getTextrueFileName());
		}


	}
}
