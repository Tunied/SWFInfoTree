package app.utils
{
	import flash.utils.Dictionary;

	public final class DictionaryUtils
	{
		public function DictionaryUtils()
		{
		}

		public static function isEmpty(_dic:Dictionary):Boolean
		{
			if (_dic)
			{
				for (var key:* in _dic)
				{
					return false;
				}
			}
			return true;
		}
	}
}
