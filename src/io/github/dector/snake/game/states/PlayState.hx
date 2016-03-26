package io.github.dector.snake.game.states;

import io.github.dector.snake.game.components.DrawableComponent;
import io.github.dector.snake.game.entities.Entities;
import luxe.Entity;
import io.github.dector.snake.model.Segment;
import io.github.dector.snake.resources.Assets;
import io.github.dector.snake.model.Powerup;
import io.github.dector.snake.model.Snake;
import io.github.dector.snake.model.Level;
import io.github.dector.snake.model.Snake.Direction;
import io.github.dector.snake.model.PowerupType;

import luxe.Sprite;
import luxe.Color;
import luxe.States;
import luxe.States.State;
import luxe.options.StateOptions;
import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Text.TextAlign;
import luxe.Input.Key;
import luxe.Input.InputEvent;
import luxe.Input.GamepadEvent;
import luxe.Input.KeyEvent;
import luxe.Audio.AudioHandle;
import luxe.resource.Resource.AudioResource;
import phoenix.geometry.TextGeometry;

using io.github.dector.snake.model.Snake.DirectionUtils;

class PlayState extends luxe.State {

    private static inline var STYLE_2_ENABLED = false;

    private static inline var PIXEL_SIZE_STYLE_1 = 32;
    private static inline var PIXEL_INNER_SIZE_STYLE_1 = 16;
    private static inline var PIXEL_SPACING_STYLE_1 = 4;

    private static inline var PIXEL_SIZE_STYLE_2 = 24;
    private static inline var PIXEL_SPACING_STYLE_2 = 6;

    private static inline var PIXEL_SIZE = STYLE_2_ENABLED ? PIXEL_SIZE_STYLE_2 : PIXEL_SIZE_STYLE_1;
    private static inline var PIXEL_INNER_SIZE = STYLE_2_ENABLED ? PIXEL_SIZE_STYLE_2 : PIXEL_INNER_SIZE_STYLE_1;
    private static inline var PIXEL_SPACING = STYLE_2_ENABLED ? PIXEL_SPACING_STYLE_2 : PIXEL_SPACING_STYLE_1;

    private static inline var INPUT_ACTION_LEFT = "left";
    private static inline var INPUT_ACTION_RIGHT = "right";
    private static inline var INPUT_ACTION_UP = "up";
    private static inline var INPUT_ACTION_DOWN = "down";
    private static inline var INPUT_ACTION_SPEEDUP = "speedup";
    private static inline var INPUT_ACTION_SLOWMO = "slowMo";
    private static inline var INPUT_ACTION_PAUSE = "pause";
    private static inline var INPUT_ACTION_RESTART = "restart";
    private static inline var INPUT_ACTION_MUTE = "mute";
    private static inline var INPUT_ACTION_SELECT = "select";

    private static inline var STARTING_SNAKE_SPEED = 0.2;
    private static inline var INCREMENT_SNAKE_SPEED_COEF = 0.95;
    private static inline var SLOWMO_SNAKE_SPEED = 0.6;
    private static inline var SPEEDUP_SNAKE_SPEED = false;

    private static inline var GAMEPAD_SENSITIVITY = 0.2;

    private var BACKGROUND_COLOR = new Color().rgb(0x2F484E);
    private var WALL_COLOR = new Color().rgb(0x1B2632);
    private var APPLE_COLOR = new Color().rgb(0xDF6F8A);
    private var SNAKE_HEAD_COLOR = new Color().rgb(0xEB4701);
    private var SNAKE_BODY_COLOR = new Color().rgb(0xA36422);
    private var POWER_UP_SPEED_UP_COLOR = new Color().rgb(0xBD2633);
    private var POWER_UP_SPEED_DOWN_COLOR = new Color().rgb(0x44881A);
    private var POWER_UP_UNKNOWN_COLOR = new Color().rgb(0xB1DBEE);

    private var naturalSnakeSpeed: Float;
    private var speedUpCoef = 0.6;
    private var snakeSpeed: Float;
    private var moveTime = 0.0;

    private var paused: Bool;

    private var speedingUp: Bool;
    private var slowMo: Bool;

    private var eatenApples: Int;

    var level: Level;

    var requestedDirection: Null<Direction>;

    var applesText: TextGeometry;
    var musicIndicator: Sprite;

