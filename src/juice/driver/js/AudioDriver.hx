package juice.driver.js;

import haxe.io.Float32Array;
import juice.AudioDriverContract;
import juice.AudioDriverContract;
import juice.driver.js.AudioWorkletContext;
import js.html.Blob;
import js.html.URL;

@:publicFields
class AudioDriver extends AudioDriverContract {
	/** Creates the best available driver: AudioWorklet where supported, falling back to the legacy ScriptProcessor driver otherwise. **/
	static function create(bufferSize:Int=1024):AudioDriverContract {

		if(!isWorkletSupported()){
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

	private var isInitialized:Bool = false;
	private var moduleReady:js.lib.Promise<Void>;
	private var blobUrl:String;

	function new(bufferSize:Int=1024):Void {
		audioContext = new AudioWorkletContext();
		super(Std.int(audioContext.sampleRate), bufferSize);

		var blob = new Blob([Processor.code], {type: "application/javascript"});
		blobUrl = URL.createObjectURL(blob);
		moduleReady = audioContext.audioWorklet.addModule(blobUrl);
	}

	function initAudioWorkletNode() {
		// create the AudioWorkletNode
		node = new AudioWorkletNode(audioContext, 'audio-stream-processor', {
			// numberOfInputs: numberOfInputs,
			numberOfOutputs: 1,
			outputChannelCount: [2],
			// parameterData: parameterData,
			// processorOptions: processorOptions,
			// channelCount: channelCount,
			// channelCountMode: channelCountMode,
			// channelInterpretation: channelInterpretation
		});

		// practice good blob blobUrl hygiene ??
		URL.revokeObjectURL(blobUrl);

		// listen for messages from the processor (to tell us it's hungry)
		node.port.onmessage = event -> {
			if (event.data.type == 'dataRequest') {
				// Generate and send more data immediately
				if (isPlaying) {
					generateAndSendBuffer();
				}
			} else if (event.data.type == 'bufferStatus') {
				// debug
				// trace('Buffer queue: ${event.data.queueLength}, Samples: ${event.data.samplesProcessed}, Silent: ${event.data.silentSamples}');
			}
		}

		// connect to output
		node.connect(this.audioContext.destination);

		isInitialized = true;
		trace('audio-stream-processor initialized');
	}

	function generateAndSendBuffer() {
		var buffL = new Float32Array(bufferSize);
		var buffR = new Float32Array(bufferSize);
		source.getAudio(buffL, buffR, bufferSize);
		streamAudioData(buffL, buffR);
	}

	function streamAudioData(buffL:Float32Array, buffR:Float32Array) {
		if (audioContext.state == SUSPENDED) {
			trace('to do .. Resuming suspended audio context...');
			audioContext.resume();
		}

		node.port.postMessage({
			type: 'audioData',
			leftBuffer: buffL,
			rightBuffer: buffR,
		});
	}

	/* begin playback, starts requesting audio data */
	function play():Void {
		moduleReady.then(_ -> {
			if (node == null) {
				initAudioWorkletNode();
			}

			if (!isInitialized) {
				trace('AudioWorklet not initialized');
				return;
			}

			if (audioContext.state == SUSPENDED) {
				audioContext.resume();
			}

			isPlaying = true;
			node.port.postMessage({type: 'start'});
			trace('Audio playback started');
		});
	}

	/* stop playback completely, clears all buffers */
	function stop():Void {
		if (node == null) {
			return;
		}
		samplesProcessed = 0;
		isPlaying = false;
		node.port.postMessage({type: 'stop'});
		trace('Audio playback stopped');
	}

	/* pause playback, keeps buffers for seamless resume */
	function pause() {
		if (node == null) {
			return;
		}

		isPlaying = false;
		node.port.postMessage({type: 'pause'});
		trace('Audio playback paused');
	}

	/* resume from pause */
	function resume() {
		if (node == null) {
			return;
		}

		if (audioContext.state == SUSPENDED) {
			audioContext.resume();
		}

		isPlaying = true;
		node.port.postMessage({type: 'resume'});
		trace('Audio playback resumed');
	}

	override function setSampleSource(source:ISampleSource):Void {
		super.setSampleSource(source);
		isInitialized = true;
	}
}
