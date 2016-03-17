package io.github.dector.snake;

class Level {

    private var map: Array<Bool>;
    private var w: Int;
    private var h: Int;

    public var appleX: Int;
    public var appleY: Int;

    public function new(w: Int, h: Int) {
        map = new Array();
        this.w = w;
        this.h = h;

        for (x in 0...w) {
            for (y in 0...h) {
               set(x, y, x == 0 || y == 0 || x == w-1 || y == h-1);
            }
        }
    }

    private function set(x: Int, y: Int, value: Bool) {
        map[y * w + x] = value;
    }

    public function get(x: Int, y: Int) {
        return map[y * w + x];
    }

    public function width() {
        return w;
    }

    public function height() {
        return h;
    }
}
