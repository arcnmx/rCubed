package classes
{
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;

    public class Site extends EventDispatcher
    {
        ///- Singleton Instance
        private static var _instance:Site = null;

        ///- Private Locals
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _loader:URLLoader;
        private var _isLoaded:Boolean = false;
        private var _isLoading:Boolean = false;
        private var _loadError:Boolean = false;

        ///- Public Locals
        public var data:Object;

        ///- Constructor
        public function Site(en:SingletonEnforcer)
        {
            if (en == null)
                throw Error("Multi-Instance Blocked");
        }

        public static function get instance():Site
        {
            if (_instance == null)
                _instance = new Site(new SingletonEnforcer());
            return _instance;
        }

        public function isLoaded():Boolean
        {
            return _isLoaded && !_loadError;
        }

        public function isError():Boolean
        {
            return _loadError;
        }

        ///- Site Loading
        public function load():void
        {
            // Kill old Loading Stream
            if (_loader && _isLoading)
            {
                removeLoaderListeners();
                _loader.close();
            }

            // Load New
            _isLoaded = false;
            _loadError = false;
            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(URLs.resolve(URLs.SITE_DATA_URL) + "?d=" + new Date().getTime());
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.session = _gvars.userSession;
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.load(req);
            _isLoading = true;
        }

        private function siteLoadComplete(e:Event):void
        {
            Logger.info(this, "Data Loaded");
            removeLoaderListeners();

            // Parse Response
            var siteDataString:String = e.target.data;
            try
            {
                data = JSON.parse(siteDataString);
            }
            catch (err:Error)
            {
                Logger.error(this, "Parse Failure: " + Logger.exception_error(err));
                Logger.error(this, "Wrote invalid response data to log folder. [logs/site.txt]");
                AirContext.writeTextFile(AirContext.getAppFile(Constant.LOG_PATH).resolvePath("site.txt"), siteDataString);

                _loadError = true;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
                return;
            }

            // Has Response
            _gvars.TOTAL_GENRES = data.game_total_genres;
            _gvars.MAX_CREDITS = data.game_max_credits;
            _gvars.SCORE_PER_CREDIT = data.game_score_per_credit;
            _gvars.MAX_DIFFICULTY = data.game_max_difficulty;
            _gvars.DIFFICULTY_RANGES = data.game_difficulty_range;
            _gvars.NONPUBLIC_GENRES = data.game_nonpublic_genres;

            // MP Divisions
            _gvars.divisionLevels = data.division_levels;
            _gvars.divisionTitles = data.division_titles;
            _gvars.divisionColors = data.division_colors;

            // Tokens
            _gvars.TOKENS = {};
            var tokens:Object = {};
            for each (var tok:Object in data.game_tokens)
            {
                if (!tokens[tok.type])
                    tokens[tok.type] = [];

                if (tok.picture != null)
                    tok.picture = URLs.resolve(tok.picture);

                tokens[tok.type][tok.id] = tok;

                if (tok.level)
                    _gvars.TOKENS[tok.level] = tok;
            }
            _gvars.TOKENS_TYPE = tokens;

            _isLoaded = true;
            _loadError = false;
            Logger.info(this, "Parse Complete");
            this.dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));

        }

        private function siteLoadError(err:ErrorEvent = null):void
        {
            Logger.error(this, "Load Failure: " + Logger.event_error(err));
            _loadError = true;
            removeLoaderListeners();
            this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, siteLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, siteLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, siteLoadError);
        }

        private function removeLoaderListeners():void
        {
            _isLoading = false;
            _loader.removeEventListener(Event.COMPLETE, siteLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, siteLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, siteLoadError);
        }
    }
}

class SingletonEnforcer
{
}
