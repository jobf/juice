package ob.juice.lime;

import haxe.io.Bytes;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.utils.ArrayBufferView;
import lime.utils.Int32Array;
import ob.juice.core.SampleSource;

@:structInit
class StreamConfig {
	public var numSamplesInBuffer:Int = 4096 * 2;
	public var numBuffers:Int = 4;
}

class StreamBuffer {
	var samples:SampleSource;
	var buffers:Array<ALSource>;
	var data:Bytes;
	var bufferView:ArrayBufferView;
	var bufferViewSize:Int;
	var currentBufferIndex:Int;
	var config:StreamConfig;
	var source:ALSource;
	var format:Int;

	public function new(config:StreamConfig, samples:SampleSource) {
		this.config = config;
		this.samples = samples;
		format = samples.numChannels == 1 ? determineMonoFormat(samples.bitsPerSample) : determineStereoFormat(samples.bitsPerSample);
		source = AL.createSource();
		buffers = AL.genBuffers(config.numBuffers);

		data = Bytes.alloc(config.numSamplesInBuffer << 1);
		bufferView = new Int32Array(data);
		var isWaveFile = true;
		bufferViewSize = config.numSamplesInBuffer * samples.bytesPerSample;
	}

	public function start() {
		// rewind source position
		AL.sourceRewind(source);

		traceAlErrors();

		// clear buffer queue
		AL.sourcei(source, AL.BUFFER, 0);

		traceAlErrors();
		// trace('setting up ${buffers.length} buffers');

		for (buffer in buffers) {
			bufferNextSamples(buffer);
		}

		AL.sourcePlay(source);
		traceAlErrors("tried to play source");
	}

	function traceAlErrors(debug:String = "") {
		#if !noaltrace
		return;
		#end
		var alErrorString = AL.getErrorString();
		var errorState = alErrorString.length == 0 ? "OK" : "ERROR";
		trace('$debug\nAL $errorState $alErrorString');
	}

	inline function determineMonoFormat(bitsPerSample:Int):Int {
		return switch bitsPerSample {
			case 8: AL.FORMAT_MONO8;
			case _: AL.FORMAT_MONO16;
		};
	}

	inline function determineStereoFormat(bitsPerSample:Int):Int {
		return switch bitsPerSample {
			case 8: AL.FORMAT_STEREO8;
			case _: AL.FORMAT_STEREO16;
		};
	}

	public function update() {
		var numBuffersToUnqueue = AL.getSourcei(source, AL.BUFFERS_PROCESSED);
		traceAlErrors("retrieved processed buffer count");

		if (numBuffersToUnqueue > 0) {
			// trace('numBuffersToUnqueue $numBuffersToUnqueue');
			var finishedBuffers = AL.sourceUnqueueBuffers(source, numBuffersToUnqueue);
			for (buffer in finishedBuffers) {
				bufferNextSamples(buffer);
			}
		}

		// If there was a buffer underrun OpenAL can unexpectedly stop the playback
		// so we check if the source has stopped but should still be playing
		// then start playback if necessary
		var state = AL.getSourcei(source, AL.SOURCE_STATE);
		var isStopped = state != AL.PLAYING && state != AL.PAUSED;
		if (isStopped) {
			// if no buffers are queued, playback is finished
			var queued = AL.getSourcei(source, AL.BUFFERS_QUEUED);
			var isFinished = queued == 0;
			if (isFinished) {
				trace('playback ended');
				return;
			}

			// otherwise start playing
			AL.sourcePlay(source);
			trace('playback recovered from underrun');
		}
	}

	function bufferNextSamples(buffer:ALBuffer) {
		
		// get data to give to buffer
		samples.bufferNextSamples(data, config.numSamplesInBuffer);
		
		/*
			notes regarding data we pass to AL.bufferData data:ArrayBufferView...
			
			8-bit PCM data is expressed as an unsigned value over the range 0 to 255,
			128 being an audio output level of zero.
			
			16-bit PCM data is expressed as a signed value over the range -32768 to 32767,
			0 being an audio output level of zero.
			
			Stereo data is expressed in interleaved format,
			left channel first.
		*/

		// feed the buffer
		AL.bufferData(buffer, format, bufferView, bufferViewSize, samples.sampleRate);
		traceAlErrors("tried to feed buffer");

		// queue the buffer
		AL.sourceQueueBuffer(source, buffer);
		traceAlErrors("tried to queue buffer");
	}

	public inline function getCurrentTime():Float {
		var soundFileTime:Int = samples.totalSamplesDelivered;
		var alSamplesOffset = AL.getSourcei(source, AL.SAMPLE_OFFSET);
		return (soundFileTime + alSamplesOffset) / samples.sampleRate;
	}

}