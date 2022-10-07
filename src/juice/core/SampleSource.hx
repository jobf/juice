package juice.core;

import haxe.io.Bytes;

abstract class SampleSource {
	abstract public function bufferNextSamples(buffer:Bytes, numSamples:Int):Void;
	abstract public function trigger():Void;
	
	public var numChannels(get, null):Int;
	abstract function get_numChannels():Int;
	
	public var bitsPerSample(get, null):Int;
	abstract function get_bitsPerSample():Int;
	
	public var bytesPerSample(get, null):Int;
	abstract function get_bytesPerSample():Int;
	
	public var sampleRate(get, null):Int;
	abstract function get_sampleRate():Int;
	
	public var totalSamplesDelivered(get, null):Int;
	abstract function get_totalSamplesDelivered():Int;
}

@:structInit
class SourceConfig {
	public var numChannels:Int = 1;
	public var bitsPerSample:Int = 16;
	public var sampleRate:Int = 44100;
}
