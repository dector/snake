package io.github.dector.snake;

class Snake {

//    public var head: Segment;
    public var body: Array<Segment> = [];

    public var direction = Direction.Left;

    public function new() {
    }
}

enum Direction {
    Left;
    Right;
    Up;
    Down;
}

class DirectionUtils {

    public static function forCoordinates(direction: Direction, x: Int, y: Int) {
        return switch (direction) {
            case Direction.Left:
                { x: x-1, y: y };
            case Direction.Right:
                { x: x+1, y: y };
            case Direction.Up:
                { x: x, y: y-1 };
            case Direction.Down:
                { x: x, y: y+1 };
        }
    }
}
