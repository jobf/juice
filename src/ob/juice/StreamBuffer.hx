package ob.juice;

import format.wav.Data;
import sys.io.File;
import format.wav.Reader;
import lime.utils.UInt8Array;
import lime.utils.ArrayBufferView;
import lime.media.openal.AL;
import haxe.io.Bytes;
import lime.media.openal.ALSource;

@:structInit
class StreamConfig {
	public var numSamplesInBuffer:Int = 8192;
	public var numBuffers:Int = 2;
	public var numChannels:Int = 1;
	public var sampleRate:Int = 44100;
	public var filePath:String;
}

class StreamBuffer {
	static var sizeOfShort:Int = 8;
	var waveData:WaveData;
	var buffers:Array<ALSource>;
	var frameSize:Int;
	var frameBuffer:ArrayBufferView;
	var currentBufferIndex:Int;
	var config:StreamConfig;
	var source:ALSource;

	public function new(config:StreamConfig) {
		this.config = config;
		waveData = new WaveData(config.filePath);
		source = AL.createSource();
		buffers = AL.genBuffers(config.numBuffers);
		frameSize = config.numSamplesInBuffer * config.numChannels * sizeOfShort;
		frameBuffer = new UInt8Array(frameSize);
	}

	public function start() {
		// rewind source position
		AL.sourceRewind(source);

		traceAlErrors();

		// clear buffer queue
		AL.sourcei(source, AL.BUFFER, 0);

		traceAlErrors();

		trace('setting up ${buffers.length} buffers');

		var offset = 0;
		for (i in 0...buffers.length) {
			// get data to give to buffer
			frameBuffer = UInt8Array.fromBytes(waveData.getNextSamples(config.numSamplesInBuffer));

			// feed the buffer
			AL.bufferData(buffers[i], waveData.format, frameBuffer, config.numSamplesInBuffer, config.sampleRate);
			offset += config.numSamplesInBuffer;

			traceAlErrors("tried to feed buffer");

			// queue the buffer
			AL.sourceQueueBuffer(source, buffers[i]);
			traceAlErrors("tried to queue buffer");
		}

		AL.sourcePlay(source);
		traceAlErrors("tried to play source");
	}

	function traceAlErrors(debug:String = "") {
		#if noaltrace
		return;
		#end
		var alErrorString = AL.getErrorString();
		var errorState = alErrorString.length == 0 ? "OK" : "ERROR";
		trace('$debug\nAL $errorState $alErrorString');
	}

	public function update() {
		var numBuffersToUnqueue = AL.getSourcei(source, AL.BUFFERS_PROCESSED);
		traceAlErrors("retrieved processed buffer count");

		if (numBuffersToUnqueue > 0) {
			// trace('numBuffersToUnqueue $numBuffersToUnqueue');
			var finishedBuffers = AL.sourceUnqueueBuffers(source, numBuffersToUnqueue);
			for (buffer in finishedBuffers) {
				// get data to give to buffer
				frameBuffer = UInt8Array.fromBytes(waveData.getNextSamples(config.numSamplesInBuffer));

				// feed the buffer
				AL.bufferData(buffer, waveData.format, frameBuffer, config.numSamplesInBuffer, config.sampleRate);

				// queue the buffer
				AL.sourceQueueBuffer(source, buffer);
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


}

class WaveData {
	var position:Int = 0;

	public var format(default, null):Int;

	var wave:WAVE;

	public function new(filePath:String) {
		position = 0;
		var input = File.read(filePath);
		var reader = new Reader(input);
		wave = reader.read();
		format = wave.header.channels == 1 ? determineMonoFormat() : determineStereoFormat();
		trace('wave format is ${StringTools.hex(format)}');
	}

	public function getNextSamples(numSamples:Int):Bytes {
		var sampleData = Bytes.alloc(numSamples);
		// trace('limit ${wave.data.length} : get $numSamples from $position');
		for (i in 0...numSamples) {
			sampleData.set(i, wave.data.get(position));
			position++;
			if(position >= wave.data.length){
				position = 0;
				// trace('reset position');
			}
		}
		return sampleData;
	}

	inline function determineMonoFormat():Int {
		return switch wave.header.bitsPerSample {
			case 8: AL.FORMAT_MONO8;
			case _: AL.FORMAT_MONO16;
		};
	}

	inline function determineStereoFormat():Int {
		return switch wave.header.bitsPerSample {
			case 8: AL.FORMAT_STEREO8;
			case _: AL.FORMAT_STEREO16;
		};
	}
}

