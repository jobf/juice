#if js
import juice.driver.js.AudioDriver;
#else
import juice.driver.lime.AudioDriver;
#end
import juice.stream.sine.SineStream;

import lime.app.Application;

class Main extends Application {
	override function onWindowCreate() {

		var bufferSize = 1024;
		
		#if js
		var driver = AudioDriver.create(bufferSize);
		#else
		var driver = new AudioDriver(bufferSize);
		#end

		driver.setSampleStream(new SineStream());

		window.onMouseDown.add((x, y, button) -> {
			if (driver.isPlaying) {
				if (driver.isPaused) {
					driver.resume();
					driver.isPaused = false;
				} else {
					driver.pause();
					driver.isPaused = true;
				}
			} else {
				driver.play();
				driver.isPlaying = true;
			}
		});

		#if !js
		driver.play();
		driver.isPlaying = true;
		#end
	}

}
