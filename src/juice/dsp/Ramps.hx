package ob.juice.dsp;


class ExponentialRampGenerator {
	var samplesElapsed = 0;
	var samplesPerRamp:Int;
	
	public var value(default, null):Float;
	
	var valueMinimum:Float;
	var valueMaximum:Float;
	var decayScaler:Float;
	var direction:RampDirection;

	public function new(samplesPerSecond:Int, valueMinimum:Float, valueMaximum:Float, direction:RampDirection) {
		this.valueMinimum = valueMinimum;
		this.valueMaximum = valueMaximum;
		this.direction = direction;
		value = direction == INCREASE ? valueMinimum : valueMaximum;
		var sign = direction == INCREASE ? -1.0 : 1.0;
		decayScaler = Math.pow(0.01, 1.0 / samplesPerSecond) * sign;
		// trace('decayScaler $decayScaler');
	}

	public function trigger() {
		value = direction == INCREASE ? valueMinimum : valueMaximum;
	}

	public function processSample():Float {
		if (isFinished())
			return value;

		value *= decayScaler;

		if (direction == INCREASE) {
			if (value >= valueMaximum) {
				value = valueMaximum;
			}
		}
		else {
			if (value <= valueMinimum) {
				value = valueMinimum;
			}
		}
		// trace('decay $value');
		return value;
	}

	public function isFinished():Bool {
		return direction == INCREASE ? value >= valueMaximum : value <= valueMinimum;
	}

	public function setDuration(samplesPerSecond:Int, secondsPerRamp:Float) {
		samplesPerRamp = Std.int(secondsPerRamp * samplesPerSecond);
	}
}

enum RampDirection {
	INCREASE;
	DECREASE;
}