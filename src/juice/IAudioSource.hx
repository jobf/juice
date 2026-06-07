package juice;

import haxe.io.Float32Array;

interface IAudioSource {
	function getAudio(left:Float32Array, right:Float32Array, numSamples:Int):Void;
	function getAudioInterleaved(output:Float32Array, numSamples:Int):Void;
}
