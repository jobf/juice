package ob.juice;

import haxe.io.Bytes;


class Tone {
	public var sampleData(default, null):Bytes;
	public var sampleRate(default, null):Int;

	var samplesPerCycle:Float;
	var amplitude:Int;
	var frequency:Float;

	public function new(frequency:Float, shape:WaveShape = SINE, amplitude:Int = 127, sampleRate:Int = 44100) {
		this.sampleRate = sampleRate;
		this.amplitude = amplitude;
		this.frequency = frequency;
		sampleData = Bytes.alloc(sampleRate);
		samplesPerCycle = sampleRate / frequency;
		switch shape {
			case SAW:
				generateSawWave();
			case PULSE:
				generatePulseWave();
			case _:
				generateSineWave();
		}
	}

	function generateSineWave() {
		for (pos in 0...sampleRate) {
			var value:Float = Math.sin(pos / samplesPerCycle * 2 * Math.PI) * amplitude;
			sampleData.set(pos, Std.int(value));
		}
	}

	function generateSawWave() {
		for (pos in 0...sampleRate) {
			var value:Float = (2 * (pos % samplesPerCycle) / (samplesPerCycle - 1)) * amplitude;
			sampleData.set(pos, Std.int(value));
		}
	}

	function generatePulseWave() {
		for (pos in 0...sampleRate) {
			var value:Float = Math.sin((pos) * Math.PI * 2 / sampleRate * frequency) > 0 ? amplitude : -amplitude;
			sampleData.set(pos, Std.int(value));
		}
	}
}

enum WaveShape {
	SINE;
	// TRI; todo
	PULSE;
	SAW;
}
