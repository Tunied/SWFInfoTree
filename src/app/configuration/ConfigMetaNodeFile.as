package app.configuration
{
	import flash.system.ApplicationDomain;

	public final class ConfigMetaNodeFile
	{
		public var fileName:String;
		public var inputFile:String;
		public var outputFilePath:String;
		
		/**
		 *读入文件的ApplicationDomain 
		 */		
		public var domain:ApplicationDomain;
		
		public function ConfigMetaNodeFile()
		{
		}
	}
}