    var musicAudio: AudioResource;
    var musicHandle: AudioHandle;

    var eatAudio: AudioResource;

    var states: States;
    var pauseEventId: String;
    var gameOverEventId: String;

    var powerUpColor: Color;
    var powerUpBlinkingTime: Float;
    var powerUpDeadTime: Float;
    var powerUpBlinking: Bool;

    var drawableContext = new Context();

    public function new(states: States) {
        super({ name: GameStates.PLAY });
        this.states = states;
    }

    public override function init() {
        musicAudio = Luxe.resources.audio(Assets.MUSIC_TRACK1);

        eatAudio = Luxe.resources.audio(Assets.SOUND_EAT);

        musicHandle = Luxe.audio.loop(musicAudio.source);

        Luxe.renderer.clear_color = BACKGROUND_COLOR;

        Luxe.input.bind_key(INPUT_ACTION_LEFT, Key.left);
        Luxe.input.bind_key(INPUT_ACTION_RIGHT, Key.right);
        Luxe.input.bind_key(INPUT_ACTION_UP, Key.up);
        Luxe.input.bind_key(INPUT_ACTION_DOWN, Key.down);
        Luxe.input.bind_key(INPUT_ACTION_SPEEDUP, Key.space);
        Luxe.input.bind_key(INPUT_ACTION_SLOWMO, Key.key_x);
        Luxe.input.bind_key(INPUT_ACTION_PAUSE, Key.key_p);
        Luxe.input.bind_key(INPUT_ACTION_RESTART, Key.key_r);
        Luxe.input.bind_key(INPUT_ACTION_SELECT, Key.enter);
        Luxe.input.bind_key(INPUT_ACTION_MUTE, Key.key_m);

        Luxe.input.bind_gamepad(INPUT_ACTION_LEFT, 14);
        Luxe.input.bind_gamepad(INPUT_ACTION_RIGHT, 15);
        Luxe.input.bind_gamepad(INPUT_ACTION_UP, 12);
        Luxe.input.bind_gamepad(INPUT_ACTION_DOWN, 13);
        Luxe.input.bind_gamepad(INPUT_ACTION_SPEEDUP, 0);
        Luxe.input.bind_gamepad(INPUT_ACTION_SLOWMO, 1);
        Luxe.input.bind_gamepad(INPUT_ACTION_PAUSE, 8);
        Luxe.input.bind_gamepad(INPUT_ACTION_RESTART, 9);
        Luxe.input.bind_gamepad(INPUT_ACTION_SELECT, 0);

        applesText = Luxe.draw.text({
            pos: new Vector(30, 30),
            point_size: 18
        });

        musicIndicator = new Sprite({
            texture: Luxe.resources.texture(Assets.TEXTURE_MUSIC_ON),
            size: new Vector(48, 48)
        });
        musicIndicator.pos = new Vector(
            Luxe.screen.width - musicIndicator.size.x / 2,
            musicIndicator.size.y / 2
        );

        createLevel();
    }

    override function onenter(_) {
        pauseEventId = Luxe.events.listen(StateEvents.STATE_EVENT_PAUSING, onPausing);
        gameOverEventId = Luxe.events.listen(StateEvents.STATE_EVENT_GAME_OVER, onGameOver);
    }

    override function onleave(_) {
        Luxe.events.unlisten(pauseEventId);
        Luxe.events.unlisten(gameOverEventId);
    }

    private function onPausing(e: { pausing: Bool }) {
        paused = e.pausing;

        if (paused) {
            Actuate.update(musicVolume, 1.5, [1.0], [0.3]);
        } else {
            Actuate.update(musicVolume, 1.5, [0.3], [1.0]);
        }
    }

    private function musicVolume(volume: Float) {
        Luxe.audio.volume(musicHandle, volume);
    }

    private function onGameOver(e: { showing: Bool }) {
        paused = e.showing;

        if (e.showing)
            Actuate.update(function(volume: Float) { Luxe.audio.volume(musicHandle, volume); }, 1.0, [1.0], [0.3]);
        else {
            Actuate.update(function(volume: Float) { Luxe.audio.volume(musicHandle, volume); }, 1.0, [0.3], [1.0]);
            createLevel();
        }
    }

