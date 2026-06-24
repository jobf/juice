package juice.stream.sine;

import haxe.io.Float32Array;
import juice.API;

/**
 * For testing with generated sine wave.
 */
class SineStream implements ISampleStream {
	var sampleRate(default, null):Float;
	var leftFreq:Float = 440;
	var rightFreq:Float = 220;
	var amplitude = 0.5;

	/** Absolute position in the stream, so phase is computed fresh from this rather than accumulated - no drift across long playback or buffer boundaries. */
	var sampleIndex:Int = 0;

	/** sampleRate here is only a placeholder for offline use - init() overwrites it with the real device rate for real time use */
	public function new(sampleRate:Float = 48000) {
		this.sampleRate = sampleRate;
	}

	public function init(deviceSampleRate:Int) {
		sampleRate = deviceSampleRate;
	}

	static final PI2 = 2.0 * Math.PI;

	public function getAudio(left:Float32Array, right:Float32Array):Void {
		var numSamples = left.length;
		for (i in 0...numSamples) {
			var t = (sampleIndex + i) / sampleRate;
			left[i] = Math.sin(PI2 * leftFreq * t) * amplitude;
			right[i] = Math.sin(PI2 * rightFreq * t) * amplitude;
		}
		sampleIndex += numSamples;
	}

	public function getAudioInterleaved(output:Float32Array):Void {
		var numSamples = output.length >> 1;
		for (i in 0...numSamples) {
			var t = (sampleIndex + i) / sampleRate;
			output[i * 2] = Math.sin(PI2 * leftFreq * t) * amplitude;
			output[i * 2 + 1] = Math.sin(PI2 * rightFreq * t) * amplitude;
		}
		sampleIndex += numSamples;
	}
}
