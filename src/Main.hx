package ;

import luxe.tween.Actuate;
import luxe.Audio.AudioState;
import luxe.resource.Resource.AudioResource;
import luxe.Audio.AudioSource;
import luxe.Audio.AudioHandle;
import phoenix.geometry.TextGeometry;
import luxe.Text;
import io.github.dector.snake.Segment;
import io.github.dector.snake.Snake.Direction;
import luxe.Color;
import luxe.utils.Random;
import io.github.dector.snake.Level;
import luxe.Input;

using io.github.dector.snake.Snake.DirectionUtils;

class Main extends luxe.Game {

    private static inline var PIXEL_SIZE = 32;
    private static inline var PIXEL_INNER_SIZE = 16;
    private static inline var PIXEL_SPACING = 4;

    private static inline var INPUT_ACTION_LEFT = "left";
    private static inline var INPUT_ACTION_RIGHT = "right";
    private static inline var INPUT_ACTION_UP = "up";
    private static inline var INPUT_ACTION_DOWN = "down";
    private static inline var INPUT_ACTION_SPEEDUP = "speedup";
    private static inline var INPUT_ACTION_PAUSE = "pause";
    private static inline var INPUT_ACTION_RESTART = "restart";

    private static inline var MUSIC_TRACK1 = "assets/music/track1.ogg";

    private static inline var SOUND_EAT = "assets/sounds/eat.wav";
    private static inline var SOUND_GAME_OVER = "assets/sounds/game_over.wav";

    private static inline var STARTING_SNAKE_SPEED = 0.2;
    private static inline var INCREMENT_SNAKE_SPEED_COEF = 0.95;

    private var BACKGROUND_COLOR = new Color().rgb(0x2F484E);
    private var WALL_COLOR = new Color().rgb(0x1B2632);
    private var APPLE_COLOR = new Color().rgb(0xDF6F8A);
    private var SNAKE_HEAD_COLOR = new Color().rgb(0xEB4701);
    private var SNAKE_BODY_COLOR = new Color().rgb(0xA36422);

    private var naturalSnakeSpeed: Float;
    private var speedUpCoef = 0.75;
    private var snakeSpeed: Float;
    private var moveTime = 0.0;

    private var paused: Bool;
    private var died: Bool;

    private var speedingUp: Bool;

    var level: Level;

    var requestedDirection: Null<Direction>;

    var pausedText: TextGeometry;
    var diedText: TextGeometry;

    var musicAudio: AudioResource;
    var musicHandle: AudioHandle;

    var eatAudio: AudioResource;
    var gameOverAudio: AudioResource;

    override public function config(config: luxe.AppConfig) {
        config.preload.sounds = [
            { id: MUSIC_TRACK1, is_stream: true },
            { id: SOUND_EAT, is_stream: false },
            { id: SOUND_GAME_OVER, is_stream: false }
        ];
        return config;
    }

    override public function ready() {
        musicAudio = Luxe.resources.audio(MUSIC_TRACK1);

        eatAudio = Luxe.resources.audio(SOUND_EAT);
        gameOverAudio = Luxe.resources.audio(SOUND_GAME_OVER);

        musicHandle = Luxe.audio.loop(musicAudio.source);

        Luxe.renderer.clear_color = BACKGROUND_COLOR;

        Luxe.input.bind_key(INPUT_ACTION_LEFT, Key.left);
        Luxe.input.bind_key(INPUT_ACTION_RIGHT, Key.right);
        Luxe.input.bind_key(INPUT_ACTION_UP, Key.up);
        Luxe.input.bind_key(INPUT_ACTION_DOWN, Key.down);
        Luxe.input.bind_key(INPUT_ACTION_SPEEDUP, Key.space);
        Luxe.input.bind_key(INPUT_ACTION_PAUSE, Key.key_p);
        Luxe.input.bind_key(INPUT_ACTION_RESTART, Key.key_r);

        Luxe.input.bind_gamepad(INPUT_ACTION_LEFT, 14);
        Luxe.input.bind_gamepad(INPUT_ACTION_RIGHT, 15);
        Luxe.input.bind_gamepad(INPUT_ACTION_UP, 12);
        Luxe.input.bind_gamepad(INPUT_ACTION_DOWN, 13);
        Luxe.input.bind_gamepad(INPUT_ACTION_SPEEDUP, 0);
        Luxe.input.bind_gamepad(INPUT_ACTION_PAUSE, 8);
        Luxe.input.bind_gamepad(INPUT_ACTION_RESTART, 9);

        pausedText = Luxe.draw.text({
            text: "Paused",
            align: TextAlign.center,
            pos: Luxe.screen.mid,
            visible: false
        });

        diedText = Luxe.draw.text({
            text: "Game over",
            align: TextAlign.center,
            pos: Luxe.screen.mid,
            visible: false
        });

        createLevel();
    }

    private function createLevel() {
        level = new Level(20, 15);

        var pos = randomEmptyMapPosition();
        level.appleX = pos.x;
        level.appleY = pos.y;

        moveTime = 0;
        naturalSnakeSpeed = STARTING_SNAKE_SPEED;
        speedingUp = false;
        updateSnakeSpeed();
        level.snake.direction = Direction.Left;

        requestedDirection = null;
        paused = false;
        died = false;
    }

    override public function oninputdown(name:String, e:InputEvent) {
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
            case INPUT_ACTION_PAUSE:
                if (!died) {
                    paused = !paused;
                }
            case INPUT_ACTION_RESTART:
                if (died) {
                    Actuate.update(function(volume: Float) { Luxe.audio.volume(musicHandle, volume); }, 1.0, [0.3], [1.0]);
                }
                createLevel();
        }
    }

    override public function oninputup(name:String, e:InputEvent) {
        switch (name) {
            case INPUT_ACTION_SPEEDUP:
                speedingUp = false;
                updateSnakeSpeed();
        }
    }

    override public function onkeyup(e: KeyEvent) {
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

        drawMap();
        drawApple();
        drawSnake();

        pausedText.visible = paused;
        diedText.visible = died;
    }

    private function moveSnake(dt: Float) {
        if (died)
            return;

        if (paused) {
            return;
        }

        moveTime += dt;
        if (moveTime > snakeSpeed) {
            moveTime -= snakeSpeed;
        } else {
            return;
        }

        if (requestedDirection != null && canSnakeChangeDirectionTo(requestedDirection))
            level.snake.direction = requestedDirection;

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
                Luxe.audio.play(eatAudio.source);

                // Speed up snake
                naturalSnakeSpeed *= INCREMENT_SNAKE_SPEED_COEF;
                updateSnakeSpeed();

                var lastSegment = snake[snake.length-1];
                var segmentPosition = level.snake.direction.forCoordinates(lastSegment.x, lastSegment.y);
                snake.push(new Segment(segmentPosition.x, segmentPosition.y));

                var pos = randomEmptyMapPosition();
                level.appleX = pos.x;
                level.appleY = pos.y;
            }

            for (i in 1...snake.length) {
                var curX = snake[i].x;
                var curY = snake[i].y;
                snake[i].x = prevX;
                snake[i].y = prevY;
                prevX = curX;
                prevY = curY;
            }
        } else {
            died = true;

            Actuate.update(function(volume: Float) { Luxe.audio.volume(musicHandle, volume); }, 1.0, [1.0], [0.3]);

            Luxe.audio.play(gameOverAudio.source);
        }
    }

    private function updateSnakeSpeed() {
        snakeSpeed = naturalSnakeSpeed;
        if (speedingUp)
            snakeSpeed *= speedUpCoef;
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
