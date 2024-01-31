package game.controls
{
    import classes.mp.MPTeam;
    import classes.mp.MPUser;
    import classes.mp.room.MPRoomFFR;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import game.GameOptions;
    import classes.mp.mode.ffr.MPMatchFFR;
    import classes.mp.mode.ffr.MPMatchFFRTeam;
    import classes.mp.mode.ffr.MPMatchFFRUser;

    public class MPFFRScoreCompare extends Sprite
    {
        private var options:GameOptions;

        private var room:MPRoomFFR;
        private var labels:Array = [];
        private var labelCount:int = 0;
        private var startY:Number = 0;

        private var match:MPMatchFFR;
        private var useTeamView:Boolean;
        private var isSpectator:Boolean;

        public function MPFFRScoreCompare(options:GameOptions, parent:DisplayObjectContainer, room:MPRoomFFR)
        {
            if (parent)
                parent.addChild(this);

            this.options = options;
            this.match = room.activeMatch;

            useTeamView = match.teams.length > 1;
            isSpectator = options.isSpectator;

            for each (var team:MPMatchFFRTeam in match.teams)
            {
                for each (var user:MPMatchFFRUser in team.users)
                {
                    const text:PlayerLabel = new PlayerLabel(room, user);
                    addChild(text);
                    labels.push(text);
                }
            }

            labelCount = labels.length;

            startY = (Main.GAME_HEIGHT / 2) - ((labelCount / 2) * 40);

            update();
        }

        public function update():void
        {
            labels.sortOn(["position", "score", "username"], [Array.NUMERIC, Array.NUMERIC | Array.DESCENDING, Array.CASEINSENSITIVE]);

            for (var i:int = 0; i < labelCount; i++)
            {
                labels[i].update();
                labels[i].y = startY + (i * 42);
            }
        }
    }
}

import classes.mp.MPUser;
import classes.mp.Multiplayer;
import classes.mp.mode.ffr.MPMatchFFRUser;
import classes.mp.room.MPRoom;
import classes.mp.room.MPRoomFFR;
import classes.ui.Text;
import flash.display.Sprite;

internal class PlayerLabel extends Sprite
{
    private static const _mp:Multiplayer = Multiplayer.instance;

    public var room:MPRoom;
    public var user:MPUser;
    public var data:MPMatchFFRUser;

    public var isSelf:Boolean = false;

    public var txtPosition:Text;
    public var txtUsername:Text;
    public var txtScore:Text;

    private var _lastPosition:int = -1;
    private var _lastScore:int = -1;

    public function PlayerLabel(room:MPRoomFFR, data:MPMatchFFRUser):void
    {
        this.room = room;
        this.data = data;
        this.user = data.user;

        isSelf = _mp.currentUser == this.user;

        this.graphics.lineStyle(0, 0, 0);
        this.graphics.beginFill(0x000000, 0.75);
        this.graphics.drawRect(0, 0, 152, 41);
        this.graphics.endFill();

        this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
        this.graphics.beginFill(isSelf ? 0x91ff89 : 0xFFFFFF, 0.1);
        this.graphics.drawRect(0, 0, 151, 40);
        this.graphics.endFill();

        txtPosition = new Text(this, 5, 5, "", 20, "#DBDBDB");
        txtPosition.setAreaParams(30, 30, "right");

        txtUsername = new Text(this, 40, 2, user.name);

        txtScore = new Text(this, 40, 18, "", 10, "#EAEAEA");
    }

    public function update():void
    {
        if (_lastPosition != data.position)
        {
            txtPosition.text = data.position.toString();
            _lastPosition = data.position;
        }

        if (_lastScore != data.raw_score)
        {
            txtScore.text = data.raw_score + " / " + data.good + "-" + data.average + "-" + data.miss + "-" + data.boo;
            _lastScore = data.raw_score;
        }
    }

    public function get position():Number
    {
        return data.position;
    }

    public function get score():Number
    {
        return data.raw_score;
    }

    public function get username():String
    {
        return user.name;
    }
}
