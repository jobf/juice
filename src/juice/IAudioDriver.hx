package juice;

import juice.IAudioSource;

interface IAudioDriver {
	var isPlaying:Bool;
	var samplesProcessed:Int;
	function getSamplingRate():Float;
	function getSamplesProcessed():Int;
	function play():Void;
	function stop():Void;
	function pause():Void;
	function resume():Void;
	function setAudioSource(source:IAudioSource):Void;
}
