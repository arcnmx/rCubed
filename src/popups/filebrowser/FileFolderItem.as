package popups.filebrowser
{

    public class FileFolderItem
    {
        public var file:AirFile;
        public var info:Object;

        public function FileFolderItem(file:AirFile, info:Object)
        {
            this.file = file;
            this.info = info;
        }
    }
}
