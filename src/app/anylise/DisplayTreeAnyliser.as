package app.anylise
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.utils.Dictionary;

	import app.utils.ImageUtils;

	import copyengine.ui.starling.component.meta.CESDisplayObjectMeta;
	import copyengine.ui.starling.component.meta.CESMovieClipMeta;
	import copyengine.ui.starling.component.meta.CESShapeMeta;
	import copyengine.ui.starling.component.meta.CESSpriteMeta;

	public final class DisplayTreeAnyliser
	{
		private var allMaskBitmapDataVector:Vector.<BitmapData>;
		private var allPHBitmapDataVector:Vector.<BitmapData>;
		private var allTextureDic:Dictionary;

		public function DisplayTreeAnyliser()
		{
		}

		public function initialize():void
		{
			allMaskBitmapDataVector=new Vector.<BitmapData>();
			allPHBitmapDataVector=new Vector.<BitmapData>();
			allTextureDic=new Dictionary();
		}

		/**
		 *在FLA文件中,如果一个导出元件是以 "mask" or "MASK" 开头,则认为该元件为Mask导出类,在遍历显示树期间,
		 * 如果认定某一个元件为mask,则仅仅读取其相关信息,不再push到显示列表中进行还原
		 */
		public function setMaskMc(_mc:DisplayObject):void  { allMaskBitmapDataVector.push(ImageUtils.cacheDisplayObjectToBitmapData(_mc)); }

		/**
		 *在FLA文件中,如果一个导出元件是以 "ph" or "PH" 开头,则认为该元件为PlaceHolder导出类,在遍历显示树期间,
		 * 如果认定某一个元件为PlaceHolder,则仅仅读取其相关信息,不再push到显示列表中进行还原
		 */
		public function setPHMc(_mc:DisplayObject):void  { allPHBitmapDataVector.push(ImageUtils.cacheDisplayObjectToBitmapData(_mc)); }

		/**
		 * 返回当前存储在Anyliser里面的所有纹理信息
		 */
		public function getAllTextureDic():Dictionary  { return allTextureDic; }

		/**
		 * 清除当前在Anyliser里面存储的所有纹理信息
		 */
		public function cleanTextureDic():void  { allTextureDic=new Dictionary(); }

		//=============================================//
		//==============      ANYLISE      ====================//
		//=============================================//

		/**
		 *分析一个显示对象,并返回该对象的Meta信息</br>
		 * <b>注意!!此时未返回对应纹理信息</b>如果需要纹理信息,需要调用getAllTextureDic函数
		 */
		public function anylise(_target:DisplayObject):CESDisplayObjectMeta
		{
			return null;
		}

		private function doAnyliseMovieClip(_target:MovieClip):CESMovieClipMeta
		{
			return null;
		}

		private function doAnyliseSprite(_target:Sprite):CESSpriteMeta
		{
			return null;
		}

		private function doAnyliseShape(_target:Shape):CESShapeMeta
		{
			return null;
		}

	}
}
