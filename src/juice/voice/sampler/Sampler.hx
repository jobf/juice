package juice.voice.sampler;

import haxe.io.Float32Array;
import juice.API;

enum EnvelopeStage {
	Idle;
	Attack;
	Decay;
	Sustain;
	Release;
	Declick;
}

@:structInit
@:publicFields
class Patch {
	/* sample data to play mono, or left channel if stereo */
	var samples:Float32Array;

	/* sample data to play right channel if stereo */
	var samplesRight:Null<Float32Array> = null;

	/* hz the samples were recorded or generated at */
	var sampleRate:Float;

	/* hz at which samples plays when not pitched (for tuning) */
	var rootFrequency:Float;

	/* start of looped region. Works with loopEnd */
	var loopStart:Int = 0;

	/* end of looped region */
	var loopEnd:Int = 0;
	
	/* seconds to rise from silence to full level */
	var attack:Float;

	/* seconds to fall from full level to the sustain level */
	var decay:Float;

	/* level held for as long as the note stays on after decay */
	var sustain:Float;

	/* seconds to fall from the current level to silence after note-off */
	var release:Float;

	/* stereo panning, -1:left 1:right */
	var pan:Float = 0.0;
}

class Sampler implements IVoice<Patch> {
	// roughly -60dB, a conventional "silent" threshold
	static inline var silence = 1.0 / 1024.0;

	// number of samples to ramp to zero when ending a release
	static inline var declickSamples = 128;

	var deviceSampleRate:Float;

	var patch:Patch;
	var velocity:Float = 1.0;
	var pan:Float = 0.0;

	var position:Float = 0;
	var step:Float = 0;
	var loopStart:Int = 0;
	var loopEnd:Int = 0;

	var stage:EnvelopeStage = Idle;
	var envelopeLevel:Float = 0;
	var attackStep:Float = 0;
	var decayFactor:Float = 0;
	var releaseFactor:Float = 0;
	var declickStep:Float = 0;
	var declickRemaining:Int = 0;

	public function new() {}

	public function init(deviceSampleRate:Int) {
		this.deviceSampleRate = deviceSampleRate;
	}

	public function noteOn(patch:Patch, frequency:Float, velocity:Float):Void {
		this.patch = patch;
		this.velocity = velocity;
		this.pan = patch.pan;
		position = 0;
		step = (frequency / patch.rootFrequency) * (patch.sampleRate / deviceSampleRate);

		// loopStart and loopEnd work together to define a looped region
		// if both are zero then play through once and release
		loopEnd = patch.loopEnd > patch.samples.length ? patch.samples.length : patch.loopEnd;
		loopStart = patch.loopStart < 0 ? 0 : patch.loopStart > loopEnd ? loopEnd : patch.loopStart;
		
		decayFactor = exponentialFactor(patch.decay);
		releaseFactor = exponentialFactor(patch.release);

		if (patch.attack > 0) {
			stage = Attack;
			envelopeLevel = 0;
			attackStep = 1.0 / (patch.attack * deviceSampleRate);
		} else {
			stage = Decay;
			envelopeLevel = 1.0;
			attackStep = 0;
		}
	}

	public function noteOff():Void {
		if (stage != Idle && stage != Declick) {
			stage = Release;
		}
	}

	public function isActive():Bool {
		return stage != Idle;
	}

	public function isReleasing():Bool {
		return stage == Release || stage == Declick;
	}

	function exponentialFactor(time:Float):Float {
		var timeConstant = time / 5.0;
		return Math.exp(-1.0 / (timeConstant * deviceSampleRate));
	}

	function nextEnvelopeLevel():Float {
		return switch (stage) {
			case Attack:
				envelopeLevel += attackStep;
				if (envelopeLevel >= 1.0) {
					envelopeLevel = 1.0;
					stage = Decay;
				}
				// fast rise and slow finish curve (quadratic ease out)
				1.0 - (1.0 - envelopeLevel) * (1.0 - envelopeLevel);

			case Decay:
				envelopeLevel = patch.sustain + (envelopeLevel - patch.sustain) * decayFactor;
				if (Math.abs(envelopeLevel - patch.sustain) < silence) {
					envelopeLevel = patch.sustain;
					stage = Sustain;
				}
				envelopeLevel;

			case Sustain:
				envelopeLevel;

			case Release:
				envelopeLevel *= releaseFactor;
				if (envelopeLevel < silence) {
					declickStep = envelopeLevel / declickSamples;
					declickRemaining = declickSamples;
					stage = Declick;
				}
				envelopeLevel;

			case Declick:
				envelopeLevel -= declickStep;
				if (--declickRemaining <= 0) {
					envelopeLevel = 0;
					stage = Idle;
				}
				envelopeLevel;

			case Idle:
				0.0;
		}
	}

	public function render(out:StereoFrame):Void {
		if (stage == Idle) {
			out.left = out.right = 0.0;
			return;
		}

		var samples = patch.samples;
		var index = Std.int(position);
		if (index >= samples.length) {
			if (stage != Declick) {
				if (envelopeLevel < silence) {
					stage = Idle;
					out.left = out.right = 0.0;
					return;
				}
				declickStep = envelopeLevel / declickSamples;
				declickRemaining = declickSamples;
				stage = Declick;
			}
			position = samples.length - 1.0;
			index = samples.length - 1;
		}

		var frac = position - index;
		var level = nextEnvelopeLevel();
		var gain = level * velocity;

		var leftSample = interpolate(samples, index, frac, loopStart, loopEnd) * gain;
		var rightSample = patch.samplesRight != null ? interpolate(patch.samplesRight, index, frac, loopStart, loopEnd) * gain : leftSample;
		var leftGain = Math.sqrt((1.0 - pan) * 0.5);
		var rightGain = Math.sqrt((1.0 + pan) * 0.5);
		out.left = leftSample * leftGain;
		out.right = rightSample * rightGain;

		position += step;
		if (loopEnd > loopStart && position >= loopEnd) {
			var loopLen = loopEnd - loopStart;
			position = loopStart + (position - loopEnd) % loopLen;
		}
	}

	static inline function interpolate(samples:Float32Array, index:Int, frac:Float, loopStart:Int = -1, loopEnd:Int = -1):Float {
		var a = samples[index];
		var nextIndex = index + 1;
		if (loopEnd > loopStart && nextIndex >= loopEnd)
			nextIndex = loopStart;
		var b = nextIndex < samples.length ? samples[nextIndex] : a;
		return a + (b - a) * frac;
	}
}
