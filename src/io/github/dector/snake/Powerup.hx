package io.github.dector.snake;

class Powerup {

    public var x: Int;
    public var y: Int;
    public var type: Type;
    public var timeToLive: Float;

    public function new() {}
}

enum Type {

    SpeedUp(speedUpFactor: Float); // factor should be > 1
    SlowDown(slowDownFactor: Float); // factor should be > 1
}
