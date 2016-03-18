package ;

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

    private var BACKGROUND_COLOR = new Color().rgb(0x2F484E);
    private var WALL_COLOR = new Color().rgb(0x1B2632);
    private var APPLE_COLOR = new Color().rgb(0xDF6F8A);
    private var SNAKE_HEAD_COLOR = new Color().rgb(0xEB4701);
    private var SNAKE_BODY_COLOR = new Color().rgb(0xA36422);

    private var naturalSnakeSpeed = 0.2;
    private var fastSnakeSpeed = 0.1;
    private var snakeSpeed: Float;
    private var moveTime = 0.0;

    /*private static inline var APPLE_ENTITY = "apple";

    private static inline var DRAWABLE_COMPONENT = "drawable";
    private static inline var POSITION_COMPONENT = "position";*/

    var level: Level;

    var requestedDirection: Null<Direction>;

    override public function config(config: luxe.AppConfig) {
        return config;
    }

    override public function ready() {
        Luxe.renderer.clear_color = BACKGROUND_COLOR;

        createLevel();
    }

    private function createLevel() {
        level = new Level(20, 15);
        /*var apple = new Entity({
            name: APPLE_ENTITY
        });

        apple.add(new Position());
        apple.add(new Drawable());*/

        var pos = randomEmptyMapPosition();
        level.appleX = pos.x;
        level.appleY = pos.y;

        moveTime = 0;
        snakeSpeed = naturalSnakeSpeed;
    }

    override public function onkeydown(event:KeyEvent) {
        switch (event.keycode) {
            case Key.left:
                requestedDirection = Direction.Left;
            case Key.right:
                requestedDirection = Direction.Right;
            case Key.up:
                requestedDirection = Direction.Up;
            case Key.down:
                requestedDirection = Direction.Down;
            case Key.space:
                snakeSpeed = fastSnakeSpeed;
        }
    }

    override public function onkeyup(e: KeyEvent) {
        if (e.keycode == Key.escape) {
            Luxe.shutdown();
        }

        if (e.keycode == Key.space) {
            /*var apple = Luxe.scene.entities.get(APPLE_ENTITY);
            var position: Position = cast apple.get(POSITION_COMPONENT);
            position.x = new Random(Luxe.time).int(0, level.width());
            position.y = new Random(Luxe.time).int(0, level.height());*/
        }

        if (e.keycode == Key.key_r) {
            createLevel();
        } else if (e.keycode == Key.space) {
            snakeSpeed = naturalSnakeSpeed;
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
    }

    private function moveSnake(dt: Float) {
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
            // Die
        }
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
        /*var apple = Luxe.scene.entities.get(APPLE_ENTITY);
        var position: Position = cast apple.get(POSITION_COMPONENT);
        drawPixel(position);*/

        drawPixel(level.appleX, level.appleY, APPLE_COLOR);
    }

    private function drawSnake() {
        var snake = level.snake.body;

        drawPixel(snake[0].x, snake[0].y, SNAKE_HEAD_COLOR);

        for (i in 1...level.snake.body.length) {
            drawPixel(snake[i].x, snake[i].y, SNAKE_BODY_COLOR);
        }
    }

//    private function drawPixel(position: Position) {
    private function drawPixel(x: Int, y: Int, color: Color) {
        var levelW = level.width() * (PIXEL_SIZE + PIXEL_SPACING) + PIXEL_SPACING;
        var levelH = level.height() * (PIXEL_SIZE + PIXEL_SPACING) + PIXEL_SPACING;

        var x0 = (Luxe.screen.width - levelW) / 2;
        var y0 = (Luxe.screen.height - levelH) / 2;

        var pixelX = x0 + x * (PIXEL_SIZE + PIXEL_SPACING) + PIXEL_SPACING;
        var pixelY = y0 + y * (PIXEL_SIZE + PIXEL_SPACING) + PIXEL_SPACING;

        Luxe.draw.rectangle({
            /*x: position.x * 8 + 1,
            y: position.y * 8 + 1,*/
            immediate: true,
            x: pixelX,
            y: pixelY,
            w: PIXEL_SIZE,
            h: PIXEL_SIZE,
            color: color
        });

        Luxe.draw.box({
            /*x: position.x * 8 + 1 + 1,
            y: position.y * 8 + 1 + 1,*/
            immediate: true,
            x: pixelX + (PIXEL_SIZE - PIXEL_INNER_SIZE) / 2,
            y: pixelY + (PIXEL_SIZE - PIXEL_INNER_SIZE) / 2,
            w: PIXEL_INNER_SIZE,
            h: PIXEL_INNER_SIZE,
            color: color
        });
    }

}
