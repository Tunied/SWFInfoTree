package app.displayTree
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
	import copyengine.ui.starling.component.meta.CESTextureMeta;
	import copyengine.utils.UUIDFactory;

	public final class DisplayTreeAnyliser
	{
		private var allMaskBitmapDataVector:Vector.<BitmapData>;
		private var allPHBitmapDataVector:Vector.<BitmapData>;
		private var allTextureDic:Dictionary;
		private var textureFileName:String;

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
		 * 设置导出纹理信息的文件名称,用于初始化CESTextureMeta数据
		 */
		public function setTextrueFileName(_name:String):void  { textureFileName=_name; }

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

			//MovieClip有一个Bug,只有反向(及从最后一帧开始往前遍历才会正常Cache),如果从
			//第一帧往后Cache则如果Child为一个Shape仅能取到第一帧的Child
			for (var currentFrame:int=totalFrame; currentFrame > 0; currentFrame--)
			{
				_target.gotoAndStop(currentFrame);
				var rootSpMeta:CESSpriteMeta=getEmptySpriteMeta();
				mcMeta.mSubFrameArray[currentFrame]=rootSpMeta;

				//===遍历当前帧下每个Child
				var totalChildNum:int=_target.numChildren;
				for (var index:int=0; index < totalChildNum; index++)
				{
					var subChild:DisplayObject=_target.getChildAt(index);
					rootSpMeta.childMetaArray.push(anylise(subChild));
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
			shapeMeta.textureMeta=getTargetTextureInfo(_target);
			return shapeMeta;
		}

		private function fillMetaBasicInfo(_target:DisplayObject, _meta:CESDisplayObjectMeta):void
		{
			_meta.alpha=_target.alpha;
			_meta.name=_target.name;
			_meta.width=_target.width;
			_meta.height=_target.height;

			if (_target is Shape)
			{
				var warpSp:Sprite=new Sprite();
				warpSp.addChild(_target);
				var re:Rectangle=warpSp.getBounds(warpSp);
				_meta.x=re.x;
				_meta.y=re.y;
			}
			else
			{
				_meta.x=_target.x;
				_meta.y=_target.y;
			}
		}

		private function getTargetTextureInfo(_target:DisplayObject):CESTextureMeta
		{
			var textrueMeta:CESTextureMeta=new CESTextureMeta();
			textrueMeta.textrueFileName=textureFileName;

			//====尝试从已有纹理中找出一样的纹理
			var newImg:BitmapData=ImageUtils.cacheDisplayObjectToBitmapData(_target);
			for (var key:String in allTextureDic)
			{
				var oldImg:BitmapData=allTextureDic[key];
				if (oldImg.compare(newImg) == 0)
				{
					textrueMeta.textureKey=key;
				}
			}

			//====如果没有则产生新的Texture
			if (textrueMeta.textureKey == null)
			{
				var newKey:String=UUIDFactory.instance.generateUUID();
				allTextureDic[newKey]=newImg;
				textrueMeta.textureKey=newKey;
			}
			return textrueMeta;
		}

		/**
		 *取得一个空的SpriteMeta的Container. 用于CESMovieClipMeta里面
		 * 其每帧节点均用一个空的sp节点进行warp
		 */
		private function getEmptySpriteMeta():CESSpriteMeta
		{
			var rootSpMeta:CESSpriteMeta=new CESSpriteMeta();
			rootSpMeta.alpha=1;
			rootSpMeta.x=rootSpMeta.y=rootSpMeta.width=rootSpMeta.height=0;
			rootSpMeta.childMetaArray=[];
			return rootSpMeta;
		}

	}
}
