package juice.dsp;

enum EgArState {
	Off;
	Attack;
	Release;
}

class EgAR {
	public var attackTime:Float = 0.001;
	public var releaseTime:Float = 1.5;

	var shouldStart:Bool = false;
	var amplitudeRamp:Ramp;
	var state:EgArState = Off;

	public function new(sampleRate:Int) {
		amplitudeRamp = {
			sampleRate: sampleRate,
		}
	}

	public function trigger(){
		shouldStart = true;
	}

	public function nextAmplitude():Float {
		switch state {
			case Off:
				if(shouldStart){
					shouldStart = false;
					state = Attack;
					amplitudeRamp.setRamp(1.0, attackTime);
				}
			case Attack:
				if(amplitudeRamp.isFinished()){
					state = Release;
					amplitudeRamp.setRamp(0.0001, releaseTime);
				}
			case Release:
				if(amplitudeRamp.isFinished()){
					state = Off;
				}
		}

		// in case of retrigger
		if(shouldStart){
			shouldStart = false;
			state = Attack;
			amplitudeRamp.setRamp(1.0, attackTime);
		}

		return amplitudeRamp.nextValue();
	}
}

@:structInit
class Ramp {
	var sampleRate:Int;
	var currentValue:Float = 0.0;
	var increment:Float = 0.0;
	var samplesRemaining:Int = 0;

	public function setRamp(targetvalue:Float, durationSeconds:Float):Void {
		increment = (targetvalue - currentValue) / (sampleRate * durationSeconds);
		samplesRemaining = Std.int(sampleRate * durationSeconds);
	}

	public function nextValue():Float {
		if (samplesRemaining > 0) {
			samplesRemaining--;
			currentValue += increment;
		}

		return currentValue;
	}

	public function isFinished() {
		return samplesRemaining <= 0;
	}
}
