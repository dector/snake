package io.github.dector.snake;

import luxe.tween.Actuate;
import luxe.Text.TextAlign;
import luxe.resource.Resource.AudioResource;
import luxe.Input.InputEvent;
import phoenix.geometry.TextGeometry;
import luxe.States;
import luxe.States.State;

class GameOverState extends luxe.State {

    var gameOverText: TextGeometry;

    var states: States;

    var gameOverAudio: AudioResource;

    var stupidTimer: Float;

    public function new(states: States) {
        super({ name: GameStates.GAME_OVER });
        this.states = states;
    }

    override public function init() {
        gameOverText = Luxe.draw.text({
            text: "Game Over",
            align: TextAlign.center,
            align_vertical: TextAlign.center,
            pos: Luxe.screen.mid,
            point_size: 40,
            visible: false
        });

        gameOverAudio = Luxe.resources.audio(Assets.SOUND_GAME_OVER);
    }

    override public function onenabled(_) {
        gameOverText.visible = true;
        Luxe.events.fire(StateEvents.STATE_EVENT_GAME_OVER, { showing: true });

        Luxe.audio.play(gameOverAudio.source);

        stupidTimer = Luxe.time + 0.5;
    }

    override public function ondisabled(_) {
        gameOverText.visible = false;
        Luxe.events.fire(StateEvents.STATE_EVENT_GAME_OVER, { showing: false });
    }

    override public function oninputdown(name:String, event:InputEvent) {
        if (stupidTimer > Luxe.time)
            return;

        if (name == "select") {
            //Luxe.events.fire(StateEvents.STATE_EVENT_RESTART);
            states.disable(GameStates.GAME_OVER);
        }
    }
}
