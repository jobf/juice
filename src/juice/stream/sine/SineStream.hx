package juice.stream.sine;

import haxe.io.Float32Array;
import juice.API;

/**
 * For testing with generated sine wave.
 */
class SineStream implements ISampleStream {
	var sampleRate:Float;
	var leftFreq:Float = 440;
	var rightFreq:Float = 220;
	var amplitude = 0.5;
	var leftPhase:Float = 0;
	var rightPhase:Float = 0;
	var sampleIndex:Int = 0;

	public function new() {}

	public function init(samplingRate:Int) {
		sampleRate = samplingRate;
	}

	var PI2 = 2.0 * Math.PI;

	public function getAudio(leftBuf:Float32Array, rightBuf:Float32Array, numSamples:Int):Void {
		var leftPhaseIncrement = (2 * Math.PI * leftFreq) / this.sampleRate;
		var rightPhaseIncrement = (2 * Math.PI * rightFreq) / this.sampleRate;

		for (i in 0...numSamples) {
			leftBuf[i] = Math.sin(this.leftPhase) * amplitude;
			rightBuf[i] = Math.sin(this.rightPhase) * amplitude;

			this.leftPhase += leftPhaseIncrement;
			this.rightPhase += rightPhaseIncrement;

			if (this.leftPhase > PI2)
				this.leftPhase -= PI2;
			if (this.rightPhase > PI2)
				this.rightPhase -= PI2;
		}
	}

	public function getAudioInterleaved(output:Float32Array, numSamples:Int):Void {
		var leftPhaseIncrement = (2 * Math.PI * leftFreq) / this.sampleRate;
		var rightPhaseIncrement = (2 * Math.PI * rightFreq) / this.sampleRate;

		for (i in 0...numSamples) {
			output[i * 2] = Math.sin(this.leftPhase) * amplitude;
			output[i * 2 + 1] = Math.sin(this.rightPhase) * amplitude;

			this.leftPhase += leftPhaseIncrement;
			this.rightPhase += rightPhaseIncrement;

			if (this.leftPhase > PI2)
				this.leftPhase -= PI2;
			if (this.rightPhase > PI2)
				this.rightPhase -= PI2;
		}
	}
}
