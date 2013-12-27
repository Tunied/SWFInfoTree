package app.displayTree.optimizer
{
	import copyengine.ui.starling.component.meta.CESDisplayObjectMeta;
	import copyengine.ui.starling.component.meta.CESFileMeta;
	import copyengine.ui.starling.component.meta.CESMovieClipMeta;
	import copyengine.ui.starling.component.meta.CESShapeMeta;
	import copyengine.ui.starling.component.meta.CESSpriteMeta;

	import org.as3commons.lang.StringUtils;

	public final class DisplayTreeOptimizer
	{
		public function DisplayTreeOptimizer()
		{
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
		public function optimize(_meta:CESFileMeta):CESFileMeta
		{
			var isContinueOptimize:Boolean=true;
			while (isContinueOptimize)
			{
				isContinueOptimize=doOptimize(_meta);
			}
			return _meta;
		}

		/**
		 *While-True循环,遍历调用该函数,每次调用优化一次及返回
		 * <li>TRUE		表示当前优化了一次,while循环需要继续
		 * <li>FALSE		表示当前没有做任何优化,while循环可以结束
		 */
		private function doOptimize(_meta:*):Boolean
		{
			if (_meta is CESMovieClipMeta)
			{
				return doOptimizeMovieClipMeta(_meta as CESMovieClipMeta)
			}
			else if (_meta is CESSpriteMeta)
			{
				return doOptimizeSpriteMeta(_meta as CESSpriteMeta);
			}
			else if (_meta is CESFileMeta)
			{
				return doOptimizeFileMeta(_meta as CESFileMeta);
			}
			return false;
		}

		private function doOptimizeFileMeta(_meta:CESFileMeta):Boolean
		{
			for (var symbolKey:String in _meta.allSubSymbolDic)
			{
				var optimzeResult:CESDisplayObjectMeta=checkAndOptimizeMeta(_meta.allSubSymbolDic[symbolKey]);
				if (optimzeResult)
				{
					_meta.allSubSymbolDic[symbolKey]=optimzeResult;
					return true;
				}
				else
				{
					var childOptimizeResult:Boolean=doOptimize(_meta.allSubSymbolDic[symbolKey]);
					if (childOptimizeResult == true)
					{
						return true;
					}
				}
			}
			return false;
		}


		private function doOptimizeMovieClipMeta(_meta:CESMovieClipMeta):Boolean
		{
			for (var frameIndex:int=0; frameIndex < _meta.mSubFrameArray.length; frameIndex++)
			{
				var optimizeResult:CESDisplayObjectMeta=checkAndOptimizeMeta(_meta.mSubFrameArray[frameIndex]);
				if (optimizeResult)
				{
					_meta.mSubFrameArray[frameIndex]=optimizeResult;
					return true;
				}
				else
				{
					var childOptimizeResult:Boolean=doOptimize(_meta.mSubFrameArray[frameIndex]);
					if (childOptimizeResult == true)
					{
						return true;
					}
				}
			}
			return false;
		}

		private function doOptimizeSpriteMeta(_meta:CESSpriteMeta):Boolean
		{
			for (var childIndex:int=0; childIndex < _meta.childMetaArray.length; childIndex++)
			{
				var optimizeResult:CESDisplayObjectMeta=checkAndOptimizeMeta(_meta.childMetaArray[childIndex]);
				if (optimizeResult)
				{
					_meta.childMetaArray[childIndex]=optimizeResult;
					return true;
				}
				else
				{
					var childOptimizeResult:Boolean=doOptimize(_meta.childMetaArray[childIndex]);
					if (childOptimizeResult == true)
					{
						return true;
					}
				}
			}
			return false;
		}


		private function checkAndOptimizeMeta(_meta:CESDisplayObjectMeta):CESDisplayObjectMeta
		{
			if (_meta is CESSpriteMeta)
			{
				var spMeta:CESSpriteMeta=_meta as CESSpriteMeta;

				//如果Sp仅有一个子且该child为一个shape
				if (spMeta.childMetaArray.length == 1 && spMeta.childMetaArray[0] is CESShapeMeta)
				{
					var shapeMeta:CESShapeMeta=spMeta.childMetaArray[0] as CESShapeMeta;
					//该子对象和其父对象有一个meta的名字不为instance开头,及未取过名字
					if (StringUtils.startsWith(spMeta.name, "instance") || StringUtils.startsWith(shapeMeta.name, "instance"))
					{
						shapeMeta.scaleX*=spMeta.scaleX;
						shapeMeta.scaleY*=spMeta.scaleY;
						shapeMeta.x=shapeMeta.x * shapeMeta.scaleX + _meta.x;
						shapeMeta.y=shapeMeta.y * shapeMeta.scaleY + _meta.y;
						shapeMeta.width*=shapeMeta.scaleX;
						shapeMeta.height*=shapeMeta.scaleY;
						shapeMeta.name=StringUtils.startsWith(spMeta.name, "instance") ? shapeMeta.name : spMeta.name;
						return shapeMeta;
					}

				}
			}
			return null;
		}

	}
}
