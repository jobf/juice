package juice.driver.lime;

import lime.media.openal.ALC;
import lime.utils.ArrayBufferView;
import lime.utils.ArrayBuffer;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import haxe.io.Float32Array;
import haxe.Timer;

import juice.AudioDriverContract;

@:publicFields
class AudioDriver extends AudioDriverContract {
	private var buffers:Array<ALBuffer>;
	private var alBufferSize:Int;
	private var alSource:ALSource;
	private var alSourceState:Int;
	private var timer:haxe.Timer;
	
	private var buffersProcessed:Int = 0;
	private var numChannels = 2;
	private var bufferCount:Int;
	private var isInitialized:Bool = false;
	private var interleavedBuf:Float32Array;

	function new(bufferSize:Int=1024){
		var device = ALC.getContextsDevice(ALC.getCurrentContext());
		var samplingRate = ALC.getIntegerv(device, ALC.FREQUENCY, 1)[0];
		super(samplingRate, bufferSize);
	}

	function init():Void {
		bufferCount = Std.int(Math.max(2, 2048 / bufferSize));
		buffers = AL.genBuffers(bufferCount);
		alSource = AL.createSource();
		
		#if (lime < "8.4.0")
		/* 
			disable hrtf to improve sound quality
			see https://github.com/openfl/lime/pull/2001
		*/
		if (AL.isExtensionPresent("AL_SOFT_direct_channels") && AL.isExtensionPresent("AL_SOFT_direct_channels_remix")) {
			static var DIRECT_CHANNELS_SOFT = 0x1033;
			static var REMIX_UNMATCHED_SOFT = 0x0002;
			AL.sourcei(alSource, DIRECT_CHANNELS_SOFT, REMIX_UNMATCHED_SOFT);
		}
		#end
		
		var frameCount = bufferSize * numChannels;
		alBufferSize = frameCount * 4;
		interleavedBuf = new Float32Array(alBufferSize);
		var interleavedView:lime.utils.Float32Array = lime.utils.Float32Array.fromBytes(interleavedBuf.view.buffer);
		var time = 1000 / 144;
		timer = new Timer(time);

		static var AL_FORMAT_STEREO_FLOAT32 = 0x10011;
		for (buffer in buffers) {
			AL.bufferData(buffer, AL_FORMAT_STEREO_FLOAT32, interleavedView, alBufferSize, samplingRate);
			AL.sourceQueueBuffer(alSource, buffer);
		}

		timer.run = () -> {
			alSourceState = AL.getSourcei(alSource, AL.SOURCE_STATE);

			var numBuffersFinished:Int = AL.getSourcei(alSource, AL.BUFFERS_PROCESSED);
			buffersProcessed += numBuffersFinished;

			if (numBuffersFinished > 0) {
				var finishedBuffers = AL.sourceUnqueueBuffers(alSource, numBuffersFinished);
				for (buffer in finishedBuffers) {
					if (isInitialized) {
						source.getAudioInterleaved(interleavedBuf, bufferSize);
					}
					AL.bufferData(buffer, AL_FORMAT_STEREO_FLOAT32, interleavedView, alBufferSize, samplingRate);
					AL.sourceQueueBuffer(alSource, buffer);
					samplesProcessed += bufferSize;
				}
			}

			// keep source playing in case it stopped (e.g. because window focus was lost and source queue was not replenished)
			if (isPlaying && alSourceState == AL.STOPPED) {
				AL.sourcePlay(alSource);
			}
		}
	}

	override function setSampleSource(source:ISampleSource) {
		super.setSampleSource(source);
		init();
		isInitialized = true;
	}

	function play():Void {
		AL.sourcePlay(alSource);
		isPlaying = true;
	}

	function stop():Void {
		AL.sourceStop(alSource);
		samplesProcessed = 0;
		isPlaying = false;
	}

	function pause():Void {
		if (!isPlaying) return;
		isPlaying = false;
		AL.sourcePause(alSource);
	}

	function resume():Void {
		if(isPlaying) return;
		AL.sourcePlay(alSource);
		isPlaying = true;
	}
}
