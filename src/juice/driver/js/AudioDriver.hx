package juice.driver.js;

import haxe.io.Float32Array;
import js.html.Blob;
import js.html.URL;
import juice.driver.js.AudioWorkletContext;
import juice.API;

@:publicFields
class AudioDriver extends AudioDriverBase {
	/** Creates the best available driver: AudioWorklet where supported, falling back to the legacy ScriptProcessor driver otherwise. **/
	static function create(bufferSize:Int = 1024):AudioDriverBase {

		if (!isWorkletSupported()) {
			// use AudioProcessingEvent for streaming audio data, does not require https at all
			return new AudioDriverLegacy(bufferSize);
		}

		// use AudioWorklet for streaming audio data, requires https when not running locally
		return new AudioDriver(bufferSize);
	}

	private static function isWorkletSupported():Bool {
		return Reflect.hasField(js.Browser.window, "AudioWorkletNode");
	}

	private var audioContext:AudioWorkletContext;
	private var node:AudioWorkletNode;
	private var modulePromise:js.lib.Promise<Void>;

	function new(bufferSize:Int = 1024):Void {
		audioContext = new AudioWorkletContext();
		super(Std.int(audioContext.sampleRate), bufferSize);

		var blob = new Blob([Processor.code], {type: "application/javascript"});
		var blobUrl = URL.createObjectURL(blob);

		modulePromise = audioContext.audioWorklet.addModule(blobUrl);
		modulePromise.catchError(error -> trace(error));
		// modulePromise.finally(() -> URL.revokeObjectURL(blobUrl));
	}

	function initAudioWorkletNode() {
		if (node != null) return;

		node = new AudioWorkletNode(audioContext, 'audio-stream-processor', {
			// numberOfInputs: numberOfInputs,
			numberOfOutputs: 1,
			outputChannelCount: [2],
			// parameterData: parameterData,
			processorOptions: {bufferSize: bufferSize},
			// channelCount: channelCount,
			// channelCountMode: channelCountMode,
			// channelInterpretation: channelInterpretation
		});

		// listen for messages from the processor (to tell us it's hungry)
		node.port.onmessage = event -> {
			if (event.data.type == 'stream.buffer.request') {
				if (isPlaying) {
					generateAndSendBuffer();
					samplesProcessed += bufferSize;
				}
			}

			// // debug (see Processor.js line 84)
			// if (event.data.type == 'bufferStatus') {
			// 	trace('bufferStatus queueLength: ${event.data.queueLength}, samplesProcessed: ${event.data.samplesProcessed}, silentSamples: ${event.data.silentSamples}');
			// }
		}

		// connect to output
		node.connect(this.audioContext.destination);

		trace('audio-stream-processor initialized');
	}

	function generateAndSendBuffer() {
		renderBuffer();
		var buffL = new Float32Array(bufferSize);
		var buffR = new Float32Array(bufferSize);
		for (i in 0...bufferSize) {
			buffL[i] = buffer[i * 2];
			buffR[i] = buffer[i * 2 + 1];
		}
		streamAudioData(buffL, buffR);
	}

	function streamAudioData(buffL:Float32Array, buffR:Float32Array) {
		if (audioContext.state == SUSPENDED) {
			trace('to do .. Resuming suspended audio context...');
			audioContext.resume();
		}

		node.port.postMessage({
			type: 'stream.buffer.data',
			leftBuffer: buffL,
			rightBuffer: buffR,
		});
	}

	/* begin stream, starts requesting audio data */
	function play():Void {
		modulePromise.then(_ -> {
			if (node == null)
				initAudioWorkletNode();
			if (audioContext.state == SUSPENDED) {
				audioContext.resume();
			}
			isPlaying = true;
			isPaused = false;
			samplesProcessed = 0;
			node.port.postMessage({type: 'stream.play'});
			trace('Audio stream started');
		});
	}

	/* stop stream completely, clears all buffers */
	function stop():Void {
		if (node == null) {
			return;
		}
		isPlaying = false;
		node.port.postMessage({type: 'stream.stop'});
		trace('Audio stream stopped');
	}

	/* pause stream, keeps buffers for seamless resume */
	function pause() {
		if (node == null) {
			return;
		}

		isPaused = true;
		node.port.postMessage({type: 'stream.pause'});
		trace('Audio stream paused');
	}

	/* resume from pause */
	function resume() {
		if (node == null || audioContext == null) {
			return;
		}

		if (audioContext.state == SUSPENDED) {
			audioContext.resume();
		}

		isPaused = false;
		node.port.postMessage({type: 'stream.resume'});
		trace('Audio stream resumed');
	}

	override function setSampleStream(stream:ISampleStream):Void {
		super.setSampleStream(stream);
	}
}
