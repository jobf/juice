import ob.juice.Buffer;
import ob.juice.Generator;
import sys.io.File;
import ob.juice.Wave.WaveFile;

#if !web
/** here we are testing the tone generation by writing the wav to disk **/
class Main {
	static public function main() {
		var envShape = {
			a: 0.5,
			d: 0.5,
			s: 0.5,
			r: 0.5
		};

		var frequency = 500;
		var noteLength = 2.0;

		for(waveShape in [SINE, TRI, PULSE, SAW]){
			var tone = new Tone(frequency, envShape, waveShape);

			var toneBuffer = new ToneBuffer(tone, noteLength);
			toneBuffer.bufferSamples();

			var filePath = '$waveShape.wav';
			var fileOutput = File.write(filePath, true);
			WaveFile.write(toneBuffer.sampleData, fileOutput);

			fileOutput.close();

			trace('wrote $filePath');
		};
	}
}
#end
