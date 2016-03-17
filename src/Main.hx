package ;

import luxe.Color;
import luxe.utils.Random;
import io.github.dector.snake.Level;
import luxe.Input;

class Main extends luxe.Game {

    private static inline var PIXEL_SIZE = 32;
    private static inline var PIXEL_INNER_SIZE = 16;
    private static inline var PIXEL_SPACING = 4;

    private var WALL_COLOR = new Color().rgb(0xffffff);
    private var APPLE_COLOR = new Color().rgb(0x00ff00);

    /*private static inline var APPLE_ENTITY = "apple";

    private static inline var DRAWABLE_COMPONENT = "drawable";
    private static inline var POSITION_COMPONENT = "position";*/

    var level: Level;

    override public function config(config: luxe.AppConfig) {
        return config;
    }

    override public function ready() {
        level = new Level(20, 15);
        /*var apple = new Entity({
            name: APPLE_ENTITY
        });

        apple.add(new Position());
        apple.add(new Drawable());*/

        var pos = randomEmptyMapPosition();
        level.appleX = pos.x;
        level.appleY = pos.y;
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

            var pos = randomEmptyMapPosition();
            level.appleX = pos.x;
            level.appleY = pos.y;
        }

    }

    private function randomEmptyMapPosition() {
        var pos = randomMapPosition();
        while (level.get(pos.x, pos.y)) {
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

    override public function update(dt: Float) {
        drawMap();
        drawApple();
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
