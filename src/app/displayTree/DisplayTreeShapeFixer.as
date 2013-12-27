package app.displayTree
{
	import flash.display.Sprite;
	import flash.geom.Rectangle;

	public final class DisplayTreeShapeFixer
	{
		public function DisplayTreeShapeFixer()
		{
		}

		/**
		 * 修复所有ShapeMeta的错误信息
		 */
		public function fixShapeMetaProperty(_allShapeMetaWarpVector:Vector.<ShapeMetaWarp>):void
		{
			for each (var shapeMetaWarp:ShapeMetaWarp in _allShapeMetaWarpVector)
			{
				doFixShapeMeta(shapeMetaWarp);
			}
		}

		private function doFixShapeMeta(_warp:ShapeMetaWarp):void
		{
			var warpSp:Sprite=new Sprite();
			warpSp.addChild(_warp.sourceTarget);
			var re:Rectangle=warpSp.getBounds(warpSp);
			_warp.shapeMeta.x=re.x;
			_warp.shapeMeta.y=re.y;
			_warp.shapeMeta.pivotX=0;
			_warp.shapeMeta.pivotY=0;
		}


	}
}
