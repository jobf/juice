package ob.juice.haxe;

import haxe.io.Bytes;
import sys.io.File;
import format.wav.Data;
import format.wav.Reader;
import ob.juice.core.SampleSource;

class WaveFileSource extends SampleSource {

	var position:Int;
	var wave:WAVE;

	public function new(filePath:String) {
		position = 0;
		totalSamplesDelivered = 0;
		var input = File.read(filePath);
		var reader = new Reader(input);
		wave = reader.read();
		// trace('wave format is ${StringTools.hex(format)}');
	}

	public function bufferNextSamples(buffer:Bytes, numSamples:Int):Void {
		for (i in 0...numSamples) {
			buffer.set(i, wave.data.get(position));
			position++;
			if (position >= wave.data.length) {
				position = 0;
				// trace('reset position');
			}
		}
		totalSamplesDelivered += numSamples;
	}

	public function trigger():Void{
		position = 0;
	}

	public function get_numChannels():Int {
		return wave.header.channels;
	}

	public function get_bitsPerSample():Int {
		return wave.header.bitsPerSample;
	}

	public function get_bytesPerSample():Int {
		return 1;
	}

	public function get_sampleRate():Int {
		return wave.header.samplingRate;
	}

	public function get_totalSamplesDelivered():Int {
		return totalSamplesDelivered;
	}
}