    private function createLevel() {
        var levelW = 20;
        var levelH = 15;

        level = new Level(levelW, levelH);

        drawableContext.levelWidth = levelW;
        drawableContext.levelHeight = levelH;

        var apple = new Entity({
            name: Entities.Apple
        });
        var appleDrawable = new DrawableComponent(drawableContext, APPLE_COLOR);
        apple.add(appleDrawable);
        var pos = randomEmptyMapPosition();
        apple.pos.set(pos.x, pos.y, 0, 0);

        moveTime = 0;
        naturalSnakeSpeed = if (SPEEDUP_SNAKE_SPEED) STARTING_SNAKE_SPEED else 0.17;
        speedingUp = false;
        updateSnakeSpeed();
        level.snake.direction = Direction.Left;

        requestedDirection = null;
        paused = false;

        eatenApples = 0;
        updateEatenApplesText();
    }

    public override function oninputdown(name: String, event:InputEvent) {
        if (event.name == INPUT_ACTION_MUTE) {
            var audioEnabled = !Luxe.audio.active;

            musicIndicator.texture = audioEnabled
            ? Luxe.resources.texture(Assets.TEXTURE_MUSIC_ON)
            : Luxe.resources.texture(Assets.TEXTURE_MUSIC_OFF);

            Luxe.audio.active = true; // To pause sounds correctly
            if (audioEnabled) {
                Luxe.audio.unpause(musicHandle);
            } else {
                Luxe.audio.pause(musicHandle);
            }
            Luxe.audio.active = audioEnabled;
        }

        if (states.enabled(GameStates.PAUSE))
            return;
        if (states.enabled(GameStates.GAME_OVER))
            return;

        switch (name) {
            case INPUT_ACTION_LEFT:
                requestedDirection = Direction.Left;
            case INPUT_ACTION_RIGHT:
                requestedDirection = Direction.Right;
            case INPUT_ACTION_UP:
                requestedDirection = Direction.Up;
            case INPUT_ACTION_DOWN:
                requestedDirection = Direction.Down;
            case INPUT_ACTION_SPEEDUP:
                speedingUp = true;
                updateSnakeSpeed();
            case INPUT_ACTION_SLOWMO:
                slowMo = true;
                updateSnakeSpeed();
            case INPUT_ACTION_PAUSE:
                states.enable(GameStates.PAUSE);
            case INPUT_ACTION_RESTART:
                createLevel();
        }
    }

    public override function oninputup(name: String, event:InputEvent) {
        switch (name) {
            case INPUT_ACTION_SPEEDUP:
                speedingUp = false;
                updateSnakeSpeed();
            case INPUT_ACTION_SLOWMO:
                slowMo = false;
                updateSnakeSpeed();
        }
    }

    public override function ongamepadaxis(e:GamepadEvent) {
        var calibratedValue = e.value;/*if (event.axis == 0)
            event.value - gamepadAxisXCalibrated;
        else if (event.axis == 1)
            event.value - gamepadAxisYCalibrated;
        else event.value;*/

        if (calibratedValue > 0 && calibratedValue > GAMEPAD_SENSITIVITY
            || calibratedValue < 0 && calibratedValue < -GAMEPAD_SENSITIVITY) {

            if (e.axis == 0) {
                if (calibratedValue < 0)
                    requestedDirection = Direction.Left;
                else
                    requestedDirection = Direction.Right;
            } else if (e.axis == 1) {
                if (calibratedValue < 0)
                    requestedDirection = Direction.Up;
                else
                    requestedDirection = Direction.Down;
            }
        }
    }

    public override function onkeyup(e:KeyEvent) {
        if (e.keycode == Key.key_u) {
            paused = !paused; // For screenshot/debug purposes
        }
        if (e.keycode == Key.escape) {
            Luxe.shutdown();
        }
    }

    private function randomEmptyMapPosition() {
        var pos = randomMapPosition();
        while (level.get(pos.x, pos.y)
            || apple().pos.x == pos.x && apple().pos.y == pos.y
            || level.powerUps.filter(function(p: Powerup) { return p.x == pos.x && p.y == pos.y; }).length != 0
            || level.snake.body.filter(
                function(segment) { return segment.x == pos.x && segment.y == pos.y; }).length != 0) {
            pos = randomMapPosition();
        }

        return pos;
    }

