package ob.juice;

import ob.juice.Generator.Tone;
import haxe.io.Bytes;

class ToneBuffer {
	var tone:Tone;

	public var sampleData(default, null):Bytes;
	public var sampleRate(default, null):Int;

	var lengthInSamples:Int;
	var sampleLengthSeconds:Float;
	var timeSeconds:Float;
	var maximumSampleValue:Int;
	var bufferIndex:Int;
	var lengthInSeconds:Float;
	var releaseAtTime:Float;

	public function new(tone:Tone, sampleRate:Int = 44100, holdTimeSeconds:Float) {
		this.tone = tone;
		this.sampleRate = sampleRate;
		this.lengthInSeconds = holdTimeSeconds + tone.envelope.releaseTimeSeconds;
		this.lengthInSamples = Math.ceil(sampleRate * lengthInSeconds);
		this.sampleData = Bytes.alloc(lengthInSamples);
		this.releaseAtTime = holdTimeSeconds;
		this.sampleLengthSeconds = 1.0 / sampleRate;
		this.timeSeconds = 0;
		this.bufferIndex = 0;
		this.maximumSampleValue = 127; // todo ? make this configurable e.g. for lower bit fidelity
	}

	public function bufferSamples() {
		tone.envelope.open(timeSeconds);

		while (timeSeconds < lengthInSeconds) {
			if (timeSeconds > releaseAtTime && tone.envelope.isOpen) {
				tone.envelope.close(timeSeconds);
			}

			var toneSample = tone.getSample(timeSeconds);
			var sample = Std.int(toneSample * maximumSampleValue);
			sampleData.set(bufferIndex, sample);

			timeSeconds += sampleLengthSeconds;
			bufferIndex++;
		}
	}
}
