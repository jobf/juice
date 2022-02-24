package ob.juice;

import ob.juice.Wave;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import lime.media.AudioBuffer;
import lime.media.AudioSource;

class BufferedAudio {
	var buffer:AudioBuffer;
	var source:AudioSource;

	public function new() {}

	public function bufferAudio(sampleData:Bytes, sampleRate:Int, channels:Int = 1, bitsPerSample:Int = 16) {
		var bytes:BytesOutput = new BytesOutput();
		WaveFile.write(sampleData, bytes, sampleRate, channels, bitsPerSample);

		buffer = AudioBuffer.fromBytes(bytes.getBytes());
		source = new AudioSource(buffer);
	}

	public function play() {
		source.play();
	}
}
