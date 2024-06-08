package
{
    import by.blooddy.crypto.MD5;
    import classes.DynamicLoader;
    import classes.FileTracker;
    import classes.chart.Song;
    import com.flashfla.utils.SystemUtil;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.system.ApplicationDomain;
    import flash.system.Capabilities;
    import flash.system.LoaderContext;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.utils.ByteArray;
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;

    /**
     * Contains methods that deal with AIR specific things, in regular flash builds, these are either excluded or stubbed.
     */
    public class AirContext
    {
        // Windows will store files in the current folder, other OS will use the application storage folder.
        public static var STORAGE_PATH:AirFile = initStoragePath();

        private static function initStoragePath():AirFile
        {
            if (isNative)
                AirFile.initNative();

            if (!isNative || SystemUtil.OS.toLowerCase().indexOf("win") == -1)
            {
                return AirFile.applicationStorageDirectory;
            }
            else
            {
                return AirFile.applicationDirectory;
            }
        }

        public static function initFolders():void
        {
            if (!STORAGE_PATH.hasFile) {
                return;
            }

            // song cache
            var folder:AirFile = STORAGE_PATH.resolvePath(Constant.SONG_CACHE_PATH);
            if (!folder.exists)
                folder.file.createDirectory();

            // replays
            folder = STORAGE_PATH.resolvePath(Constant.REPLAY_PATH);
            if (!folder.exists)
                folder.file.createDirectory();

            // noteskins
            folder = STORAGE_PATH.resolvePath(Constant.NOTESKIN_PATH);
            if (!folder.exists)
                folder.file.createDirectory();
        }

        public static function get isAir():Boolean
        {
            return Capabilities.playerType == "Desktop";
        }

        public static function get isNative():Boolean
        {
            return isAir && !isRuffle;
        }

        public static function get isRuffle():Boolean
        {
            return GlobalVariables.instance.flashvars["ruffle"] == "1";
        }

        public static function get hasFilesystem():Boolean
        {
            return isAir && AirFile.FlashFile != null;
        }

        public static function createFileName(file_name:String, replace:String = ""):String
        {
            // Remove chars not allowed in Windows filename \ / : * ? " < > |
            file_name = file_name.replace(/[~\\\/:\*\?\"<>\|]/g, replace);

            // Trim leading and trailing whitespace.
            file_name = file_name.replace(/^\s+|\s+$/gs, replace);

            return file_name;
        }

        static public function getLoaderContext():LoaderContext
        {
            var lc:LoaderContext = new LoaderContext();
            lc.applicationDomain = new ApplicationDomain(null);
            lc.allowCodeImport = true;
            return lc;
        }

        static public function getSongCachePath(song:Song):String
        {
            return Constant.SONG_CACHE_PATH + (song.songInfo.engine ? MD5.hash(song.songInfo.engine.id) + "/" + MD5.hash(song.songInfo.level_id.toString()) : '57fea2a7e69445179686b7579d5118ef/' + MD5.hash(song.id.toString())) + "/";
        }

        static public function getReplayPath(song:Song):String
        {
            return Constant.REPLAY_PATH + (song.songInfo.engine ? createFileName(song.songInfo.engine.id) : Constant.BRAND_NAME_SHORT_LOWER) + "/";
        }

        static public function encodeData(rawData:ByteArray, key:uint = 0):ByteArray
        {
            if (key == 0)
                return rawData;

            // Do some XOR stuff on the ByteArray.
            var sp:uint = rawData.position;
            rawData.position = 0;
            var storeData:ByteArray = new ByteArray();
            storeData.writeBytes(rawData);
            for (var bi:uint = 4; bi < rawData.length; bi += 4)
            {
                storeData[bi] ^= (key + bi) % 0xFF;
            }
            rawData.position = sp;
            storeData.position = 0;
            return storeData;
        }

        static private function e_fileError(e:Event):void
        {
            trace(e);
        }

        static public function getAppFile(path:String):AirFile
        {
            return STORAGE_PATH.resolvePath(path);
        }

        static public function doesFileExist(path:String):Boolean
        {
            return STORAGE_PATH.resolvePath(path).exists;
        }

        static public function writeFile(file:AirFile, bytes:ByteArray, key:uint = 0, errorCallback:Function = null):void
        {
            var fileStream:IDataOutput = file.openWrite(errorCallback != null ? errorCallback : e_fileError);
            if (fileStream != null)
            {
                fileStream.writeBytes(encodeData(bytes, key));
                file.close(fileStream);
            }
        }

        static public function readFile(file:AirFile, key:uint = 0, errorCallback:Function = null):ByteArray
        {
            var fileStream:IDataInput = file.openRead(errorCallback != null ? errorCallback : e_fileError);
            var readData:ByteArray = null;
            if (fileStream != null)
            {
                readData = new ByteArray();
                fileStream.readBytes(readData);
                file.close(fileStream);
                readData = encodeData(readData, key);
            }
            return readData;
        }

        static public function readTextFile(file:AirFile, errorCallback:Function = null):String
        {
            var fileStream:IDataInput = file.openRead(errorCallback != null ? errorCallback : e_fileError);
            var readData:String = null;
            if (fileStream != null)
            {
                readData = fileStream.readUTFBytes(fileStream.bytesAvailable);
                file.close(fileStream);
            }
            return readData;
        }

        static public function writeTextFile(file:AirFile, data:String, errorCallback:Function = null):void
        {
            if (data == null || data.length == 0)
                return;

            var fileStream:IDataOutput = file.openWrite(errorCallback != null ? errorCallback : e_fileError);
            if (fileStream != null)
            {
                fileStream.writeUTFBytes(data);
                file.close(fileStream);
            }
        }

        static public function appendTextFile(file:AirFile, data:String, errorCallback:Function = null):void
        {
            if (data == null || data.length == 0)
                return;

            var fileStream:IDataOutput = file.openAppend(errorCallback != null ? errorCallback : e_fileError);
            if (fileStream != null)
            {
                fileStream.writeUTFBytes(data);
                file.close(fileStream);
            }
        }

        static public function loadFile(file:AirFile, callback:Function = null, errorCallback:Function = null, context:LoaderContext = null):DynamicLoader {
            var dynloader:DynamicLoader = new DynamicLoader();
            var loader:Loader = dynloader;
            loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorCallback != null ? errorCallback : e_fileError);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorCallback != null ? errorCallback : e_fileError);

            if (callback != null)
            {
                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, callback);
            }

            loader.load(new URLRequest(file.url), context != null ? context : getLoaderContext());
            return dynloader;
        }

        static public function deleteFile(file:AirFile):Boolean
        {
            if (file.hasFile && file.exists)
            {
                file.file.moveToTrash();
                return true;
            }
            return false;
        }

        public static function getFileSize(file:AirFile, track:FileTracker = null, track_file_paths:Boolean = false):FileTracker
        {
            if (!track)
                track = new FileTracker();

            if (file == null || file.exists == false)
            {
                return track;
            }
            if (file.isDirectory)
            {
                track.dirs++;
                var files:Vector.<AirFile> = file.getDirectoryListing();
                for each (var f:AirFile in files)
                {
                    if (f.isDirectory)
                    {
                        getFileSize(f, track, track_file_paths);
                    }
                    else
                    {
                        if (track_file_paths)
                            track.file_paths.push(f);
                        track.files++;
                        track.size += f.size;
                    }
                }
            }
            else
            {
                if (track_file_paths)
                    track.file_paths.push(file);
                track.files++;
                track.size += file.size;
            }
            return track;
        }
    }
}
