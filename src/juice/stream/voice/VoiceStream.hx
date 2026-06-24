package juice.stream.voice;

import haxe.io.Float32Array;
import juice.API;

class VoiceStream<Patch, Voice:IVoice<Patch>> implements ISampleStream {
	final voices:Array<Voice>;

	final generation:Array<Int>;
	final voiceFrame:StereoFrame;
	final mixFrame:StereoFrame;
	final replacementFadeSamples = 64;
	final replacementFade:Array<Int>;
	final replacementPatch:Array<Null<Patch>>;
	final replacementFrequency:Array<Float>;
	final replacementVelocity:Array<Float>;

	var nextVoice:Int = 0;

	public var stealOnOverflow:Bool;
	public var gain:Float = 1.0;

	public function new(voices:Array<Voice>, stealOnOverflow:Bool = true) {
		this.voices = voices;
		this.stealOnOverflow = stealOnOverflow;
		this.generation = [for (n in voices) 0];
		this.replacementFade = [for (n in voices) 0];
		this.replacementPatch = [for (n in voices) null];
		this.replacementFrequency = [for (n in voices) 0.0];
		this.replacementVelocity = [for (n in voices) 0.0];
		this.voiceFrame = {};
		this.mixFrame = {};
	}

	public function init(deviceSampleRate:Int) {
		for (voice in voices) {
			voice.init(deviceSampleRate);
		}
	}

	public function noteOn(patch:Patch, frequency:Float, velocity:Float):Int {
		var index = findVoice();
		if (index < 0)
			return -1;

		generation[index]++;
		if (voices[index].isActive()) {
			if (replacementFade[index] == 0) {
				replacementFade[index] = replacementFadeSamples;
			}
			replacementPatch[index] = patch;
			replacementFrequency[index] = frequency;
			replacementVelocity[index] = velocity;
		} else {
			replacementFade[index] = 0; // clear any stale steal state
			voices[index].noteOn(patch, frequency, velocity);
		}
		return toHandle(index, generation[index]);
	}

	public function noteOff(handle:Int):Void {
		if (handle < 0)
			return;

		var index = indexFromHandle(handle);
		if (generation[index] == generationFromHandle(handle)) {
			voices[index].noteOff();
		}
	}

	function findVoice():Int {
		var start = nextVoice;
		var releasingIndex = -1;
		for (offset in 0...voices.length) {
			var index = (start + offset) % voices.length;
			if (!voices[index].isActive()) {
				nextVoice = (index + 1) % voices.length;
				return index;
			}
			if (releasingIndex < 0 && voices[index].isReleasing()) {
				releasingIndex = index;
			}
		}

		if (!stealOnOverflow)
			return -1;

		// prefer stealing a voice that's already been released
		if (releasingIndex >= 0) {
			nextVoice = (releasingIndex + 1) % voices.length;
			return releasingIndex;
		}

		// every voice is held so steal the oldest
		nextVoice = (start + 1) % voices.length;
		return start;
	}

	inline function toHandle(index:Int, gen:Int):Int {
		return gen * voices.length + index;
	}

	inline function indexFromHandle(handle:Int):Int {
		return handle % voices.length;
	}

	inline function generationFromHandle(handle:Int):Int {
		return Std.int(handle / voices.length);
	}

	public function getAudio(left:Float32Array, right:Float32Array):Void {
		for (i in 0...left.length) {
			mixNextFrame();
			left[i] = mixFrame.left;
			right[i] = mixFrame.right;
		}
	}

	public function getAudioInterleaved(output:Float32Array):Void {
		var numSamples = output.length >> 1;
		for (i in 0...numSamples) {
			mixNextFrame();
			output[i * 2] = mixFrame.left;
			output[i * 2 + 1] = mixFrame.right;
		}
	}

	inline function mixNextFrame():Void {
		mixFrame.left = 0;
		mixFrame.right = 0;

		for (i in 0...voices.length) {
			var voice = voices[i];
			var active = voice.isActive();
			if (!active && replacementFade[i] == 0)
				continue;

			voice.render(voiceFrame);
			if (replacementFade[i] > 0) {
				var scale = (replacementFade[i] : Float) / replacementFadeSamples;
				voiceFrame.left *= scale;
				voiceFrame.right *= scale;
				if (--replacementFade[i] == 0) {
					voice.noteOn(replacementPatch[i], replacementFrequency[i], replacementVelocity[i]);
				}
			}
			mixFrame.left += voiceFrame.left;
			mixFrame.right += voiceFrame.right;
		}

		mixFrame.left = softClip(mixFrame.left * gain);
		mixFrame.right = softClip(mixFrame.right * gain);
	}

	// soften hard clipping by rounding off the peaks
	inline function softClip(x:Float):Float {
		if (x <= -1.0) {
			return -2.0 / 3.0;
		}
		if (x >= 1.0) {
			return 2.0 / 3.0;
		}
		return x - x * x * x / 3.0;
	}
}
