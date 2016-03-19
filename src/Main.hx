package ;

import io.github.dector.snake.GameOverState;
import io.github.dector.snake.GameStates;
import io.github.dector.snake.PauseState;
import io.github.dector.snake.PlayState;
import luxe.States;
import io.github.dector.snake.Assets;
import io.github.dector.snake.Snake.Direction;

using io.github.dector.snake.Snake.DirectionUtils;

class Main extends luxe.Game {

    private var states: States;

    override public function config(config: luxe.AppConfig) {
        config.preload.sounds = [
            { id: Assets.MUSIC_TRACK1, is_stream: true },
            { id: Assets.SOUND_EAT, is_stream: false },
            { id: Assets.SOUND_GAME_OVER, is_stream: false }
        ];
        return config;
    }

    override public function ready() {
        states = new States();

        states.add(new PlayState(states));
        states.add(new PauseState(states));
        states.add(new GameOverState(states));

        states.set(GameStates.PLAY);
    }

}
