package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class GameStartEvent extends TypedSFSEvent
    {
        public var room:Object;

        public function GameStartEvent(params:Object)
        {
            super(Multiplayer.EVENT_GAME_START);
            room = params.room;
        }
    }
}
