package app.anylise
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	import app.debug.APPLog;
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

		/**
		 *将一个Bitmapdata Push到当前的TextureDic里面,因为在FLA文件里面有可能会指定Export一些Img素材
		 * 所以在开始anylise之前先将这些bitmapdata push进去</br>
		 * <b>注意!!! 不要再开始Anylise以后再调用该函数,并且保证传入的key值为uniqueKey</b>
		 */
		public function pushBitmapDataToTextureDic(_bitmapData:BitmapData, _uniqueKey:String):void
		{
			allTextureDic[_uniqueKey]=_bitmapData;
		}

		//=============================================//
		//================= OPTIMIZE ====================//
		//=============================================//

		/**
		 * 对某一个Meta显示树层级结构进行优化</br>
		 * <b>注意!!!目前版本不支持滤镜</b>
		 * <li>如果某一个Sprite节点下仅有一个Child,且这个Child为一个Shape,则删除Sprite节点仅保留Shape节点
		 *
		 * @return  优化后的Meta数据
		 *
		 */
		public function optimize(_meta:CESDisplayObjectMeta):CESDisplayObjectMeta
		{
			return null;
		}

		/**
		 *While-True循环,遍历调用该函数,每次调用优化一次及返回
		 * <li>TRUE		表示当前优化了一次,while循环需要继续
		 * <li>FALSE		表示当前没有做任何优化,while循环可以结束
		 */
		private function doOptimize(_meta:CESDisplayObjectMeta):Boolean
		{
			return false;
		}





		//=============================================//
		//==============      ANYLISE      ====================//
		//=============================================//

		/**
		 *分析一个显示对象,并返回该对象的Meta信息</br>
		 * <b>注意!!此时未返回对应纹理信息</b>如果需要纹理信息,需要调用getAllTextureDic函数
		 */
		public function anylise(_target:DisplayObject):CESDisplayObjectMeta
		{
			if (_target is MovieClip)
			{
				if ((_target as MovieClip).totalFrames == 1)
				{
					return doAnyliseSprite(_target as Sprite);
				}
				else
				{
					return doAnyliseMovieClip(_target as MovieClip);
				}
			}
			else if (_target is Shape)
			{
				return doAnyliseShape(_target as Shape);
			}
			else
			{
				APPLog.err("unknow target type");
				return null;
			}
		}

		private function doAnyliseMovieClip(_target:MovieClip):CESMovieClipMeta
		{
			var mcMeta:CESMovieClipMeta=new CESMovieClipMeta();
			mcMeta.mSubFrameArray=[];

			var totalFrame:int=_target.totalFrames;
			for (var currentFrame:int=totalFrame; currentFrame > 0; currentFrame--)
			{
				_target.gotoAndStop(currentFrame);
				var totalChildNum:int=_target.numChildren;
				for (var index:int=totalChildNum; index < totalChildNum; index++)
				{
					var subChild:DisplayObject=_target.getChildAt(index);
					mcMeta.mSubFrameArray.push(anylise(subChild));
						//TODO::考虑Mapping的问题
				}
			}

			fillMetaBasicInfo(_target, mcMeta);
			return mcMeta;
		}

		private function doAnyliseSprite(_target:Sprite):CESDisplayObjectMeta
		{
			var totalChildNum:int=_target.numChildren;

			var spMeta:CESSpriteMeta=new CESSpriteMeta();
			spMeta.childMetaArray=[];

			for (var index:int=0; index < totalChildNum; index++)
			{
				var subChild:DisplayObject=_target.getChildAt(index);
				spMeta.childMetaArray.push(anylise(subChild));
			}

			fillMetaBasicInfo(_target, spMeta);
			return spMeta;
		}

		private function doAnyliseShape(_target:Shape):CESShapeMeta
		{
			var shapeMeta:CESShapeMeta=new CESShapeMeta();
			fillMetaBasicInfo(_target, shapeMeta);
			return shapeMeta;
		}

		private function fillMetaBasicInfo(_target:DisplayObject, _meta:CESDisplayObjectMeta):void
		{
			var re:Rectangle=_target.getBounds(_target);
			_meta.alpha=_target.alpha;
			_meta.name=_target.name;
			_meta.width=_target.width;
			_meta.height=_target.height;
			_meta.x=_target is Shape ? re.x : _target.x;
			_meta.y=_target is Shape ? re.y : _target.y;
		}

	}
}
