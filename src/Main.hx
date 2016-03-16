package ;

import luxe.Color;
import luxe.Text;
import luxe.Input;

class Main extends luxe.Game {

    var text: Text;

    override public function config(config: luxe.AppConfig) {
        return config;

    }

    override public function ready() {
        text = new Text({
            text: "Hello, luxe",
            color: new Color().rgb(0xffffff)
        });

        text.pos = Luxe.screen.mid;
        text.pos.x -= text.geom.text_width / 2;
        text.pos.y -= text.geom.text_height / 2;
    }

    override public function onkeyup(e: KeyEvent) {
        if(e.keycode == Key.escape) {
            Luxe.shutdown();
        }

    }

    override public function update(dt: Float) {

    }


}