    private function apple() {
        return Luxe.scene.entities.get(Entities.Apple);
    }

    private function randomMapPosition() {
        return {
            x: Luxe.utils.random.int(1, level.width() - 1),
            y: Luxe.utils.random.int(1, level.height() - 1)
        }
    }

    private function canSnakeChangeDirectionTo(direction: Direction) {
        var head = level.snake.body[0];
        var newPosition = direction.forCoordinates(head.x, head.y);

        return canSnakeMoveTo(newPosition.x, newPosition.y);
    }

    override public function update(dt: Float) {
        moveSnake(dt);
    }

    override public function onrender() {
        drawMap();
        drawPowerUps();
        drawApple();
        drawSnake();
    }

    private function moveSnake(dt: Float) {
        if (paused) {
            return;
        }

        moveTime += dt;
        if (moveTime > snakeSpeed) {
            while (moveTime > snakeSpeed)
                moveTime -= snakeSpeed;
        } else {
            return;
        }

        // Generate powerups
        var powerUpChance = 1;//0.1;
        if (level.powerUps.length == 0 && Luxe.utils.random.bool(powerUpChance)) {
            var powerUp = new Powerup();

            var position = randomEmptyMapPosition();
            powerUp.x = position.x;
            powerUp.y = position.y;

            powerUp.timeToLive = 5.0;
            powerUp.type = (Luxe.utils.random.bool(0.75)) ? PowerupType.SpeedUp(1.2) : PowerupType.SlowDown(1.2);
            level.powerUps.push(powerUp);

            powerUpColor = switch (powerUp.type) {
                case SpeedUp(_):
                    POWER_UP_SPEED_UP_COLOR.clone();
                case SlowDown(_):
                    POWER_UP_SPEED_DOWN_COLOR.clone();
                default:
                    POWER_UP_UNKNOWN_COLOR.clone();
            };
            powerUpDeadTime = Luxe.time + powerUp.timeToLive;
            trace(Luxe.time);
            trace(powerUp.timeToLive);
            powerUpBlinkingTime = powerUpDeadTime - 2; // 2 sec before
            powerUpBlinking = false;
        }
        if (level.powerUps.length != 0) {
            var powerUp = level.powerUps[0];

            if (Luxe.time > powerUpBlinkingTime && !powerUpBlinking) {
                Actuate.tween(powerUpColor, 0.2, { a: 0.5 }).repeat().reflect();
                powerUpBlinking = true;
            }
            if (Luxe.time > powerUpDeadTime) {
                level.powerUps.remove(powerUp);
                Actuate.stop(powerUpColor);

                powerUpDeadTime = 0;
                powerUpBlinkingTime = 0;
                powerUpBlinking = false;
                powerUpColor = null;
            }
        }

        if (requestedDirection != null && canSnakeChangeDirectionTo(requestedDirection)) {
            level.snake.direction = requestedDirection;
            requestedDirection = null;
        }

        var direction = level.snake.direction;

        var snake = level.snake.body;

        var prevX = snake[0].x;
        var prevY = snake[0].y;

        // move head
        var newHeadX = prevX;
        var newHeadY = prevY;
        switch (direction) {
            case Right:
                newHeadX++;
            case Left:
                newHeadX--;
            case Up:
                newHeadY--;
            case Down:
                newHeadY++;
        }
        if (canSnakeMoveTo(newHeadX, newHeadY)) {
            snake[0].x = newHeadX;
            snake[0].y = newHeadY;

            // Check if snake eats apple
            if (isSnakeEatsApple(newHeadX, newHeadY)) {
                Luxe.audio.play(eatAudio.source);

                performEatApple(prevX, prevY);
            } else {
                performSnakeMove(prevX, prevY);

                // Check powerups
                var powerUpsToEat = level.powerUps.filter(function(p: Powerup) { return p.x == newHeadX && p.y == newHeadY; });
                if (powerUpsToEat.length > 0) {
                    var powerUp = powerUpsToEat[0];
                    switch (powerUp.type) {
                        case SpeedUp(speedUpFactor):
                            naturalSnakeSpeed /= speedUpFactor;
                            updateSnakeSpeed();
                        case SlowDown(slowDownFactor):
                            naturalSnakeSpeed *= slowDownFactor;
                            updateSnakeSpeed();
                    }

                    level.powerUps.remove(powerUp);
                }
            }
        } else {
            states.enable(GameStates.GAME_OVER);
        }
    }

