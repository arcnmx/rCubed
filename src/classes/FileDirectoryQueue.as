package classes
{
    import flash.filesystem.File;

    public class FileDirectoryQueue
    {
        public var dir:File;
        public var level:int;
        public var maxDepth:int;

        public function FileDirectoryQueue(dir:File, level:int=0, maxDepth:int=2)
        {
            this.dir = dir;
            this.level = level;
            this.maxDepth = maxDepth;
        }

        public static function ofRoot(dir:File, maxDepth:int=2):FileDirectoryQueue
        {
            return new FileDirectoryQueue(dir, 0, maxDepth);
        }

        public function childQueue(dir:File):FileDirectoryQueue
        {
            return new FileDirectoryQueue(dir, this.level + 1, this.maxDepth)
        }

        public function getFileListing(dirQueue:Vector.<FileDirectoryQueue>):Vector.<File>
        {
            var files:Vector.<File> = new <File>[];
            var found:Array = this.dir.getDirectoryListing();
            for each (var file:File in found)
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
