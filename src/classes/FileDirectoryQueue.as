package classes
{
    public class FileDirectoryQueue
    {
        public var dir:AirFile;
        public var level:int;
        public var maxDepth:int;

        public function FileDirectoryQueue(dir:AirFile, level:int=0, maxDepth:int=2)
        {
            this.dir = dir;
            this.level = level;
            this.maxDepth = maxDepth;
        }

        public static function ofRoot(dir:AirFile, maxDepth:int=2):FileDirectoryQueue
        {
            return new FileDirectoryQueue(dir, 0, maxDepth);
        }

        public function childQueue(dir:AirFile):FileDirectoryQueue
        {
            return new FileDirectoryQueue(dir, this.level + 1, this.maxDepth)
        }

        public function getFileListing(dirQueue:Vector.<FileDirectoryQueue>):Vector.<AirFile>
        {
            var files:Vector.<AirFile> = new <AirFile>[];
            var found:Vector.<AirFile> = this.dir.getDirectoryListing();
            for each (var file:AirFile in found)
            {
                if (file.isHidden)
                    continue;

                if (file.isDirectory)
                {
                    if (this.level < this.maxDepth)
                        dirQueue.push(this.childQueue(file));
                }
                else
                {
                    files.push(file);
                }
            }
            return files;
        }
    }
}
