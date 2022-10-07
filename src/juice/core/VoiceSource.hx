package juice.core;

import juice.dsp.Voice;
import juice.core.SampleSource;
import haxe.io.Bytes;

class VoiceSource extends SampleSource {
	var config:SourceConfig;
	var voice:Voice;
	var position:Int = 0;

	public function new(config:SourceConfig) {
		this.config = config;
		voice = new Voice(220.0, 0.75, config.sampleRate, SINE);
	}

	public function setFrequency(frequencyHz:Float):Void {
		voice.frequency = frequencyHz;
	}

	public function bufferNextSamples(buffer:Bytes, numSamples:Int):Void {
		// here we fill the buffer of Bytes with juicy audio samples
		for (n in 0...numSamples) {
			// get next sample from voice, it will be between -1 and 1, a signed percentage perhaps
			var sample:Float = voice.getSample(position);
			// it is a stream of samples so update position
			position++;

			// convert float to int
			var v = Std.int(sample * 0x7FFF);
			
			// buffer pair of bytes, compatible with 16 bit PCM format
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
