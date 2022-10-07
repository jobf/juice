package ob.juice.dsp;

import ob.juice.dsp.Ramps;
import ob.juice.dsp.Oscillator;

class Voice {
	public var amplitude:Float;
	public var frequency:Float;

	var sampleRate:Float;
	var oscShape:WaveShape;
	var oscillator:(frequency:Float, timeSeconds:Float) -> Float;
	var decayRamp:ExponentialRampGenerator;

	public function new(frequency:Float, decayLengthSeconds:Float, sampleRate:Int, oscShape:WaveShape = SINE) {
		this.amplitude = 1.0;
		this.frequency = frequency;
		this.oscShape = oscShape;
		this.sampleRate = sampleRate;

		var decayMinimum = 0.0001;
		var decayMaximum = 1.0;
		decayRamp = new ExponentialRampGenerator(sampleRate, decayMinimum, decayMaximum, DECREASE);

		oscillator = switch oscShape {
			case PULSE: (frequency:Float, timeSeconds:Float) -> Oscillator.pulse(frequency, timeSeconds, sampleRate);
			case SAW: (frequency:Float, timeSeconds:Float) -> Oscillator.saw(frequency, timeSeconds, sampleRate);
			case TRI: (frequency:Float, timeSeconds:Float) -> Oscillator.triangle(frequency, timeSeconds, sampleRate);
			case SINE: (frequency:Float, timeSeconds:Float) -> Oscillator.sine(frequency, timeSeconds, sampleRate);
		};
	}

	public function trigger() {
		decayRamp.trigger();
	}

	public function getSample(position:Float):Float {
		// var oscSample = Math.sin(2.0 * Math.PI * position * frequency / sampleRate);
		var oscSample = oscillator(frequency, position);

		var envAmplitude = decayRamp.processSample();
		return oscSample * envAmplitude;
	}
}
