package juice.driver.js;

import js.html.audio.AudioContext;
import js.html.audio.AudioProcessingEvent;
import js.html.audio.ScriptProcessorNode;
import juice.API;

/*
	This AudioDriver implementation can be used when https is not available.
*/
@:publicFields
class AudioDriverLegacy extends AudioDriverBase {
	private var audioContext:AudioContext;
	private var scriptProcessor:ScriptProcessorNode;
	private var onaudioprocess:AudioProcessingEvent->Void;

	function new(bufferSize:Int=1024){
		audioContext = new AudioContext();
		super(Std.int(audioContext.sampleRate), bufferSize);
		scriptProcessor = audioContext.createScriptProcessor(bufferSize, 0, 2);
		trace('info: using legacy audio driver!');
	}

	override function setSampleStream(stream:ISampleStream) {
		super.setSampleStream(stream);
		onaudioprocess = (event:AudioProcessingEvent) -> {
			if (isPlaying) {
				renderBuffer();
				var leftBuf:haxe.io.Float32Array = cast event.outputBuffer.getChannelData(0);
				var rightBuf:haxe.io.Float32Array = cast event.outputBuffer.getChannelData(1);
				for (i in 0...bufferSize) {
					leftBuf[i] = buffer[i * 2];
					rightBuf[i] = buffer[i * 2 + 1];
				}
				samplesProcessed += bufferSize;
			} else {
				// Fill with silence when stopped
				var leftBuf:haxe.io.Float32Array = cast event.outputBuffer.getChannelData(0);
				var rightBuf:haxe.io.Float32Array = cast event.outputBuffer.getChannelData(1);
				for (i in 0...leftBuf.length) {
					leftBuf[i] = 0;
					rightBuf[i] = 0;
				}
			}
		}
	}

	function play():Void {
		if (audioContext.state == SUSPENDED) {
			audioContext.resume();
		}

		isPlaying = true;
		isPaused = false;
		samplesProcessed = 0;
		scriptProcessor.onaudioprocess = onaudioprocess;
		scriptProcessor.connect(audioContext.destination);
	}

	function stop():Void {
		if (scriptProcessor.onaudioprocess != null) {
			scriptProcessor.disconnect(audioContext.destination);
			scriptProcessor.onaudioprocess = null;
		}
		isPlaying = false;
	}

	function pause() {
		isPaused = true;
		audioContext.suspend();
	}

	function resume() {
		if (audioContext.state == SUSPENDED) audioContext.resume();
		isPaused = false;
	}
}
