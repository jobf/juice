package ob.juice.core;

import lime.utils.ArrayBufferView;
import lime.utils.Int16Array;
import ob.juice.dsp.Oscillator;
import ob.juice.dsp.Voice;
import ob.juice.core.SampleSource;
import haxe.io.Bytes;

class VoiceSource extends SampleSource {
	var config:SourceConfig;
	var voice:Voice;
	var position:Int = 0;

	public function new(config:SourceConfig) {
		this.config = config;
		voice = new Voice(220.0, 0.75, config.sampleRate, SINE);
	}

	 public function bufferNextSamples(buffer:Bytes, numSamples:Int):Void{
		for (n in 0...numSamples) {
			var sample = voice.getSample(position);
			position++;
			var v = Std.int(sample * 0x7FFF);
			buffer.set(n << 1, v);
			buffer.set((n << 1) + 1, v >>> 8);
		}

		totalSamplesDelivered += buffer.length;
	}

	public function get_numChannels():Int {
		return config.numChannels;
	}

	public function get_bitsPerSample():Int {
		return config.bitsPerSample;
	}

	public function get_bytesPerSample():Int {
		return 2;
	}

	public function get_sampleRate():Int {
		return config.sampleRate;
	}

	public function get_totalSamplesDelivered():Int {
		return position;
	}

	public function trigger():Void {
		voice.trigger();
	}
}
