package juice.driver.lime;

import lime.utils.ArrayBufferView;
import lime.utils.ArrayBuffer;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import haxe.io.Float32Array;
import haxe.Timer;
import juice.IAudioSource;

@:publicFields
class AudioDriver implements IAudioDriver {
	private var audioSource:IAudioSource;
	private var buffers:Array<ALBuffer>;
	private var source:ALSource;
	private var timer:haxe.Timer;
	
	private var buffersProcessed:Int = 0;
	private var sampleRate:Int;
	private var numChannels = 2;
	private var bufferSize:Int;
	private var bufferCount:Int;
	private var isInitialized:Bool = false;
	private var interleavedBuf:Float32Array;

	var isPlaying:Bool = false;
	var samplesProcessed:Int = 0;

	function new(sampleRate:Int = 48000) {
		this.sampleRate = sampleRate;
	}

	function init():Void {
		bufferCount = 2;
		buffers = AL.genBuffers(bufferCount);
		source = AL.createSource();
		
		#if (lime < "8.4.0")
		/* 
			disable hrtf to improve sound quality
			see https://github.com/openfl/lime/pull/2001
		*/
		if (AL.isExtensionPresent("AL_SOFT_direct_channels") && AL.isExtensionPresent("AL_SOFT_direct_channels_remix")) {
			static var DIRECT_CHANNELS_SOFT = 0x1033;
			static var REMIX_UNMATCHED_SOFT = 0x0002;
			AL.sourcei(source, DIRECT_CHANNELS_SOFT, REMIX_UNMATCHED_SOFT);
		}
		#end

		var bufferSampleCount = 2048;
		bufferSize = bufferSampleCount * numChannels * 4;
		var bufferArraySize = Std.int(bufferSampleCount * 2);
		interleavedBuf = new Float32Array(bufferArraySize);
		var interleavedView:lime.utils.Float32Array = lime.utils.Float32Array.fromBytes(interleavedBuf.view.buffer);
		var time = 1000 / 144;
		timer = new Timer(time);

		static var AL_FORMAT_STEREO_FLOAT32 = 0x10011;
		for (buffer in buffers) {
			AL.bufferData(buffer, AL_FORMAT_STEREO_FLOAT32, interleavedView, bufferSize, sampleRate);
			AL.sourceQueueBuffer(source, buffer);
		}

		timer.run = () -> {
			var numBuffersFinished:Int = AL.getSourcei(source, AL.BUFFERS_PROCESSED);
			buffersProcessed += numBuffersFinished;

			if (numBuffersFinished > 0) {
				var finishedBuffers = AL.sourceUnqueueBuffers(source, numBuffersFinished);
				for (buffer in finishedBuffers) {
					if (isInitialized) {
						audioSource.getAudioInterleaved(interleavedBuf, bufferSampleCount);
					}
					AL.bufferData(buffer, AL_FORMAT_STEREO_FLOAT32, interleavedView, bufferSize, sampleRate);
					AL.sourceQueueBuffer(source, buffer);
					samplesProcessed += bufferSampleCount;
				}
			}
		}
	}

	function getSamplingRate():Float {
		return sampleRate;
	}

	function getSamplesProcessed():Int {
		return samplesProcessed;
	}

	function setAudioSource(audioSource:IAudioSource):Void {
		this.audioSource = audioSource;
		init();
		isInitialized = true;
	}

	function play():Void {
		AL.sourcePlay(source);
		isPlaying = true;
	}


	function stop():Void {
		AL.sourceStop(source);
		samplesProcessed = 0;
		isPlaying = false;
	}

	function pause():Void {
		if (!isPlaying) return;
		isPlaying = false;
		AL.sourcePause(source);
	}

	function resume():Void {
		if(isPlaying) return;
		AL.sourcePlay(source);
		isPlaying = true;
	}
}
