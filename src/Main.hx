package ;

import io.github.dector.snake.model.Snake;
import io.github.dector.snake.game.states.GameOverState;
import io.github.dector.snake.game.states.GameStates;
import io.github.dector.snake.game.states.PauseState;
import io.github.dector.snake.game.states.PlayState;
import luxe.States;
import io.github.dector.snake.resources.Assets;
import io.github.dector.snake.model.Snake.Direction;

using io.github.dector.snake.model.Snake.DirectionUtils;

class Main extends luxe.Game {

    private var states: States;

    override public function config(config: luxe.AppConfig) {
        config.preload.sounds = [
            { id: Assets.MUSIC_TRACK1, is_stream: true },
            { id: Assets.SOUND_EAT, is_stream: false },
            { id: Assets.SOUND_GAME_OVER, is_stream: false }
        ];
        config.preload.textures = [
            { id: Assets.TEXTURE_A_BUTTON },
            { id: Assets.TEXTURE_MUSIC_ON },
            { id: Assets.TEXTURE_MUSIC_OFF }
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
