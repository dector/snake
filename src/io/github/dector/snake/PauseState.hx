package io.github.dector.snake;

import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Sprite;
import luxe.Color;
import phoenix.geometry.QuadGeometry;
import luxe.Input.InputEvent;
import luxe.Text;
import luxe.Text.TextAlign;
import phoenix.geometry.TextGeometry;
import luxe.States;
import luxe.States.State;

class PauseState extends luxe.State {

    var background: QuadGeometry;
    var pausedText: TextGeometry;
    var continueIcon: Sprite;
    var continueText: Text;

    var states: States;

    var stupidTimer: Float;

    public function new(states: States) {
        super({ name: GameStates.PAUSE });
        this.states = states;
    }

    override public function init() {
        background = Luxe.draw.box({
            x: 0,
            y: 0,
            w: Luxe.screen.width,
            h: Luxe.screen.height,
            color: new Color().rgb(0xffffff),
            visible: false
        });
        background.color.a = 0;

        pausedText = Luxe.draw.text({
            text: "Paused",
            align: TextAlign.center,
            align_vertical: TextAlign.center,
            pos: Luxe.screen.mid,
            point_size: 40,
            visible: false
        });

        continueText = new Text({
            text: "Continue",
            align: TextAlign.left,
            align_vertical: TextAlign.center,
            point_size: 24,
            visible: false
        });
        continueText.pos = new Vector(
            Luxe.screen.w - continueText.geom.text_width - 32,
            Luxe.screen.h - continueText.geom.text_height / 2 - 32
        );

        continueIcon = new Sprite({
            texture: Luxe.resources.texture(Assets.TEXTURE_A_BUTTON),
            visible: false
        });
        continueIcon.pos = new Vector(
            continueText.pos.x - continueIcon.size.x / 2,
            continueText.pos.y);
    }

    override public function onenabled(_) {
        setVisible(true);
        Luxe.events.fire(StateEvents.STATE_EVENT_PAUSING, { pausing: true });

        background.color.tween(0.5, { a: 0.5 });

        stupidTimer = Luxe.time + 0.5;
    }

    override public function ondisabled(_) {
        setVisible(false);
        Luxe.events.fire(StateEvents.STATE_EVENT_PAUSING, { pausing: false });

        background.color.a = 0;
    }

    override public function oninputdown(name:String, event:InputEvent) {
        if (stupidTimer > Luxe.time)
            return;

        if (name == "pause" || name == "select") {
            states.disable(GameStates.PAUSE);
        }
    }

    private function setVisible(visible: Bool) {
        background.visible = visible;
        pausedText.visible = visible;
        continueIcon.visible = visible;
        continueText.visible = visible;
    }
}
