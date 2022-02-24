import ob.juice.Buffer;
import ob.juice.Generator;
import sys.io.File;
import ob.juice.Wave.WaveFile;

#if !web
/** here we are testing the tone generation by writing the wav to disk **/
class Main {
	static public function main() {
		var tone = new Tone(660, {
			a: 0.5,
			d: 0.5,
			s: 0.5,
			r: 0.5
		});
		var toneBuffer = new ToneBuffer(tone, 2.0);
		toneBuffer.bufferSamples();

		var fileOutput = File.write('tone.wav', true);
		WaveFile.write(toneBuffer.sampleData, fileOutput);

		fileOutput.close();

		trace('wrote file');
	}
}
#end