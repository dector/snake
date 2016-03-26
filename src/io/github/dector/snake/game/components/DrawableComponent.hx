package io.github.dector.snake.game.components;

import luxe.Color;
import luxe.Component;

class DrawableComponent extends Component {

    private static inline var STYLE_2_ENABLED = false;

    private static inline var PIXEL_SIZE_STYLE_1 = 32;
    private static inline var PIXEL_INNER_SIZE_STYLE_1 = 16;
    private static inline var PIXEL_SPACING_STYLE_1 = 4;

    private static inline var PIXEL_SIZE_STYLE_2 = 24;
    private static inline var PIXEL_SPACING_STYLE_2 = 6;

    private static inline var PIXEL_SIZE = STYLE_2_ENABLED ? PIXEL_SIZE_STYLE_2 : PIXEL_SIZE_STYLE_1;
    private static inline var PIXEL_INNER_SIZE = STYLE_2_ENABLED ? PIXEL_SIZE_STYLE_2 : PIXEL_INNER_SIZE_STYLE_1;
    private static inline var PIXEL_SPACING = STYLE_2_ENABLED ? PIXEL_SPACING_STYLE_2 : PIXEL_SPACING_STYLE_1;

    var context: Context;
    public var color: Color;

    public function new(context: Context, color: Color) {
        super({
            name: Components.Drawable
        });
        this.context = context;
        this.color = color;
    }

    override public function update(dt:Float) {
        drawPixel(Std.int(entity.pos.x), Std.int(entity.pos.y), color);
    }

    private function drawPixel(x: Int, y: Int, color: Color) {
        var levelW = context.levelWidth * (PIXEL_SIZE + PIXEL_SPACING) + PIXEL_SPACING;
        var levelH = context.levelHeight * (PIXEL_SIZE + PIXEL_SPACING) + PIXEL_SPACING;

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

class Context {

    public var levelWidth = 0;
    public var levelHeight = 0;

    public function new() {
    }
}