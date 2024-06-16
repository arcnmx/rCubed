package classes
{
    import classes.replay.Replay;
    import flash.events.Event;

    public class SongPreview extends Replay
    {
        public var songData:SongInfo;

        public function SongPreview(song_id:int, songData:SongInfo=null)
        {
            super(0);
            this.level = song_id;
            this.songData = songData;
            this.isPreview = true;
        }

        public override function loaderName():String
        {
            return "Preview";
        }

        public override function isLoaded():Boolean
        {
            return _isLoaded && this.songData != null;
        }

        public override function isError():Boolean
        {
            return _isLoaded && this.songData == null;
        }

        public override function load():void
        {
            if (this.songData == null)
                this.songData = Playlist.instanceCanon.playList[this.level];

            if (this.songData != null)
                this.level = songData.level;

            setupSongPreview();

            this._isLoaded = true;
            if (this.songData != null)
                dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));
            else
                dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
        }

        private function setupSongPreview():void
        {
            var _gvars:GlobalVariables = GlobalVariables.instance;

            this.user = new User(false, false);
            this.user.siteId = 1743546;
            this.user.name = "Song Preview";
            this.user.skillLevel = _gvars.MAX_DIFFICULTY;
            this.user.loadAvatar();

            this.timestamp = Math.floor((new Date()).getTime() / 1000);
            this.settings = _gvars.playerUser.settings;

            _gvars.options.fill();
        }
    }
}
