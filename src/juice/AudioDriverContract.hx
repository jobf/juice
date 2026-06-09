package juice;

import haxe.io.Float32Array;

@:publicFields
abstract class AudioDriverContract {
	var isPlaying:Bool = false;
	var samplesProcessed:Int = 0;
	var samplingRate:Int;
	var bufferSize:Int;
	var source:ISampleSource;

	function new(samplingRate:Int, bufferSize:Int=1024){
		this.samplingRate = samplingRate;
		this.bufferSize = bufferSize;
	}
	function setSampleSource(source:ISampleSource){
		this.source = source;
		this.source.init(samplingRate);
	};

	abstract function play():Void;
	abstract function stop():Void;
	abstract function pause():Void;
	abstract function resume():Void;
}

interface ISampleSource {
	function init(sampleRate:Int):Void;
	function getAudio(left:Float32Array, right:Float32Array, numSamples:Int):Void;
	function getAudioInterleaved(output:Float32Array, numSamples:Int):Void;
}