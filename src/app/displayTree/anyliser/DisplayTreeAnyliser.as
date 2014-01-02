package app.displayTree.anyliser
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.utils.Dictionary;

	import app.debug.APPLog;
	import app.displayTree.fixer.ShapeMetaWarp;
	import app.utils.ImageUtils;

	import copyengine.ui.starling.component.meta.CESDisplayObjectMeta;
	import copyengine.ui.starling.component.meta.CESMovieClipMeta;
	import copyengine.ui.starling.component.meta.CESPlaceHolderMeta;
	import copyengine.ui.starling.component.meta.CESRectangleMeta;
	import copyengine.ui.starling.component.meta.CESShapeMeta;
	import copyengine.ui.starling.component.meta.CESSpriteMeta;
	import copyengine.ui.starling.component.meta.CESTextFieldMeta;

	public final class DisplayTreeAnyliser
	{
		private var allRectangleBitmapDataVector:Vector.<BitmapData>;
		private var allPHBitmapDataVector:Vector.<BitmapData>;
		private var allShapeMetaWarpVector:Vector.<ShapeMetaWarp>;
		private var allTextureDic:Dictionary;
		private var textureFileName:String;

		private var support:DisplayTreeAnyliserSupport;

		public function DisplayTreeAnyliser()
		{
			allRectangleBitmapDataVector=new Vector.<BitmapData>();
			allPHBitmapDataVector=new Vector.<BitmapData>();
			allShapeMetaWarpVector=new Vector.<ShapeMetaWarp>();
			allTextureDic=new Dictionary();

			support=new DisplayTreeAnyliserSupport(allRectangleBitmapDataVector, allPHBitmapDataVector, allShapeMetaWarpVector, allTextureDic);
		}

		/**
		 * 设置导出纹理信息的文件名称,用于初始化CESTextureMeta数据
		 */
		public function setTextrueFileName(_name:String):void  { textureFileName=_name; support.setTextrueFileName(_name); }

		public function getTextrueFileName():String  { return textureFileName; }

		/**
		 *在FLA文件中,如果一个导出元件是以 "mask" or "MASK" 开头,则认为该元件为Mask导出类,在遍历显示树期间,
		 * 如果认定某一个元件为mask,则仅仅读取其相关信息,不再push到显示列表中进行还原
		 */
		public function setRectangleMc(_mc:DisplayObject):void  { allRectangleBitmapDataVector.push(ImageUtils.cacheDisplayObjectToBitmapData(_mc)); }

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
		public function cleanTextureDic():void  { allTextureDic=new Dictionary(); support.setTextureDic(allTextureDic); }

		/**
		 *返回所有需要调整信息的ShapeWarp
		 *
		 */
		public function getAllShapeMetaWarpVector():Vector.<ShapeMetaWarp>  { return allShapeMetaWarpVector; }

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
				return doAnyliseTextfield(_target as TextField);
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

				var rootSpMeta:CESSpriteMeta=support.getEmptySpriteMeta();
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
			support.fillMetaBasicInfo(_target, mcMeta);
			return mcMeta;
		}

		private function doAnyliseSprite(_target:Sprite):CESDisplayObjectMeta
		{
			if (support.isRectangleHolder(_target))
			{
				var reMeta:CESRectangleMeta=new CESRectangleMeta();
				support.fillRectangleOrPhInfo(_target, reMeta);
				return reMeta;
			}
			else if (support.isPlaceHolder(_target))
			{
				var phMeta:CESPlaceHolderMeta=new CESPlaceHolderMeta();
				support.fillRectangleOrPhInfo(_target, phMeta);
				return phMeta;
			}
			else
			{
				var spMeta:CESSpriteMeta=new CESSpriteMeta();
				spMeta.childMetaArray=[];

				var totalChildNum:int=_target.numChildren;
				for (var index:int=0; index < totalChildNum; index++)
				{
					spMeta.childMetaArray.push(anylise(_target.getChildAt(index)));
				}

				support.fillMetaBasicInfo(_target, spMeta);
				return spMeta;
			}
		}

		private function doAnyliseShape(_target:Shape):CESDisplayObjectMeta
		{
			var shapeMeta:CESShapeMeta=new CESShapeMeta();
			support.fillMetaBasicInfo(_target, shapeMeta);
			shapeMeta.textureMeta=support.getTargetTextureInfo(_target);
			return shapeMeta;
		}

		private function doAnyliseTextfield(_target:TextField):CESDisplayObjectMeta
		{
			var textFieldMeta:CESTextFieldMeta=new CESTextFieldMeta();
			support.fillTextfieldInfo(_target, textFieldMeta);
			return textFieldMeta;
		}

	}
}
