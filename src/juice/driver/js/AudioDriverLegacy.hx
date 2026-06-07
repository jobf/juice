package juice.driver.js;

import js.html.audio.AudioContext;
import js.html.audio.AudioProcessingEvent;
import js.html.audio.ScriptProcessorNode;
import juice.IAudioSource;

/*
	This IAudioDriver implementation can be used when https is not available.
*/
@:publicFields
class AudioDriverLegacy implements IAudioDriver {
	private var audioContext:AudioContext;
	private var scriptProcessor:ScriptProcessorNode;
	private var audioSource:IAudioSource;
	private var onaudioprocess:AudioProcessingEvent->Void;
	
	private var bufferSize:Int = 0;

	var isPlaying:Bool = false;
	var samplesProcessed:Int = 0;

	function new():Void {
		audioContext = new AudioContext();
		scriptProcessor = audioContext.createScriptProcessor(0, 0, 2);
		trace('info: using legacy web player');
	}

	function setAudioSource(audioSource:IAudioSource) {
		onaudioprocess = (event:AudioProcessingEvent) -> {
			if (isPlaying) {
				samplesProcessed += event.outputBuffer.length;
				var leftBuf:haxe.io.Float32Array = cast event.outputBuffer.getChannelData(0);
				var rightBuf:haxe.io.Float32Array = cast event.outputBuffer.getChannelData(1);
				audioSource.getAudio(leftBuf, rightBuf, event.outputBuffer.length);
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

	function getSamplingRate():Float {
		return audioContext.sampleRate;
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

	function getBufferSize():Int {
		return bufferSize;
	}

	function getSamplesProcessed():Int {
		return samplesProcessed;
	}
}
