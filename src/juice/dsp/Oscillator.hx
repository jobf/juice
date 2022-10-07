package juice.dsp;

/**
	Functions for generating waveforms, not the most efficient.
**/
class Oscillator {
	public static inline function sine(frequencyHz:Float, position:Float, sampleRate:Float):Float {
		return Math.sin(2.0 * Math.PI * position * frequencyHz / sampleRate);
	}

	public static inline function triangle(frequencyHz:Float, position:Float, sampleRate:Float):Float {
		return Math.asin(sine(frequencyHz, position, sampleRate)) * (1.0 / Math.PI);
	}

	public static inline function pulse(frequencyHz:Float, position:Float, sampleRate:Float):Float {
		return Math.sin((position) * Math.PI * 2 / sampleRate * frequencyHz) > 0 ? 1.0 : -1.0;
	}

	public static inline function saw(frequencyHz:Float, position:Float, sampleRate:Float):Float {
		return (2 * (position % (sampleRate / frequencyHz)) / (sampleRate / frequencyHz) - 1);
	}
}

enum WaveShape {
	SINE;
	TRI;
	PULSE;
	SAW;
}
