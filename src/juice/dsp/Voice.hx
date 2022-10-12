package juice.dsp;

import juice.dsp.Envelopes;
import juice.dsp.Oscillator;

class Voice {
	public var amplitude:Float;
	public var frequency:Float;

	var sampleRate:Float;
	var oscShape:WaveShape;
	var nextFrequency:(frequency:Float, timeSeconds:Float) -> Float;
	var eg:EgAR;

	public function new(frequency:Float, decayLengthSeconds:Float, sampleRate:Int, oscShape:WaveShape = SINE) {
		this.amplitude = 1.0;
		this.frequency = frequency;
		this.oscShape = oscShape;
		this.sampleRate = sampleRate;

		nextFrequency = switch oscShape {
			case PULSE: (frequency:Float, timeSeconds:Float) -> Oscillator.pulse(frequency, timeSeconds, sampleRate);
			case SAW: (frequency:Float, timeSeconds:Float) -> Oscillator.saw(frequency, timeSeconds, sampleRate);
			case TRI: (frequency:Float, timeSeconds:Float) -> Oscillator.triangle(frequency, timeSeconds, sampleRate);
			case SINE: (frequency:Float, timeSeconds:Float) -> Oscillator.sine(frequency, timeSeconds, sampleRate);
		};

		eg = new EgAR(sampleRate);
		eg.releaseTime = 3.0;
	}

	public function trigger() {
		eg.trigger();
	}

	public function getSample(position:Float):Float {
		var oscSample = nextFrequency(frequency, position);
		var envAmplitude =  eg.nextAmplitude();
		return oscSample * envAmplitude;
	}
}
