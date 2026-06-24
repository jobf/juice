package juice.driver.format;

import format.wav.Data;
import format.wav.Writer;
import haxe.io.BytesOutput;
import juice.API;

class AudioDriver extends AudioDriverBase {
	final totalSamples:Int;

	#if sys
	final outputPath:String;

	public function new(totalSamples:Int, outputPath:String, deviceSampleRate:Int=48000, bufferSize:Int=1024) {
		super(deviceSampleRate, bufferSize);
		this.totalSamples = totalSamples;
		this.outputPath = outputPath;
	}
	#else
	public function new(totalSamples:Int, deviceSampleRate:Int=48000, bufferSize:Int=1024) {
		super(deviceSampleRate, bufferSize);
		this.totalSamples = totalSamples;
	}
	#end

	public function stop():Void {}

	public function pause():Void {}

	public function resume():Void {}

	public function play():Void {
		isPlaying = true;
		samplesProcessed = 0;

		final channels = 2;
		final bytesPerFrame = channels * 4;
		var pcmOut = new BytesOutput();
		pcmOut.bigEndian = false;

		var remaining = totalSamples;
		while (remaining > 0) {
			var chunk = Std.int(Math.min(remaining, bufferSize));
			renderBuffer();
			for (i in 0...chunk) {
				pcmOut.writeInt32(Std.int(buffer[i * 2] * 0x7FFFFFFF));
				pcmOut.writeInt32(Std.int(buffer[i * 2 + 1] * 0x7FFFFFFF));
			}
			remaining -= chunk;
			samplesProcessed += chunk;
		}

		var wavOut = new BytesOutput();
		new Writer(wavOut).write({
			header: {
				format: WF_PCM,
				channels: channels,
				samplingRate: deviceSampleRate,
				byteRate: deviceSampleRate * bytesPerFrame,
				blockAlign: bytesPerFrame,
				bitsPerSample: 32
			},
			data: pcmOut.getBytes(),
			cuePoints: []
		});
		var wavBytes = wavOut.getBytes();

		#if js
		var blob = new js.html.Blob([wavBytes.getData()], {type: "audio/wav"});
		var url = js.html.URL.createObjectURL(blob);
		var a = cast(js.Browser.document.createElement("a"), js.html.AnchorElement);
		a.href = url;
		a.download = 'output.wav';
		a.click();
		js.html.URL.revokeObjectURL(url);
		#else
		var out = sys.io.File.write(outputPath, true);
		out.write(wavBytes);
		out.close();
		#end

		isPlaying = false;
	}
}
