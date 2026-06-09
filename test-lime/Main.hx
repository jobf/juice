#if js
import juice.driver.js.AudioDriver;
#else
import juice.driver.lime.AudioDriver;
#end

import juice.source.sine.SineSource;

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
		var bufferSize = 1024;
		#if js
		var driver = AudioDriver.create(bufferSize);
		#else
		var driver = new AudioDriver(bufferSize);
		#end
		driver.setSampleSource(new SineSource());
		driver.play();
	}
}
