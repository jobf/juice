package;

import juice.haxe.WaveFileSource;
import juice.core.VoiceSource;
import lime.app.Application;
import juice.lime.StreamBuffer;

class StreamBufferTest extends Application {
	var stream:StreamBuffer;

	override function onPreloadComplete() {
		// var filePath = "assets/sine.wav";
		// var filePath = "assets/loop-stereo.wav";
		// var filePath = "assets/loop-mono.wav";
		// var sampleSource = new WaveFileSource(filePath);

		var sampleSource = new VoiceSource({
			numChannels: 1,
		});

		stream = new StreamBuffer({
			numBuffers: 4,
			numSamplesInBuffer: 4096,
		}, sampleSource);

		stream.start();

		window.onKeyDown.add((code, modifier) -> {
			switch code {
				case T:
					sampleSource.trigger();
					return;
				case _:
					return;
			}
		});
	}

	override function update(deltaTime:Int) {
		super.update(deltaTime);
		stream.update();
	}
}
