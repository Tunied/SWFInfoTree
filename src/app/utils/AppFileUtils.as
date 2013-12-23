package app.utils
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class AppFileUtils
	{
		public function AppFileUtils()
		{
		}
		
		public function writeFileToPath(_data:ByteArray,_path:String):void
		{
			var file:File=new File(_path);
			var fileStream:FileStream=new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeBytes(_data);
			fileStream.close();
		}
		
	}
}