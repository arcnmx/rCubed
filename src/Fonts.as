package
{

    public class Fonts
    {
        public static var BASE_FONT:String = "Noto Sans Bold"; //new NotoSans.Bold().fontName;
        public static var BASE_FONT_CJK:String = "Noto Sans CJK JP Bold"; //new NotoSans.CJKBold().fontName;
        public static var AACHEN_LIGHT:String = "Aachen-Light"; //new AachenLight().fontName;
        public static var BEBAS_NEUE:String = "BebasNeue-Regular"; //new BebasNeue().fontName;
        public static var BREE_SERIF:String = "Bree Serif"; //new BreeSerif().fontName;
        public static var ULTRA:String = "Ultra"; //new Ultra().fontName;
        public static var XOLONIUM:String = "Xolonium Regular"; //new Xolonium.Regular().fontName;
        public static var HUSSAR:String = "Hussar Regular"; //new HussarBold.Regular().fontName;

        // Embed Fonts
        CONFIG::embedFonts {
        AachenLight;
        BreeSerif;
        Ultra;
        BebasNeue;
        Xolonium.Bold;
        Xolonium.Regular;
        HussarBold.Italic;
        HussarBold.Regular;
        NotoSans.CJKBold;
        NotoSans.Bold;
        }

        // Static Initializer
        {
            private static const fallbackFont:String = "Arial";
            if (!CONFIG::embedFonts) {
                // TODO: loader shouldn't be that bad... an example:
                // https://web.archive.org/web/20140130110101/http://labs.tomasino.org/2009/07/16/flash-as3-runtime-font-manager/
                BASE_FONT = fallbackFont;
                BASE_FONT_CJK = fallbackFont;
                AACHEN_LIGHT = fallbackFont;
                BEBAS_NEUE = fallbackFont;
                BREE_SERIF = fallbackFont;
                ULTRA = fallbackFont;
                XOLONIUM = fallbackFont;
                HUSSAR = fallbackFont;
            }
        }
    }
}
