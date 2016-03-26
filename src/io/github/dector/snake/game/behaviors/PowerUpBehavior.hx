package io.github.dector.snake.game.behaviors;

import io.github.dector.snake.model.PowerupType;
import luxe.tween.Actuate;
import io.github.dector.snake.game.components.DrawableComponent;
import io.github.dector.snake.game.components.Components;
import luxe.Component;

class PowerUpBehavior extends Component {

    private static inline var BLINKING_FREQUENCY = 5.0; // Hz

    public var blinkingTime = 0.0;
    public var disposingTime = 0.0;

    private var passedTime = 0.0;
    private var blinking = false;

    private var updateContext: UpdateContext;

    public var type: PowerupType;

    public var drawableComponent: DrawableComponent;

    public function new(updateContext: UpdateContext, blinkingTime: Float, timeToLeave: Float, powerUpType: PowerupType) {
        super({
            name: Behaviors.PowerUp
        });

        this.updateContext = updateContext;

        this.blinkingTime = blinkingTime;
        this.disposingTime = timeToLeave;

        this.type = powerUpType;
    }

    override public function init() {
        drawableComponent = cast get(Components.Drawable);
    }

    override public function update(dt:Float) {
        if (updateContext.paused)
            return;

        passedTime += dt;

        if (!blinking && passedTime > blinkingTime) {
            blinking = true;

            Actuate.tween(drawableComponent.color, 1.0 / BLINKING_FREQUENCY, { a: 0.5 }).repeat().reflect();
        } else if (passedTime > disposingTime) {
            entity.scene.remove(entity);
        }
    }
}
