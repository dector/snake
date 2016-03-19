package io.github.dector.snake;

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
import io.github.dector.snake.Snake.Direction;
import luxe.Color;

import Main;

using io.github.dector.snake.Snake.DirectionUtils;

class PlayState extends luxe.State {

    private static inline var PIXEL_SIZE = 32;
    private static inline var PIXEL_INNER_SIZE = 16;
    private static inline var PIXEL_SPACING = 4;

    private static inline var INPUT_ACTION_LEFT = "left";
    private static inline var INPUT_ACTION_RIGHT = "right";
    private static inline var INPUT_ACTION_UP = "up";
    private static inline var INPUT_ACTION_DOWN = "down";
    private static inline var INPUT_ACTION_SPEEDUP = "speedup";
    private static inline var INPUT_ACTION_SLOWMO = "slowMo";
    private static inline var INPUT_ACTION_PAUSE = "pause";
    private static inline var INPUT_ACTION_RESTART = "restart";
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

    var musicAudio: AudioResource;
    var musicHandle: AudioHandle;

    var eatAudio: AudioResource;

    var states: States;
    var pauseEventId: String;
    var gameOverEventId: String;

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
        level = new Level(20, 15);

        var pos = randomEmptyMapPosition();
        level.appleX = pos.x;
        level.appleY = pos.y;

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
        trace(name);
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
        if (e.keycode == Key.escape) {
            Luxe.shutdown();
        }
    }

    private function randomEmptyMapPosition() {
        var pos = randomMapPosition();
        while (level.get(pos.x, pos.y) || level.snake.body.filter(
            function(segment) { return segment.x == pos.x && segment.y == pos.y; }).length != 0) {
            pos = randomMapPosition();
        }

        return pos;
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
            if (newHeadX == level.appleX && newHeadY == level.appleY) {
                eatenApples++;

                Luxe.audio.play(eatAudio.source);

                // Speed up snake
                if (SPEEDUP_SNAKE_SPEED) {
                    naturalSnakeSpeed *= INCREMENT_SNAKE_SPEED_COEF;
                    updateSnakeSpeed();
                }

                updateEatenApplesText();

                // Tricky part. Add new segment right where head was
                snake.insert(1, new Segment(prevX, prevY));

                var pos = randomEmptyMapPosition();
                level.appleX = pos.x;
                level.appleY = pos.y;
            } else {
                for (i in 1...snake.length) {
                    var curX = snake[i].x;
                    var curY = snake[i].y;
                    snake[i].x = prevX;
                    snake[i].y = prevY;
                    prevX = curX;
                    prevY = curY;
                }
            }
        } else {
            states.enable(GameStates.GAME_OVER);
        }
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

    private function drawApple() {
        drawPixel(level.appleX, level.appleY, APPLE_COLOR);
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
