package ob.juice;

enum WaveShape {
	SINE;
	TRI;
	PULSE;
	SAW;
}

class Oscillator {
	static inline function hzToAngularVelocity(hz:Float) {
		return hz * 2.0 * Math.PI;
	}

	public static inline function sine(frequencyHz:Float, time:Float):Float {
		return Math.sin(hzToAngularVelocity(frequencyHz) * time);
	}

	public static inline function triangle(frequencyHz:Float, time:Float):Float {
		return Math.asin(sine(frequencyHz, time)) * (2.0 / Math.PI);
	}

	public static inline function pulse(frequencyHz:Float, time:Float):Float {
		return sine(frequencyHz, time) > 0 ? 1.0 : -1.0;
	}

	public static inline function saw(frequencyHz:Float, time:Float):Float {
		return (2.0 / Math.PI) * (frequencyHz * Math.PI * (time % ( 1.0 / frequencyHz)) - (Math.PI / 2.0));
	}
}

typedef ADSR = {
	a:Float,
	d:Float,
	s:Float,
	r:Float
}

class Envelope {
	public var attackTimeSeconds:Float;
	public var decayTimeSeconds:Float;
	public var releaseTimeSeconds:Float;

	var amplitudeAtStart:Float;

	public var amplitudeAtSustain:Float;

	public var isOpen:Bool;

	var openedAtTime:Float;
	var closedAtTime:Float;

	public function new(shape:ADSR) {
		attackTimeSeconds = shape.a;
		decayTimeSeconds = shape.d;
		amplitudeAtStart = 1.0;
		amplitudeAtSustain = shape.s;
		releaseTimeSeconds = shape.r;
		isOpen = false;
		openedAtTime = 0;
		closedAtTime = 0;
	}

	public function open(time:Float):Void {
		isOpen = true;
		openedAtTime = time;
	}

	public function close(time:Float):Void {
		isOpen = false;
		closedAtTime = time;
	}

	// todo ! logarithmic
	public function getAmplitude(timeSeconds:Float):Float {
		var amplitude:Float = 0;

		if (isOpen) {
			var timeOpen = timeSeconds - openedAtTime;
			// attack
			if (timeOpen <= attackTimeSeconds) {
				amplitude = (timeOpen / attackTimeSeconds) * amplitudeAtStart;
			}
			// decay
			if (timeOpen > attackTimeSeconds && timeOpen <= (attackTimeSeconds + decayTimeSeconds)) {
				amplitude = ((timeOpen - attackTimeSeconds) / decayTimeSeconds * (amplitudeAtSustain - amplitudeAtStart)) + amplitudeAtStart;
			}
			// sustain
			if (timeOpen > attackTimeSeconds + decayTimeSeconds) {
				amplitude = amplitudeAtSustain;
			}
		} else {
			// release
			var timeClosed = timeSeconds - closedAtTime;
			amplitude = timeClosed / releaseTimeSeconds * (0.0 - amplitudeAtSustain) + amplitudeAtSustain;
		}

		return amplitude < 0.0001 ? 0.0 : amplitude;
	}
}

class Tone {
	public var amplitude:Float;
	public var frequency:Float;
	public var envelope(default, null):Envelope;

	var oscShape:WaveShape;

	public function new(frequency:Float, ampShape:ADSR, oscShape:WaveShape = SINE) {
		this.amplitude = 1.0;
		this.frequency = frequency;
		this.oscShape = oscShape;
		envelope = new Envelope(ampShape);
	}

	public function getSample(timeSeconds:Float):Float {
		var oscSample = switch oscShape {
			case PULSE: Oscillator.pulse(frequency, timeSeconds);
			case SAW: Oscillator.saw(frequency, timeSeconds);
			case TRI: Oscillator.triangle(frequency, timeSeconds);
			case SINE: Oscillator.sine(frequency, timeSeconds);
		};

		var envAmplitude = envelope.getAmplitude(timeSeconds);

		return oscSample * envAmplitude;
	}
}
