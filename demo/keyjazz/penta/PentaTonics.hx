package penta;

@:publicFields
class PentaTonics
{
	var rows = 4;
	var defaultRoot = 523.25; // C
	var currentScale(default, null):Scale;

	// major pentatonic: 1, 2, 3, 5, 6
	static var major:Array<Int> = [0, 2, 4, 7, 9];

	// minor pentatonic: 1, b3, 4, 5, b7
	static var minor:Array<Int> = [0, 3, 5, 7, 10];

	// suspended pentatonic (Egyptian): 1, 2, 4, 5, b7
	static var egyptian:Array<Int> = [0, 2, 5, 7, 10];

	// hirajoshi (Japanese): 1, 2, b3, 5, b6
	static var hirajoshi:Array<Int> = [0, 2, 3, 7, 8];

	// insen (Japanese): 1, b2, 4, 5, b7
	static var insen:Array<Int> = [0, 1, 5, 7, 10];

	var frequencies:Array<Float>;
	var scaleNavigator:Array<Scale>;
	var scaleIndex:Int;
	var currentRoot:Float;

	function new() {
		scaleNavigator = [MAJOR, MINOR, SUSPENDED, HIRAJOSHI, INSEN];
		frequencies = [for (i in 0...major.length * rows) 0.0];
		changeScale(MAJOR, defaultRoot);
	}

	function changeScale(choice:Scale, root:Float){
		scaleIndex = scaleNavigator.indexOf(choice);
		currentScale = choice;
		currentRoot = root;
		var scale = switch choice {
			case MAJOR: major;
			case MINOR: minor;
			case SUSPENDED: egyptian;
			case HIRAJOSHI: hirajoshi;
			case INSEN: insen;
		}
		var computed = octaveSplit(toFrequencies(scale, root), rows);
		for (i in 0...computed.length) {
			frequencies[i] = computed[i];
		}
	}

	function toFrequencies(scale:Array<Int>, root:Float):Array<Float> {
		return [for (semitone in scale) root * Math.pow(2, semitone / 12)];
	}

	function octaveSplit(baseRow:Array<Float>, rows:Int):Array<Float> {
		return [for (row in 0...rows) for (f in baseRow) f / Math.pow(2, row)];
	}

	public function incrementScale(direction:Int) {
		var wrapAt = scaleNavigator.length;
		var next = (((scaleIndex + direction) % wrapAt) + wrapAt) % wrapAt;
		changeScale(scaleNavigator[next], currentRoot);
	}
}

enum Scale
{
	MAJOR;
	MINOR;
	SUSPENDED;
	HIRAJOSHI;
	INSEN;
}