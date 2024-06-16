package classes
{
    import flash.events.IEventDispatcher;

    public interface IPreloader extends IEventDispatcher
    {
        function load():void;
        function loaderName():String;
        function isLoaded():Boolean;
        function isError():Boolean;
    }
}
