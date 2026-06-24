package penta;

import lime.ui.KeyCode;

@:publicFields
class PentaKeys {

	var azqwerty:Array<KeyCode> = [
		KeyCode.NUMBER_5,	KeyCode.NUMBER_6,	KeyCode.NUMBER_7,	KeyCode.NUMBER_8,	KeyCode.NUMBER_9,
		KeyCode.R,			KeyCode.T,			KeyCode.Y,			KeyCode.U,			KeyCode.I,
		KeyCode.D,			KeyCode.F,			KeyCode.G,			KeyCode.H,			KeyCode.J,
		KeyCode.X,			KeyCode.C,			KeyCode.V,			KeyCode.B,			KeyCode.N
	];
	
	var colemak:Array<KeyCode> = [
		KeyCode.NUMBER_5,	KeyCode.NUMBER_6,	KeyCode.NUMBER_7,	KeyCode.NUMBER_8,	KeyCode.NUMBER_9,
		KeyCode.P,			KeyCode.G,			KeyCode.J,			KeyCode.L,			KeyCode.U,
		KeyCode.S,			KeyCode.T,			KeyCode.D,			KeyCode.H,			KeyCode.N,
		KeyCode.X,			KeyCode.C,			KeyCode.V,			KeyCode.B,			KeyCode.K
	];
	
	var dvorak:Array<KeyCode> = [
		KeyCode.NUMBER_5,	KeyCode.NUMBER_6,	KeyCode.NUMBER_7,	KeyCode.NUMBER_8,	KeyCode.NUMBER_9,
		KeyCode.P,			KeyCode.Y,			KeyCode.F,			KeyCode.G,			KeyCode.C,
		KeyCode.E,			KeyCode.U,			KeyCode.I,			KeyCode.D,			KeyCode.H,
		KeyCode.Q,			KeyCode.J,			KeyCode.K,			KeyCode.X,			KeyCode.B
	];
	
	var qwertz:Array<KeyCode> = [
		KeyCode.NUMBER_5,	KeyCode.NUMBER_6,	KeyCode.NUMBER_7,	KeyCode.NUMBER_8,	KeyCode.NUMBER_9,
		KeyCode.R,			KeyCode.T,			KeyCode.Z,			KeyCode.U,			KeyCode.I,
		KeyCode.D,			KeyCode.F,			KeyCode.G,			KeyCode.H,			KeyCode.J,
		KeyCode.X,			KeyCode.C,			KeyCode.V,			KeyCode.B,			KeyCode.N
	];

	var keymap:Map<KeyCode, Int>;

	var layout:Array<KeyCode>;
	var layouts = [ 
		"AZERTY",
		"QWERTY",
		"QWERTZ",
		"DVORAK",
		"COLEMAK",
	];

	function fromLayout(layout:Array<KeyCode>):Map<KeyCode, Int>
	{
		return [for (index => key in layout) key => index];
	}

	function new() {
		
	}

	public function chooseLayout(choice:String) {
		layout = switch choice {
			case "QWERTZ": qwertz;
			case "DVORAK": dvorak;
			case "COLEMAK": colemak;
			case _: azqwerty;
		}
		keymap = fromLayout(layout);
	}
}