    private function isSnakeEatsApple(headX: Int, headY: Int) {
        return headX == apple().pos.x && headY == apple().pos.y;
    }

    private function performEatApple(headX: Int, headY: Int) {
        eatenApples++;

        // Speed up snake
        if (SPEEDUP_SNAKE_SPEED) {
            naturalSnakeSpeed *= INCREMENT_SNAKE_SPEED_COEF;
            updateSnakeSpeed();
        }

        updateEatenApplesText();

        // Tricky part. Add new segment right where head was
        level.snake.body.insert(1, new Segment(headX, headY));

        var pos = randomEmptyMapPosition();
        apple().pos.x = pos.x;
        apple().pos.y = pos.y;
    }

    private function performSnakeMove(prevX: Int, prevY: Int) {
        var snake = level.snake.body;

        var lastSegmentIndex = snake.length - 1;
        var lastSegment = snake[lastSegmentIndex];
        snake.remove(lastSegment);

        // Snake before movement:     [H] [1] [2] [3] [4] [5]
        //                         +---+                   |
        //                         |                       |
        //                         |   +-------------------+
        //                         v   v
        // Snake after movement:  [H] [5] [1] [2] [3] [4]
        lastSegment.x = prevX;
        lastSegment.y = prevY;
        snake.insert(1, lastSegment);
    }

    private function updateSnakeSpeed() {
        snakeSpeed = naturalSnakeSpeed;
        if (slowMo)
            snakeSpeed = SLOWMO_SNAKE_SPEED;
        if (speedingUp)
            snakeSpeed *= speedUpCoef;
    }

    private function updateEatenApplesText() {
        applesText.text = 'Apples: $eatenApples';
    }

    private function canSnakeMoveTo(x: Int, y: Int) {
        return !level.get(x, y)
        && level.snake.body.filter(
            function(segment) { return segment.x == x && segment.y == y; }).length == 0;
    }

    private function drawMap() {
        for (x in 0...level.width()) {
            for (y in 0...level.height()) {
                if (level.get(x, y)) {
                    drawPixel(x, y, WALL_COLOR);
                }
            }
        }
    }

    private function drawPowerUps() {
        var powerUps = level.powerUps;
        if (powerUps.length == 0)
            return;

        for (i in 0...powerUps.length) {
            drawPixel(powerUps[i].x, powerUps[i].y, powerUpColor);
        }
    }

    private function drawApple() {
        //drawPixel(level.appleX, level.appleY, APPLE_COLOR);
    }

    private function drawSnake() {
        var snake = level.snake.body;

        drawPixel(snake[0].x, snake[0].y, SNAKE_HEAD_COLOR);

        for (i in 1...level.snake.body.length) {
            drawPixel(snake[i].x, snake[i].y, SNAKE_BODY_COLOR);
        }
    }

    private function drawPixel(x: Int, y: Int, color: Color) {
        var levelW = level.width() * (PIXEL_SIZE + PIXEL_SPACING) + PIXEL_SPACING;
        var levelH = level.height() * (PIXEL_SIZE + PIXEL_SPACING) + PIXEL_SPACING;

        var x0 = (Luxe.screen.width - levelW) / 2;
        var y0 = (Luxe.screen.height - levelH) / 2;

        var pixelX = x0 + x * (PIXEL_SIZE + PIXEL_SPACING) + PIXEL_SPACING;
        var pixelY = y0 + y * (PIXEL_SIZE + PIXEL_SPACING) + PIXEL_SPACING;

        Luxe.draw.rectangle({
            immediate: true,
            x: pixelX,
            y: pixelY,
            w: PIXEL_SIZE,
            h: PIXEL_SIZE,
            color: color
        });

        Luxe.draw.box({
            immediate: true,
            x: pixelX + (PIXEL_SIZE - PIXEL_INNER_SIZE) / 2,
            y: pixelY + (PIXEL_SIZE - PIXEL_INNER_SIZE) / 2,
            w: PIXEL_INNER_SIZE,
            h: PIXEL_INNER_SIZE,
            color: color
        });
    }


}
