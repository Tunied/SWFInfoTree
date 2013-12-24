package app.configuration
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	import app.debug.APPLog;

	import copyengine.utils.GeneralUtils;

	public final class ConfigMeta
	{
		private static var _instance:ConfigMeta;

		public static function get instance():ConfigMeta
		{
			if (_instance == null)
			{
				_instance=new ConfigMeta();
			}
			return _instance;
		}


		/**
		 *所有的FileNode节点
		 */
		public var allNodeFileVector:Vector.<ConfigMetaNodeFile>;

		private var xmlFileLoader:URLLoader;
		private var swfLoader:Loader;

		private var currentNodeFileMeta:ConfigMetaNodeFile;

		private var initFinishCallback:Function;

		public function ConfigMeta()
		{
		}

		public function initialize(_finishCallback:Function):void
		{
			initFinishCallback=_finishCallback;

			xmlFileLoader=new URLLoader();
			xmlFileLoader.load(new URLRequest("Config.xml"));
			xmlFileLoader.dataFormat=URLLoaderDataFormat.BINARY;
			GeneralUtils.addTargetEventListener(xmlFileLoader, Event.COMPLETE, onConfigFileLoaded);
			GeneralUtils.addTargetEventListener(xmlFileLoader, IOErrorEvent.IO_ERROR, loadConfigFileOnError);
		}

		//=====================================//
		//===========LOAD CONFIG FILE=============//
		//=====================================//

		private function onConfigFileLoaded(e:Event):void
		{
			allNodeFileVector=new Vector.<ConfigMetaNodeFile>();

			var byteArray:ByteArray=xmlFileLoader.data as ByteArray;
			var xmlFile:XML=new XML(byteArray);

			for each (var fileNodeElement:XML in xmlFile.file)
			{
				var nodeFileMeta:ConfigMetaNodeFile=new ConfigMetaNodeFile();
				nodeFileMeta.inputFile=fileNodeElement.inputFile;
				nodeFileMeta.outputFilePath=fileNodeElement.outputFilePath;
				nodeFileMeta.fileName=fileNodeElement.fileName;
				allNodeFileVector.push(nodeFileMeta);
			}

			tryToLoadSWFFile();
		}


		//=====================================//
		//============LOAD  SWF FILE==============//
		//=====================================//
		private function tryToLoadSWFFile():void
		{
			var isAllSWFFileLoaded:Boolean=true;
			for each (var nodeFile:ConfigMetaNodeFile in allNodeFileVector)
			{
				if (nodeFile.domain == null)
				{
					isAllSWFFileLoaded=false;
					currentNodeFileMeta=nodeFile;
					swfLoader=new Loader();
					swfLoader.load(new URLRequest(nodeFile.inputFile));
					GeneralUtils.addTargetEventListener(swfLoader.contentLoaderInfo, Event.COMPLETE, onSWFFileLoaded);
					GeneralUtils.addTargetEventListener(swfLoader.contentLoaderInfo, IOErrorEvent.IO_ERROR, loadSWFFileOnError);
					//每次只Load一个swf文件
					break;
				}
			}
			//所有swf文件都加载完成,完成初始化步骤
			isAllSWFFileLoaded && initFinishCallback();
		}

		private function onSWFFileLoaded(e:Event):void
		{
			var loaderInfo:LoaderInfo=e.currentTarget as LoaderInfo;
			currentNodeFileMeta.domain=loaderInfo.applicationDomain;

			//当前swf加载完成,尝试加载下一个
			tryToLoadSWFFile();
		}



		private function loadConfigFileOnError(e:Event):void  { APPLog.err("can not load Config.xml file"); }

		private function loadSWFFileOnError(e:Event):void  { APPLog.err("can not load swf file"); }



	}
}
