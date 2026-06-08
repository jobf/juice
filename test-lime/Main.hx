#if js
import juice.driver.js.AudioDriver;
#else
import juice.driver.lime.AudioDriver;
#end

import juice.source.sine.AudioSource;

import lime.app.Application;

class Main extends Application {
	override function onWindowCreate() {
		#if js
		// browser required interactino before audio can start
		window.onMouseDown.add((x, y, button) -> {
			start();
		});
		#else
		start();
		#end
	}

	function start() {
		var driver = new AudioDriver();
		driver.setAudioSource(new AudioSource(driver.getSamplingRate()));
		driver.play();
	}
}
