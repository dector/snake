package io.github.dector.snake.model;

enum PowerupType {

    SpeedUp(speedUpFactor: Float); // factor should be > 1
    SlowDown(slowDownFactor: Float); // factor should be > 1
}