package juice;

import haxe.io.Float32Array;

@:publicFields
abstract class AudioDriverBase {

	var samplesProcessed:Int = 0;
	var samplingRate:Int;
	var stream:ISampleStream;

	var bufferSize:Int;
	var buffer:Float32Array;

	var isPlaying:Bool = false;
	var isPaused:Bool = false;

	function new(samplingRate:Int, bufferSize:Int=1024){
		this.samplingRate = samplingRate;
		this.bufferSize = bufferSize;
		this.buffer = new Float32Array(bufferSize * 2);
	}
	
	function setSampleStream(stream:ISampleStream){
		this.stream = stream;
		this.stream.init(samplingRate);
	};

	function renderBuffer():Void {
		stream.getAudioInterleaved(buffer, bufferSize);
	}

	abstract function play():Void;
	abstract function stop():Void;
	abstract function pause():Void;
	abstract function resume():Void;
}

interface ISampleStream {
	function init(sampleRate:Int):Void;
	function getAudioInterleaved(output:Float32Array, numSamples:Int):Void;
	// todo: remove getAudio or replace with abstract ?
	function getAudio(left:Float32Array, right:Float32Array, numSamples:Int):Void;
}
