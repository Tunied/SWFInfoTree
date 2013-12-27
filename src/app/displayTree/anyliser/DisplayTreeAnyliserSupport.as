package app.displayTree.anyliser
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	import app.displayTree.fixer.ShapeMetaWarp;
	import app.utils.ImageUtils;

	import copyengine.ui.starling.component.meta.CESDisplayObjectMeta;
	import copyengine.ui.starling.component.meta.CESMaskMeta;
	import copyengine.ui.starling.component.meta.CESShapeMeta;
	import copyengine.ui.starling.component.meta.CESSpriteMeta;
	import copyengine.ui.starling.component.meta.CESTextureMeta;
	import copyengine.utils.UUIDFactory;

	/**
	 * 辅助DisplayTreeAnyliser
	 * 封装一些和递归遍历无关的基础方法
	 */
	public final class DisplayTreeAnyliserSupport
	{
		private var allMaskBitmapDataVector:Vector.<BitmapData>;
		private var allPHBitmapDataVector:Vector.<BitmapData>;
		private var allShapeMetaWarpVector:Vector.<ShapeMetaWarp>;
		private var allTextureDic:Dictionary;
		private var textureFileName:String;

		public function DisplayTreeAnyliserSupport(_allMaskBitmapDataVector:Vector.<BitmapData>,
												   _allPHBitmapDataVector:Vector.<BitmapData>,
												   _allShapeMetaWarpVector:Vector.<ShapeMetaWarp>,
												   _allTextureDic:Dictionary)
		{
			allMaskBitmapDataVector=_allMaskBitmapDataVector;
			allPHBitmapDataVector=_allPHBitmapDataVector;
			allShapeMetaWarpVector=_allShapeMetaWarpVector;
			allTextureDic=_allTextureDic;
		}

		/**
		 * 设置导出纹理信息的文件名称,用于初始化CESTextureMeta数据
		 */
		public function setTextrueFileName(_name:String):void  { textureFileName=_name; }

		public function fillMetaBasicInfo(_target:DisplayObject, _meta:CESDisplayObjectMeta):void
		{
			var re:Rectangle=_target.getBounds(_target);
			_meta.alpha=_target.alpha;
			_meta.name=_target.name;
			_meta.width=_target.width;
			_meta.height=_target.height;
			_meta.scaleX=_target.scaleX;
			_meta.scaleY=_target.scaleY;
			_meta.x=_target.x;
			_meta.y=_target.y;
			_meta.pivotX=re.x;
			_meta.pivotY=re.y;

			//对于Shape存在一个Bug:
			//如果在FLA库中某一个元件A是通过 "直接复制" 的 元件B (FLA库中操作) 则元件A的坐标信息是错误的
			//可以理解为swf底层针对于这种 "直接复制" 做了某种优化,使得元件A的坐标信息其实反映的是把 元件B进行某种变化能够得到
			//所以这时候需要将shap重新添加到一个container里面 才可以
			//但是直接在次数进行修正则改变了显示树结构,导致递归错误(即时最后再把target add回去也不行,MovieClip无解,请其他小朋友不用尝试了)
			//所以目前的解决方案是最后再对所有Shape进行修正
			//@see DisplayTreeShapeFixer.fixShapeMetaProperty()
			if (_target is Shape)
			{
				var shapeMetaWarp:ShapeMetaWarp=new ShapeMetaWarp();
				shapeMetaWarp.shapeMeta=_meta as CESShapeMeta;
				shapeMetaWarp.sourceTarget=_target as Shape;
				allShapeMetaWarpVector.push(shapeMetaWarp);
			}
		}

		public function fillMaskMetaInfo(_target:Sprite, _maskMeta:CESMaskMeta):void
		{
			_maskMeta.name=_target.name;
			_maskMeta.x=_target.x;
			_maskMeta.y=_target.y;
			_maskMeta.width=_target.width;
			_maskMeta.height=_target.height;
		}

		public function getTargetTextureInfo(_target:DisplayObject):CESTextureMeta
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
		public function getEmptySpriteMeta():CESSpriteMeta
		{
			var rootSpMeta:CESSpriteMeta=new CESSpriteMeta();
			rootSpMeta.scaleX=rootSpMeta.scaleY=rootSpMeta.alpha=1;
			rootSpMeta.x=rootSpMeta.y=rootSpMeta.pivotX=rootSpMeta.pivotY=0
			rootSpMeta.childMetaArray=[];
			return rootSpMeta;
		}

		public function isMaskOrPH(_mc:DisplayObject):Boolean
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
