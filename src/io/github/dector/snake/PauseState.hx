package io.github.dector.snake;

import luxe.Input.InputEvent;
import luxe.Text.TextAlign;
import phoenix.geometry.TextGeometry;
import luxe.States;
import luxe.States.State;

class PauseState extends luxe.State {

    var pausedText: TextGeometry;

    var states: States;

    var stupidTimer: Float;

    public function new(states: States) {
        super({ name: GameStates.PAUSE });
        this.states = states;
    }

    override public function init() {
        pausedText = Luxe.draw.text({
            text: "Paused",
            align: TextAlign.center,
            align_vertical: TextAlign.center,
            pos: Luxe.screen.mid,
            point_size: 40,
            visible: false
        });
    }

    override public function onenabled(_) {
        pausedText.visible = true;
        Luxe.events.fire(StateEvents.STATE_EVENT_PAUSING, { pausing: true });

        stupidTimer = Luxe.time + 0.5;
    }

    override public function ondisabled(_) {
        pausedText.visible = false;
        Luxe.events.fire(StateEvents.STATE_EVENT_PAUSING, { pausing: false });
    }

    override public function oninputdown(name:String, event:InputEvent) {
        if (stupidTimer > Luxe.time)
            return;

        if (name == "pause") {
            states.disable(GameStates.PAUSE);
        }
    }
}
