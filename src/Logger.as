package
{
    import com.flashfla.utils.TimeUtil;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.system.Capabilities;
    import flash.utils.getTimer;
    import flash.utils.IDataOutput;

    public class Logger
    {
        private static var LOG_FILE:AirFile;

        private static const DEBUG_LINES:Array = ["Info: ", "Debug: ", "Warning: ", "Error: ", "Success: "];
        private static const DEBUG_COLORS:Array = ["", "\u001b[1;35m", "\u001b[1;33m", "\u001b[1;31m", "\u001b[1;32m"];
        private static const DEBUG_COLOR_RESET:String = "\u001b[0m";

        public static const INFO:Number = 0; // Blue
        public static const DEBUG:Number = 1; // Purple
        public static const WARNING:Number = 2; // Yellow
        public static const ERROR:Number = 3; // Red
        public static const SUCCESS:Number = 4; // Green

        public static var enabled:Boolean = CONFIG::debug;
        public static var file_log:Boolean = false;
        public static var history:Array = [];

        private static var file_log_buffer:String = "";
        private static var file_log_buffer_time:Number = 0;

        public static function init():void
        {
            // Check for special file to enable file logging.
            if (AirContext.doesFileExist("logging.txt"))
            {
                trace("Logging Flag Found, enabling.");
                file_log = true;
                enabled = true;
            }
        }

        public static function initLogFile():void
        {
            if (file_log && LOG_FILE == null)
            {
                var now:Date = new Date();
                var filename:String = AirContext.createFileName(now.toLocaleString(), " ");
                LOG_FILE = AirContext.getAppFile(Constant.LOG_PATH).resolvePath(filename + ".txt");
                var fileStream:IDataOutput = LOG_FILE.openAppend(e_logFileFail);
                if (fileStream != null)
                {
                    fileStream.writeUTFBytes("======================" + filename + "======================\n");
                    fileStream.writeUTFBytes("OS: " + Capabilities.os + " | " + Capabilities.version + "\n");
                    fileStream.writeUTFBytes("R3 Version: " + Constant.AIR_VERSION + " | " + CONFIG::timeStamp + " | " + Main.SWF_VERSION + "\n");
                    LOG_FILE.close(fileStream);
                }
            }

            function e_logFileFail(e:Event):void
            {
                trace("Unable to use file logging.");
                LOG_FILE = null;
            }
        }

        public static function enableLogger():void
        {
            file_log = true;
            enabled = true;
            initLogFile();
        }

        public static function divider(clazz:*):void
        {
            log(clazz, WARNING, "------------------------------------------------------------------------------------------------", true);
        }

        public static function info(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, INFO, text, simple);
        }

        public static function debug(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, DEBUG, text, simple);
        }

        public static function warning(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, WARNING, text, simple);
        }

        public static function error(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, ERROR, text, simple);
        }

        public static function success(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, SUCCESS, text, simple);
        }

        public static function log(clazz:*, level:int, text:*, simple:Boolean = false):void
        {
            // Check if Logger Enabled
            if (!enabled)
                return;

            // Store History
            var currentTime:Number = getTimer();
            history.push([currentTime, class_name(clazz), level, text, simple]);
            if (history.length > 250)
                history.unshift();

            // Create Log Message
            var msg:String = "";
            if (text is Error)
            {
                var err:Error = (text as Error);
                msg = "Error: " + exception_error(err);
            }
            else if (text is ErrorEvent)
            {
                var erre:ErrorEvent = (text as ErrorEvent);
                msg = "Error: " + event_error(erre);
            }
            else
            {
                msg = text;
            }

            msg = ((!simple ? "[" + TimeUtil.convertToHHMMSS(currentTime / 1000) + "][" + class_name(clazz) + "] " : "") + msg);

            // Display
            //trace(DEBUG_COLORS[level] + msg + DEBUG_COLOR_RESET); // For consoles that support color.
            trace(level + ":" + msg);

            if (LOG_FILE != null)
            {
                file_log_buffer += (msg + "\n");

                // Buffer file writes if within the last 150ms of a write to prevent file writing bottlenecks.
                if (currentTime - file_log_buffer_time > 150)
                {
                    AirContext.appendTextFile(LOG_FILE, file_log_buffer, null);

                    file_log_buffer = "";
                    file_log_buffer_time = currentTime;
                }
            }
        }

        public static function destroy():void
        {
            if (LOG_FILE != null)
            {
                if (file_log_buffer.length > 0)
                {
                    AirContext.appendTextFile(LOG_FILE, file_log_buffer, null);
                }
            }
        }

        public static function exception_error(err:Error):String
        {
            return "(" + err.errorID + ") " + err.name + "\n" + err.message + "\n" + err.getStackTrace();
        }

        public static function event_error(e:ErrorEvent):String
        {
            return "(" + e.type + ") " + e.errorID + ": " + e.text;
        }

        public static function class_name(clazz:*):String
        {
            if (clazz is String)
                return clazz;
            var t:String = (Object(clazz).constructor).toString();
            return t.substr(7, t.length - 8);
        }
    }
}
