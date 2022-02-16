package ob.juice;

import format.wav.Data;
import format.wav.Writer;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import lime.media.AudioBuffer;
import lime.media.AudioSource;

class BufferedAudio {
	var buffer:AudioBuffer;
	var source:AudioSource;

	public function new() {}

	public function bufferAudio(sampleData:Bytes, sampleRate:Int, channels:Int = 1, bitsPerSample:Int = 16) {
		var wav:WAVE = {
			header: {
				format: WF_PCM,
				channels: channels,
				samplingRate: sampleRate,
				byteRate: Std.int(sampleRate * channels * bitsPerSample / 8),
				blockAlign: Std.int(channels * bitsPerSample / 8),
				bitsPerSample: bitsPerSample,
			},
			data: sampleData,
			cuePoints: [
				{
					id: 0,
					sampleOffset: 0
				}
			]
		}

		// var fileOutput = File.write('tone.wav', true);
		// var wavWrite = new Writer(fileOutput);
		var bytes:BytesOutput = new BytesOutput();
		var wavWrite = new Writer(bytes);
		wavWrite.write(wav);

		buffer = AudioBuffer.fromBytes(bytes.getBytes());
		source = new AudioSource(buffer);
	}

	public function play() {
		source.play();
	}
}
