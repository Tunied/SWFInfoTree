package app.utils
{
	import flash.display.BitmapData;
	import flash.display.PNGEncoderOptions;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import app.configuration.ConfigMetaNodeFile;

	import copyengine.ui.starling.component.meta.CESFileMeta;
	import copyengine.utils.GeneralUtils;

	public class AppFileUtils
	{
		public function AppFileUtils()
		{
		}

		/**
		 * 导出显示树Meta文件
		 */
		public static function exportFileMeta(_fileMeta:CESFileMeta, _configFileNode:ConfigMetaNodeFile):void
		{
			var serializedObj:Object=GeneralUtils.serializeObject(_fileMeta);
			var fileByteArray:ByteArray=new ByteArray();
			fileByteArray.writeObject(serializedObj);
			writeByteArrayToPath(fileByteArray, _configFileNode.outputFilePath);
		}

		/**
		 *导出Starling可以使用的纹理信息,包括一张和fileName相同的png图及xml文件
		 */
		public static function exportTextureFile(_allTextureDic:Dictionary, _configFileNode:ConfigMetaNodeFile):void
		{
			var textureRectDic:Dictionary=new Dictionary();
			for each (var textureKey:String in _allTextureDic)
			{
				var bitmapData:BitmapData=_allTextureDic[textureKey];
				textureRectDic[textureKey]=new Rectangle(0, 0, bitmapData.width, bitmapData.height);
			}
			doExportTexturePNG(_allTextureDic, textureRectDic, _configFileNode);
			doExportTextureXML(_allTextureDic, textureRectDic, _configFileNode);
		}

		private static function doExportTextureXML(_allTextureDic:Dictionary, _textureRectDic:Dictionary, _configFileNode:ConfigMetaNodeFile):void
		{
			var xml:XML=<TextureAtlas/>;
			var childXml:XML;
			var currentBitmapRect:Rectangle;

			for each (var textureKey:String in _allTextureDic)
			{
				currentBitmapRect=_textureRectDic[textureKey];

				childXml=<SubTexture/>;
				childXml.@name=textureKey;
				childXml.@x=currentBitmapRect.x;
				childXml.@y=currentBitmapRect.y;
				childXml.@width=currentBitmapRect.width;
				childXml.@height=currentBitmapRect.height;
				xml.appendChild(childXml);
			}
			writeStringToPath(xml.toXMLString(), _configFileNode.outputFilePath + "/" + _configFileNode.fileName + ".xml");
		}

		private static function doExportTexturePNG(_allTextureDic:Dictionary, _textureRectDic:Dictionary, _configFileNode:ConfigMetaNodeFile):void
		{
			var textureAtlasRect:Rectangle=TextureUtil.packTextures(0, 2, _textureRectDic);
			var textureAtlasBitmapData:BitmapData=new BitmapData(textureAtlasRect.width, textureAtlasRect.height, true, 0);

			var currentBitmapData:BitmapData;
			var currentBitmapRect:Rectangle;

			var shareRect:Rectangle=new Rectangle();
			var sharePoint:Point=new Point();
			for each (var textureKey:String in _allTextureDic)
			{
				currentBitmapRect=_textureRectDic[textureKey];
				currentBitmapData=_allTextureDic[textureKey];

				shareRect.copyFrom(currentBitmapRect);
				shareRect.x=shareRect.y=0;
				sharePoint.x=currentBitmapRect.x;
				sharePoint.y=currentBitmapRect.y;

				textureAtlasBitmapData.copyPixels(currentBitmapData, shareRect, sharePoint);
			}
			writeImgToPath(textureAtlasBitmapData, _configFileNode.outputFilePath + "/" + _configFileNode.fileName + ".png");
		}


		//================================================//
		//===============   UTILS  WRITE   =====================//
		//================================================//

		private static function writeByteArrayToPath(_data:ByteArray, _path:String):void
		{
			var file:File=new File(_path);
			var fileStream:FileStream=new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeBytes(_data);
			fileStream.close();
		}

		private static function writeImgToPath(_bitmapData:BitmapData, _path:String):void
		{
			var bytes:ByteArray=_bitmapData.encode(new Rectangle(0, 0, _bitmapData.width, _bitmapData.height), new PNGEncoderOptions());
			writeByteArrayToPath(bytes, _path);
		}

		private static function writeStringToPath(_str:String, _path:String):void
		{
			var bytes:ByteArray=new ByteArray();
			bytes.writeUTF(_str);
			writeByteArrayToPath(bytes, _path);
		}

	}
}
