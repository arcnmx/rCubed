package
{
    import com.flashfla.utils.StringUtil;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.FileReference;
    import flash.system.ApplicationDomain;
    import flash.utils.ByteArray;
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;

    public class AirFile
    {
        public static var FlashFile:Class = null;
        public static var FlashFileStream:Class = null;

        public var _url:String = null;
        public var _file:FileReference = null;

        public static function initNative():void
        {
            try {
                var systemDomain:ApplicationDomain = ApplicationDomain.currentDomain.parentDomain;
                if (systemDomain == null) {
                    systemDomain = ApplicationDomain.currentDomain;
                }
                FlashFileStream = systemDomain.getDefinition("flash.filesystem::FileStream") as Class;
                FlashFile = systemDomain.getDefinition("flash.filesystem::File") as Class;
            } catch(e:Error) {
                Logger.error(e, "flash.filesystem missing");
            }
        }

        public function AirFile(url:String, file:FileReference)
        {
            this._url = url;
            this._file = file;
        }

        public static function ofFile(file:FileReference):AirFile
        {
            return new AirFile(null, file);
        }

        public static function ofUrl(url:String):AirFile
        {
            if (FlashFile != null)
                return AirFile.ofFile(new FlashFile(url));
            else
                return AirFile.ofAnyUrl(url);
        }

        public static function ofAnyUrl(url:String):AirFile
        {
            return new AirFile(url, null);
        }

        public static function get applicationStorageDirectory():AirFile
        {
            if (FlashFile != null)
                return AirFile.ofFile(FlashFile.applicationStorageDirectory as FileReference);
            else
                return AirFile.ofUrl("app-storage:/");
        }

        public static function get applicationDirectory():AirFile
        {
            if (FlashFile != null)
                return AirFile.ofFile(FlashFile.applicationDirectory as FileReference);
            else
                return AirFile.ofUrl("app:/");
        }

        public function get exists():Boolean
        {
            if (this.hasFile)
                return this.file.exists;
            else
            {
                try {
                    var fileStream:IDataInput = this.openRead(null);
                    if (fileStream != null)
                    {
                        this.close(fileStream);
                        return true;
                    }
                } catch (e:Error) { }
                return false;
            }
        }

        public function get file():Object
        {
            return this._file;
        }

        public function get hasFile():Boolean
        {
            return FlashFile != null && this._file != null;
        }

        public function get url():String
        {
            if (this.hasFile)
                return this.file.url;
            else
                return this._url;
        }

        public function toString():String
        {
            if (this.hasFile)
                return this.file.toString()
            else
                return this.url;
        }

        public function get parent():AirFile
        {
            if (this.hasFile)
                return AirFile.ofFile(this.file.parent);
            else
            {
                var p:String = this.url;
                if (this.isDirectory)
                    p = p.substring(0, p.length - 1);
                var slash:int = p.lastIndexOf("/");
                if (slash < 0)
                    slash = p.lastIndexOf("\\");
                if (slash >= 0)
                    return AirFile.ofUrl(p.substring(0, slash + 1));
                else
                    return null;
            }
        }

        public function get name():String
        {
            if (this.hasFile)
                return this.file.name;
            else
            {
                var p:String = this.url;
                if (this.isDirectory)
                    p = p.substring(0, p.length - 1);
                var slash:int = p.lastIndexOf("/");
                if (slash < 0)
                    slash = p.lastIndexOf("\\");
                if (slash >= 0)
                    return p.substring(slash + 1);
                else
                    return this.url;
            }
        }

        public function get extension():String
        {
            if (this.hasFile)
                return this.file.extension;
            else
            {
                var dot:int = this.url.lastIndexOf(".");
                if (dot >= 0)
                    return this.url.substring(dot + 1)
                else
                    return null;
            }
        }

        public function get isHidden():Boolean
        {
            if (this.hasFile)
                return this.file.isHidden;
            else
                return StringUtil.beginsWith(this.name, ".");
        }

        public function resolvePath(part:String):AirFile
        {
            if (this.hasFile)
                return AirFile.ofFile(this.file.resolvePath(part) as FileReference)
            else if (this.isDirectory)
                return AirFile.ofUrl(this.url + part);
            else
                return AirFile.ofUrl(this.parent.url + part);
        }

        public function get nativePath():String
        {
            if (this.hasFile)
                return this.file.nativePath;
            else
                return this._url;
        }

        public function get nativeFile():Object
        {
            if (this.hasFile && StringUtil.beginsWith(this.url, "app:/"))
                return new FlashFile(this.file.nativePath)
            else
                return this.file;
        }

        public function open(mode:String, errorCallback:Function):Object
        {
            if (!this.hasFile) {
                if (errorCallback != null) {
                    // TODO: tell errorCallback the file can't be opened!
                }
                return null;
            }
            var fileStream:Object = new FlashFileStream();
            //var fileStream:Object = new FileStream();
            if (errorCallback != null) {
                fileStream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorCallback);
                fileStream.addEventListener(IOErrorEvent.IO_ERROR, errorCallback);
            }
            try {
                var file:Object = mode == "read" ? this.file : this.nativeFile;
                fileStream.open(file, mode);
            } catch (e:Error) {
                if (errorCallback == null)
                    throw e;
                else
                    return null;
            }
            return fileStream;
        }

        public function close(fileStream:Object):void
        {
            if (this.hasFile && fileStream != null)
            {
                fileStream.close();
            }
        }

        public function openRead(errorCallback:Function):IDataInput
        {
            return this.open("read", errorCallback) as IDataInput;
        }

        public function openWrite(errorCallback:Function):IDataOutput
        {
            return this.open("write", errorCallback) as IDataOutput;
        }

        public function openAppend(errorCallback:Function):IDataOutput
        {
            return this.open("append", errorCallback) as IDataOutput;
        }

        public function get size():Number
        {
            if (this.file != null)
                return this.file.size;
            else
            {
                var fileStream:IDataInput = this.openRead(null);
                if (fileStream == null)
                    return 0;
                var sz:uint = fileStream.bytesAvailable;
                this.close(fileStream);
                return sz;
            }
        }

        public function get isDirectory():Boolean
        {
            if (this.hasFile)
                return this.file.isDirectory;
            else
                return StringUtil.endsWith(this.url, "/") || StringUtil.endsWith(this.url, "\\");
        }

        public function getDirectoryListing():Vector.<AirFile>
        {
            var air:Vector.<AirFile> = new <AirFile>[];
            if (this.hasFile)
            {
                var listing:Array = this.file.getDirectoryListing();
                for each (var file:Object in listing) {
                    air.push(AirFile.ofFile(file as FileReference));
                }
            }
            return air;
        }

        public static function browseForDirectory(callback:Function, title:String, typeFilter:Array=null):AirFile
        {
            if (FlashFile == null)
                return null;

            var file:AirFile = AirFile.ofFile(new FlashFile(null));
            if (callback != null)
            {
                var select:Function = function(e:Event):void
                {
                    callback({"target": file, "type": e.type});
                }
                file.file.addEventListener(Event.SELECT, callback);
            }
            file.file.browseForDirectory(title, typeFilter);
            return file;
        }
    }
}
