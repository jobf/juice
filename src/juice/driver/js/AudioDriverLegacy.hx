package juice.driver.js;

import js.html.audio.AudioContext;
import js.html.audio.AudioProcessingEvent;
import js.html.audio.ScriptProcessorNode;
import juice.AudioDriverContract;

/*
	This AudioDriver implementation can be used when https is not available.
*/
@:publicFields
class AudioDriverLegacy extends AudioDriverContract {
	private var audioContext:AudioContext;
	private var scriptProcessor:ScriptProcessorNode;
	private var onaudioprocess:AudioProcessingEvent->Void;

	function new(bufferSize:Int=1024){
		audioContext = new AudioContext();
		super(Std.int(audioContext.sampleRate), bufferSize);
		scriptProcessor = audioContext.createScriptProcessor(0, 0, 2);
		trace('info: using legacy web player');
	}

	override function setSampleSource(source:ISampleSource) {
		super.setSampleSource(source);
		onaudioprocess = (event:AudioProcessingEvent) -> {
			if (isPlaying) {
				samplesProcessed += event.outputBuffer.length;
				var leftBuf:haxe.io.Float32Array = cast event.outputBuffer.getChannelData(0);
				var rightBuf:haxe.io.Float32Array = cast event.outputBuffer.getChannelData(1);
				source.getAudio(leftBuf, rightBuf, event.outputBuffer.length);
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
		isPlaying = true;
		samplesProcessed = 0;
		scriptProcessor.onaudioprocess = onaudioprocess;
		scriptProcessor.connect(audioContext.destination);
	}

	function stop():Void {
		isPlaying = false;
		if (scriptProcessor.onaudioprocess != null) {
			scriptProcessor.disconnect(audioContext.destination);
			scriptProcessor.onaudioprocess = null;
		}
	}

	function pause() {
		isPlaying = false;
	}

	function resume() {
		isPlaying = true;
	}
}
