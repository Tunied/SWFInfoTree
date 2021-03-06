package app.utils
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	import app.debug.APPLog;

	public final class ImageUtils
	{
		public function ImageUtils()
		{
		}

		private static var emptyBitmapData:BitmapData=new BitmapData(1, 1, true, 0);

		public static function cacheDisplayObjectToBitmapData(_target:DisplayObject, scale:Number=1):BitmapData
		{
			var targetNormalScaleX:Number=_target.scaleX;
			var targetNormalScaleY:Number=_target.scaleY;

			emptyBitmapData.dispose();
			_target.scaleX=_target.scaleY=scale;
			var bounds:Rectangle=_target.getBounds(_target);
			var bitmapData:BitmapData;

			//need to convert the number to int , beacuse use number to cache the object will shake
			var offsetX:int=Math.ceil(bounds.x * _target.scaleX);
			var offsetY:int=Math.ceil(bounds.y * _target.scaleY);

			if (bounds.width == 0 || bounds.height == 0)
			{
				APPLog.err("fond one empry bitmap , the symbol in FLA file maybe wrong, please check out!");
				bitmapData=emptyBitmapData;
			}
			else
			{
				bitmapData=new BitmapData(Math.ceil(_target.width), Math.ceil(_target.height), true, 0xFFFFFF);
				bitmapData.draw(_target, new Matrix(_target.scaleX, 0, 0, _target.scaleY, -offsetX, -offsetY));
			}

			_target.scaleX=targetNormalScaleX;
			_target.scaleY=targetNormalScaleY;
			//var bitmap:Bitmap = new Bitmap(bitmapData);
			//bitmap.x = offsetX;
			//bitmap.y = offsetY;
			return bitmapData;
		}
	}
}
