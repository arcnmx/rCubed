package game.controls
{
    import assets.gameplay.BarTopNormal;
    import assets.gameplay.BarTopSideways;
    import classes.ui.BoxCheck;
    import classes.ui.Text;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import game.GameOptions;

    public class BarTop extends GameControl
    {
        private var options:GameOptions;

        public var lastType:int = 0;

        public var type0:BarTopNormal;
        public var type1:BarTopSideways;

        public function BarTop(options:GameOptions, parent:DisplayObjectContainer):void
        {
            if (parent)
                parent.addChild(this);

            this.options = options;

            type0 = new BarTopNormal();
            type1 = new BarTopSideways();
        }

        public function set type(val:Number):void
        {
            this.removeChildren();

            if (val == 1)
            {
                addChild(type1);
                lastType = 1;
            }
            else
            {
                addChild(type0);
                lastType = 0;
            }
        }

        override public function get id():String
        {
            return GameLayoutManager.LAYOUT_BAR_TOP;
        }

        override public function getEditorInterface():GameControlEditor
        {
            var self:BarTop = this;

            var out:GameControlEditor = super.getEditorInterface();

            new Text(out, 10, out.cy, _lang.string("editor_component_alt_layout"));
            var checkLayout:BoxCheck = new BoxCheck(out, 10 + 3, out.cy + 22, e_changeHandler);
            checkLayout.checked = (lastType == 1);

            out.cy += 42;

            function e_changeHandler(e:Event):void
            {
                if (e.target == checkLayout)
                {
                    checkLayout.checked = !checkLayout.checked;
                    editorLayout["type"] = checkLayout.checked ? 1 : 0;
                    self.type = editorLayout["type"];
                }
            }

            return out;
        }
    }
}
