package app.displayTree
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import app.debug.APPLog;
	import app.utils.ImageUtils;
	
	import copyengine.ui.starling.component.meta.CESDisplayObjectMeta;
	import copyengine.ui.starling.component.meta.CESMaskMeta;
	import copyengine.ui.starling.component.meta.CESMovieClipMeta;
	import copyengine.ui.starling.component.meta.CESShapeMeta;
	import copyengine.ui.starling.component.meta.CESSpriteMeta;
	import copyengine.ui.starling.component.meta.CESTextFieldMeta;
	import copyengine.ui.starling.component.meta.CESTextureMeta;
	import copyengine.utils.UUIDFactory;

	public final class DisplayTreeAnyliser
	{
		private var allMaskBitmapDataVector:Vector.<BitmapData>;
		private var allPHBitmapDataVector:Vector.<BitmapData>;
		private var allShapeMetaWarpVector:Vector.<ShapeMetaWarp>;
		private var allTextureDic:Dictionary;
		private var textureFileName:String;

		public function DisplayTreeAnyliser()
		{
		}

		public function initialize():void
		{
			allMaskBitmapDataVector=new Vector.<BitmapData>();
			allPHBitmapDataVector=new Vector.<BitmapData>();
			allShapeMetaWarpVector=new Vector.<ShapeMetaWarp>();
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
		 *返回所有需要调整信息的ShapeWarp
		 *
		 */
		public function getAllShapeMetaWarpVector():Vector.<ShapeMetaWarp>  { return allShapeMetaWarpVector; }

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
			else if (_target is TextField)
			{
				//TODO::暂时不解析
				return new CESTextFieldMeta();
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
			//帧标签第0帧无意义
			mcMeta.mSubFrameArray[0]=new CESDisplayObjectMeta();
			mcMeta.mKeyAndIndexMapDic={}

			var totalFrame:int=_target.totalFrames;

			//MovieClip有一个Bug,只有反向(及从最后一帧开始往前遍历才会正常Cache),如果从
			//第一帧往后Cache则如果Child为一个Shape仅能取到第一帧的Child
			for (var currentFrame:int=totalFrame; currentFrame > 0; currentFrame--)
			{
				_target.gotoAndStop(currentFrame);
				var rootSpMeta:CESSpriteMeta=getEmptySpriteMeta();
				mcMeta.mSubFrameArray[currentFrame]=rootSpMeta;
				//===Push帧标签
				_target.currentFrameLabel != null ? mcMeta.mKeyAndIndexMapDic[_target.currentFrameLabel]=currentFrame : null;

				//===遍历当前帧下每个Child
				var totalChildNum:int=_target.numChildren;
				for (var index:int=0; index < totalChildNum; index++)
				{
					var subChild:DisplayObject=_target.getChildAt(index);
					rootSpMeta.childMetaArray.push(anylise(subChild));
				}

			}
			fillMetaBasicInfo(_target, mcMeta);
			return mcMeta;
		}

		private function doAnyliseSprite(_target:Sprite):CESDisplayObjectMeta
		{
			if (isMaskOrPH(_target))
			{
				var maskMeta:CESMaskMeta=new CESMaskMeta();
				maskMeta.name=_target.name;
				maskMeta.x=_target.x;
				maskMeta.y=_target.y;
				maskMeta.width=_target.width;
				maskMeta.height=_target.height;
				return maskMeta;
			}
			else
			{
				var totalChildNum:int=_target.numChildren;

				var spMeta:CESSpriteMeta=new CESSpriteMeta();
				spMeta.childMetaArray=[];

				//临时缓存所有的子节点,因为在递归遍历时候遇到Shape需要先将Shape
				//add到另外一个空的sprite上面才能正确的得到相应信息,这样话会打乱显示树结构
				//无法通过_target.getChildAt(index) 正确取得节点
				var allChildMcVector:Vector.<DisplayObject>=new Vector.<DisplayObject>();
				for (var index:int=0; index < totalChildNum; index++)
				{
					allChildMcVector.push(_target.getChildAt(index));
				}
				for each (var childMc:DisplayObject in allChildMcVector)
				{
					spMeta.childMetaArray.push(anylise(childMc));
				}

				fillMetaBasicInfo(_target, spMeta);
				return spMeta;
			}
		}

		private function doAnyliseShape(_target:Shape):CESDisplayObjectMeta
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
			_meta.scaleX=_target.scaleX;
			_meta.scaleY=_target.scaleY;

			var re:Rectangle;
			re=_target.getBounds(_target);
			_meta.x=_target.x;
			_meta.y=_target.y;
			_meta.pivotX=re.x;
			_meta.pivotY=re.y;

			if (_target is Shape)
			{
				var shapeMetaWarp:ShapeMetaWarp=new ShapeMetaWarp();
				shapeMetaWarp.shapeMeta=_meta as CESShapeMeta;
				shapeMetaWarp.sourceTarget=_target as Shape;
				allShapeMetaWarpVector.push(shapeMetaWarp);
			}

//			if (_target is Shape)
//			{
//				//对于Shape存在一个Bug:
//				//如果在FLA库中某一个元件A是通过 "直接复制" 的 元件B (FLA库中操作) 则元件A的坐标信息是错误的
//				//可以理解为swf底层针对于这种 "直接复制" 做了某种优化,使得元件A的坐标信息其实反映的是把 元件B进行某种变化能够得到
//				//所以这时候需要将shap重新添加到一个container里面 才可以
//				//注意!!由于改变了显示树结构,所以在递归调用时候需要先去的所有元件在for循环
//				//@see doAnyliseSprite()
//
//				var targetParent:DisplayObjectContainer=_target.parent;
//				var targetChildIndex:int=_target.parent.getChildIndex(_target);
//
//				var warpSp:Sprite=new Sprite();
//				warpSp.addChild(_target);
//				re=warpSp.getBounds(warpSp);
//				_meta.x=re.x;
//				_meta.y=re.y;
//				_meta.pivotX=0;
//				_meta.pivotY=0;
//
//				targetParent.addChildAt(_target, targetChildIndex);
//			}
//			else
//			{
//				re=_target.getBounds(_target);
//				_meta.x=_target.x;
//				_meta.y=_target.y;
//				_meta.pivotX=re.x;
//				_meta.pivotY=re.y;
//			}
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

		private function isMaskOrPH(_mc:DisplayObject):Boolean
		{
			var img:BitmapData=ImageUtils.cacheDisplayObjectToBitmapData(_mc);
			for each (var maskData:BitmapData in allMaskBitmapDataVector)
			{
				if (maskData.compare(img) == 0)
				{
					return true;
				}
			}

			for each (var phData:BitmapData in allPHBitmapDataVector)
			{
				if (phData.compare(img) == 0)
				{
					return true;
				}
			}

			return false;
		}

	}
}
