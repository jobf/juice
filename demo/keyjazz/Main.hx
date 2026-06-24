import haxe.io.Float32Array;
import lime.app.Application;
import peote.view.PeoteView;

#if js
import juice.driver.js.AudioDriver;
#else
import juice.driver.lime.AudioDriver;
#end
import juice.API;
import juice.stream.sine.SineStream;
import juice.stream.voice.VoiceStream;
import juice.voice.sampler.Sampler;
import penta.*;
import analyser.Oscilloscope;

class Main extends Application {
	
	var source:VoiceStream<Patch, Sampler>;
	var patch:Patch;
	var pentaView:PentaUI;
	var scope:Oscilloscope;

	override function onWindowCreate() {
		var pv = new PeoteView(window);

		var onActivate:PentaUI->Void = ui -> {

			var bufferSize:Int = 1024;
			var driver = initAudio(bufferSize);
			ui.source = source;
			ui.patch = patch;

			var oscHistorySeconds = 0.25;
			scope = new Oscilloscope(0, 0, window.width, window.height, driver.deviceSampleRate, oscHistorySeconds, pv);
			pv.addDisplay(scope, ui, true);

			// keep the scope fed with fresh samples
			var lastSamplesProcessed = -1;
			window.application.onUpdate.add(i -> {
				if (driver.samplesProcessed > lastSamplesProcessed) {
					lastSamplesProcessed = driver.samplesProcessed;
					scope.update(driver.buffer);
				}
			});

			// bind to keyboard events
			window.onKeyDown.add((code, modifier) -> pentaView.handleKey(code, true));
			window.onKeyUp.add((code, modifier) -> pentaView.handleKey(code, false));

			// setup is complete, show keyboard ui and start the driver
			ui.showKeyboard();
			driver.play();
		}

		pentaView = new PentaUI(0, 0, window.width, window.height, onActivate);
		pentaView.addToPeoteView(pv);
	}

	function initAudio(bufferSize:Int):AudioDriverBase {
		#if js
		var driver = AudioDriver.create(bufferSize);
		#else
		var driver = new AudioDriver(bufferSize);
		#end

		var numSamplers = 7;
		var voices = [for (n in 0...numSamplers) new Sampler()];
		source = new VoiceStream(voices);
		// reduce gain to prevent clipping on multipe voices
		source.gain = 0.7;
		driver.setSampleStream(source);

	/*
		SineStream computes a constant stream of samples from Math.sin which can be used by an audio driver directly.

		However, in this demo we are only using it to generate PCM data which we give to the Sampler voice.

		We use a different sample rate for generation to test that Sampler is correctly resampling to driver sample rate.
	*/
		
		// generate the sample for the patch which Sampler will play
		var testSampleRate = 24000;
		var sine = new SineStream(testSampleRate);
		// we generate 1 second - todo: test longer or shorter too ?
		var numSamples = testSampleRate;
		var left = new Float32Array(numSamples);
		var right = new Float32Array(numSamples);
		sine.getAudio(left, right);

		// init the Sampler patch
		patch = {
			samples: left,
			// samplesRight: // not used because we don't need a stereo sample here
			sampleRate: testSampleRate,
			rootFrequency: 440.0,
			loopEnd: numSamples,
			attack: 0.01,
			decay: 0.2,
			sustain: 0.7,
			release: 3.3
		};

		return driver;
	}
}
