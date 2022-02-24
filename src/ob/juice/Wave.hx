package ob.juice;

import format.wav.Data;
import format.wav.Writer;
import haxe.io.Output;
import haxe.io.Bytes;

class WaveFile{
	public static function write(sampleData:Bytes, out:Output, sampleRate:Int=44100, channels:Int = 1, bitsPerSample:Int = 16){
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

		var wavWrite = new Writer(out);
		wavWrite.write(wav);
	}
}