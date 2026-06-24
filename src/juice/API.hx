package juice;

import haxe.io.Float32Array;

@:publicFields
abstract class AudioDriverBase {

	final deviceSampleRate:Int;
	var stream:ISampleStream;
	var samplesProcessed:Int = 0;
	
	final bufferSize:Int;
	final buffer:Float32Array;

	var isPlaying:Bool = false;
	var isPaused:Bool = false;

	function new(deviceSampleRate:Int, bufferSize:Int=1024){
		this.deviceSampleRate = deviceSampleRate;
		this.bufferSize = bufferSize;
		this.buffer = new Float32Array(bufferSize * 2);
	}

	function setSampleStream(stream:ISampleStream){
		this.stream = stream;
		this.stream.init(deviceSampleRate);
	};

	function renderBuffer():Void {
		stream.getAudioInterleaved(buffer);
	}

	abstract function play():Void;
	abstract function stop():Void;
	abstract function pause():Void;
	abstract function resume():Void;
}

interface ISampleStream {
	function init(deviceSampleRate:Int):Void;

	/* interleaved left/right buffer - the sample count is output.length / 2 */
	function getAudioInterleaved(output:Float32Array):Void;

	// todo: remove getAudio or replace with abstract ?
	/* separate left/right buffers - the sample count must match */
	function getAudio(left:Float32Array, right:Float32Array):Void;
}

interface IVoice<Patch> {
	function init(deviceSampleRate:Int):Void;
	function noteOn(patch:Patch, frequency:Float, velocity:Float):Void;
	function noteOff():Void;
	function render(out:StereoFrame):Void;
	function isActive():Bool;
	function isReleasing():Bool;
}

@:structInit
@:publicFields
class StereoFrame {
	var left:Float = 0;
	var right:Float = 0;
}
