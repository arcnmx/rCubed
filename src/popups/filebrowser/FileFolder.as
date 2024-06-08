package popups.filebrowser
{

    public class FileFolder
    {
        public var dir:AirFile;
        public var data:Vector.<FileFolderItem>;

        public var author:String;
        public var name:String;
        public var banner:String;
        public var ext:String;

        public function FileFolder(folder:AirFile, ext:String)
        {
            this.dir = folder;
            this.ext = ext;
            this.data = new <FileFolderItem>[];
        }

        public static function ofFile(file:AirFile, ext:String, item:FileFolderItem):FileFolder
        {
            var folder:FileFolder = new FileFolder(file.parent, ext);
            folder.data.push(item);
            return folder;
        }

        public function get folder():String
        {
            return dir.nativePath;
        }
    }
}
