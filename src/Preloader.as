package
{
    import assets.GameBackgroundColor;
    import classes.IPreloader;
    import flash.events.EventDispatcher;
    import flash.events.Event;

    public class Preloader extends EventDispatcher implements IPreloader
    {
        public static const EVENT_DATA_LOADED:String = GlobalVariables.LOAD_COMPLETE;
        public static const EVENT_DATA_ERROR:String = GlobalVariables.LOAD_ERROR;

        public var loaders:Object = new Object();

        public function preload(loader:IPreloader):void
        {
            var prev:Object = loaders[loader.loaderName()];
            if (prev != null)
            {
                prev.removeEventListener(GlobalVariables.LOAD_COMPLETE, e_loaderComplete);
                prev.removeEventListener(GlobalVariables.LOAD_ERROR, e_loaderError);
            }

            loader.addEventListener(GlobalVariables.LOAD_COMPLETE, e_loaderComplete);
            loader.addEventListener(GlobalVariables.LOAD_ERROR, e_loaderError);
            loaders[loader.loaderName()] = loader;
        }

        public function load():void
        {
            for each (var loader:IPreloader in loaders)
            {
                if (!loader.isLoaded())
                    loader.load();
            }
        }

        public function reload():void
        {
            for each (var loader:IPreloader in loaders)
            {
                loader.load();
            }
        }

        public function isLoaded():Boolean
        {
            return amtLoaded == amtTotal;
        }

        public function isError():Boolean
        {
            for each (var loader:IPreloader in loaders)
            {
                if (loader.isError())
                    return true;
            }
            return false;
        }

        public function get amtLoaded():uint
        {
            var count:uint = 0;
            for each (var loader:IPreloader in loaders)
            {
                if (loader.isLoaded())
                    count++;
            }
            return count;
        }

        public function get amtTotal():uint
        {
            var count:uint = 0;
            for each (var loader:IPreloader in loaders)
            {
                count++;
            }
            return count;
        }

        private function e_loaderComplete(e:Event):void
        {
            if (isLoaded())
                dispatchEvent(new Event(Event.COMPLETE));
            else
                dispatchEvent(e);
        }

        private function e_loaderError(e:Event):void
        {
            dispatchEvent(e);
        }

        /// IPreloader
        public function loaderName():String
        {
            return "Data";
        }
    }
}
