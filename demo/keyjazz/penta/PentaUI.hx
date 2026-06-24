package penta;

import juice.stream.voice.VoiceStream;
import juice.voice.sampler.Sampler;
import lime.ui.KeyCode;
import lime.ui.Window;
import peote.view.Buffer;
import peote.view.Display;
import peote.view.element.Elem;
import peote.view.PeoteView;
import peote.view.Program;
import peote.view.text.Text;
import peote.view.text.TextOptions;
import peote.view.text.TextProgram;

@:publicFields
class PentaUI extends Display {
	var COLUMNS = 5;
	var HIGH_FREQUENCY_INDEX = 5;
	var LOUDNESS_COMPENSATION = 0.4;
	var MAX_LOUDNESS_BOOST = 4.0;
	var MAX_PAN = 0.85;

	var skinBuffer:Buffer<Elem>;
	var skinProgram:Program;
	var textProgram:TextProgram;
	var headerText:Text;
	var footerText:Text;
	var keyTexts:Array<Text>;
	var displayWidthMid:Float;
	var displayHeightMid:Float;
	var textOptions:TextOptions;
	var onActivate:PentaUI->Void;
	var source:VoiceStream<Patch, Sampler>;
	var patch:Patch;
	var heldNotes:Map<Int, Int> = [];
	var state:State = CHOOSE_LAYOUT;
	var keys:PentaKeys;
	var tonics:PentaTonics;

	var buttons:Array<Button> = [];
	var buffer:Buffer<Elem>;
	var buttonUnderMouse:Button;
	var buttonPressedByMouse:Button;
	var isMouseDown:Bool = false;
	var controlKeymap:Map<KeyCode, Button> = new Map();
	var keyPressOffset = 6;
	var letterSizeHelp:Int;
	var letterSizeButton:Int;

	function new(x:Int, y:Int, w:Int, h:Int, onActivate:PentaUI->Void) {
		super(x, y, w, h);
		this.onActivate = onActivate;
		keys = new PentaKeys();
		tonics = new PentaTonics();

		skinBuffer = new Buffer<Elem>(22);
		skinProgram = new Program(skinBuffer);
		skinProgram.blendEnabled = true;
		addProgram(skinProgram);

		letterSizeHelp = 32;
		letterSizeButton = 64;

		textOptions = {
			letterWidth: letterSizeHelp,
			letterHeight: letterSizeHelp,
		}

		textProgram = new TextProgram(textOptions);
		addProgram(textProgram);

		displayWidthMid = width / 2;
		displayHeightMid = height / 2;

		showHeader("choose keyboard");
		showLayouts();
		state = CHOOSE_LAYOUT;
	}

	function showHeader(message:String):Void {
		if (headerText != null) {
			textProgram.remove(headerText);
		}
		textOptions.fgColor = 0xf0f0f0FF;
		textOptions.letterWidth = letterSizeHelp;
		textOptions.letterHeight = letterSizeHelp;
		var textWidth = message.length * textOptions.letterWidth;
		var helpX = Std.int(displayWidthMid - (textWidth / 2));
		var helpY = 20;
		headerText = textProgram.add(new Text(helpX, helpY, message));
	}

	function showFooter(message:String):Void {
		if (footerText != null) {
			textProgram.remove(footerText);
		}
		textOptions.fgColor = 0xf0f0f0FF;
		textOptions.letterWidth = letterSizeHelp;
		textOptions.letterHeight = letterSizeHelp;
		var textWidth = message.length * textOptions.letterWidth;
		var helpX = Std.int(displayWidthMid - (textWidth / 2));
		var helpY = height - 20 - letterSizeHelp;
		footerText = textProgram.add(new Text(helpX, helpY, message));
	}

	public function handleKey(code:KeyCode, isDown:Bool):Void {
		var noteIndex = keys.keymap[code];
		if (noteIndex != null) {
			press(buttons[noteIndex], isDown);
			return;
		}
		var button = controlKeymap[code];
		if (button != null) press(button, isDown);
	}

	function press(button:Button, isDown:Bool):Void {
		if (button.isDown == isDown) return; // ignore key-repeat
		button.isDown = isDown;

		switch button.action {
			case Note(frequencyIndex):
				if (isDown) {
					if (!heldNotes.exists(frequencyIndex)) {
						var column = frequencyIndex % COLUMNS;
						var highFrequency = tonics.frequencies[HIGH_FREQUENCY_INDEX];
						var freq = tonics.frequencies[frequencyIndex];
						patch.pan = (column / (COLUMNS - 1) * 2.0 - 1.0) * MAX_PAN;
						var velocity = Math.min(Math.pow(highFrequency / freq, LOUDNESS_COMPENSATION), MAX_LOUDNESS_BOOST);
						heldNotes[frequencyIndex] = source.noteOn(patch, freq, velocity);
					}
				} else {
					if (heldNotes.exists(frequencyIndex)) {
						source.noteOff(heldNotes[frequencyIndex]);
						heldNotes.remove(frequencyIndex);
					}
				}
			case ScaleStep(direction):
				if (isDown) {
					tonics.incrementScale(direction);
					showFooter('' + tonics.currentScale);
				}
			case null:
		}

		var offset = isDown ? keyPressOffset : -keyPressOffset;
		button.skin.x += offset;
		button.skin.y += offset;
		button.label.x += offset;
		button.label.y += offset;
		textProgram.updateText(button.label);
		skinBuffer.updateElement(button.skin);
	}

	override function addToPeoteView(peoteView:PeoteView, ?atDisplay:Display, addBefore:Bool = false) {
		super.addToPeoteView(peoteView, atDisplay, addBefore);
		register(peoteView.window);
	}

	private function register(window:Window) {
		window.onMouseDown.add((x, y, button) -> {
			switch state {
				case CHOOSE_LAYOUT:
					if (buttonUnderMouse != null) {
						keys.chooseLayout(buttonUnderMouse.label.text);
						clearButtons();
						onActivate(this);
						showHeader("play keys");
						state = KEYJAZZ;
					}
				case KEYJAZZ:
					isMouseDown = true;
					if (buttonUnderMouse != null) {
						buttonPressedByMouse = buttonUnderMouse;
						press(buttonPressedByMouse, true);
					}
			}
		});

		window.onMouseUp.add((x, y, button) -> {
			isMouseDown = false;
			if (buttonPressedByMouse != null) {
				press(buttonPressedByMouse, false);
				buttonPressedByMouse = null;
			}
		});

		window.onMouseMove.add((x, y) -> {
			buttonUnderMouse = null;
			for (button in buttons) {
				var left = button.hitX;
				var right = button.hitX + button.hitW;
				var top = button.hitY;
				var bottom = button.hitY + button.hitH;
				if (x >= left && x < right && y >= top && y < bottom) {
					button.skin.c.a = 0xff;
					buttonUnderMouse = button;
				} else {
					button.skin.c.a = 0xdf;
				}
			}
			if (isMouseDown && buttonUnderMouse != buttonPressedByMouse) {
				if (buttonPressedByMouse != null)
					press(buttonPressedByMouse, false);
				buttonPressedByMouse = buttonUnderMouse;
				if (buttonUnderMouse != null)
					press(buttonUnderMouse, true);
			}
			skinBuffer.update();
		});
	}

	function clearButtons():Void {
		skinBuffer.clear();
		for (button in buttons) {
			textProgram.remove(button.label);
		}
	}

	var labelColor = 0x5D4B56df;
	var skinColor = 0xEDD7E3df;

	function showLayouts():Void {
		textOptions.fgColor = labelColor;
		textOptions.letterWidth = letterSizeButton;
		textOptions.letterHeight = letterSizeButton;

		var index:Int = 0;

		var margin = Std.int(letterSizeButton * 0.2);
		var keyHeight = Std.int(textOptions.letterHeight * 1.2);
		var keyTextSpaceY = margin + keyHeight;

		var gridHeight = keys.layouts.length * keyTextSpaceY;
		var gridY = Std.int(displayHeightMid - (gridHeight / 2));

		buttons = [
			for (n => layout in keys.layouts) {
				var buttonWidth = (letterSizeButton * layout.length) + margin;
				var skinX = Std.int(displayWidthMid - (buttonWidth / 2));
				var skinY = gridY + (n * keyTextSpaceY);
				// Button
				{
					index: index++,
					label: textProgram.add(new Text(skinX + margin, skinY + margin, layout, textOptions)),
					skin: skinBuffer.addElement(new Elem(skinX, skinY, buttonWidth, keyHeight, 0, 0, 0, 0, skinColor)),
					hitX: skinX - keyPressOffset,
					hitY: skinY - keyPressOffset,
					hitW: buttonWidth,
					hitH: keyHeight + keyPressOffset
				}
			}
		];
	}

	function showKeyboard():Void {
		textOptions.fgColor = labelColor;
		textOptions.letterWidth = 64;
		textOptions.letterHeight = 64;

		var index:Int = 0;
		var columns = COLUMNS;
		var rows = 4;
		var margin = 8;

		var keyGapX = Std.int(textOptions.letterWidth * 0.2);
		var keyWidth = Std.int(textOptions.letterWidth * 1.2);
		var keyTextSpaceX = keyGapX + keyWidth;

		var keyGapY = Std.int(textOptions.letterWidth * 0.2);
		var keyHeight = Std.int(textOptions.letterHeight * 1.2);
		var keyTextSpaceY = keyGapY + keyHeight;

		var gridWidth = (keyGapX * (columns - 1)) + (keyWidth * columns);
		var gridHeight = (keyGapY * (rows - 1)) + (keyHeight * rows);

		var gridX = Std.int(displayWidthMid - (gridWidth / 2));
		var gridY = Std.int(displayHeightMid - (gridHeight / 2));

		var keyHitW = keyWidth + keyPressOffset * 2;
		var keyHitH = keyHeight + keyPressOffset * 2;

		buttons = [
			for (keyCode in keys.layout) {
				var char:String = String.fromCharCode(keyCode).toUpperCase();
				var column = (index % columns);
				var row = Std.int(index / columns);
				var rowShift = textOptions.letterWidth * 0.9;
				var diagonalOffset = Std.int(((rows - 1) / 2.0 - row) * rowShift);
				var skinX = gridX + (column * keyTextSpaceX) + diagonalOffset;
				var skinY = gridY + (row * keyTextSpaceY);
				var buttonIndex = index++;
				// Button
				{
					index: buttonIndex,
					label: textProgram.add(new Text(skinX + margin, skinY + margin, char, textOptions)),
					skin: skinBuffer.addElement(new Elem(skinX, skinY, keyWidth, keyHeight, 0, 0, 0, 0, skinColor)),
					hitX: skinX,
					hitY: skinY,
					hitW: keyHitW,
					hitH: keyHitH,
					action: Note(buttonIndex)
				}
			}
		];

		showFooter('' + tonics.currentScale);

		textOptions.fgColor = labelColor;
		textOptions.letterWidth = 64;
		textOptions.letterHeight = 64;

		var skinX = 120;
		var skinY = footerText.y - 32;

		var scaleDown:Button = {
			index: buttons.length,
			label: textProgram.add(new Text(skinX + margin, skinY + margin, "<", textOptions)),
			skin: skinBuffer.addElement(new Elem(skinX, skinY, keyWidth, keyHeight, 0, 0, 0, 0, skinColor)),
			hitX: skinX,
			hitY: skinY,
			hitW: keyHitW,
			hitH: keyHitH,
			action: ScaleStep(-1)
		};
		buttons.push(scaleDown);
		controlKeymap[KeyCode.LEFT] = scaleDown;

		skinX = width - keyWidth - 120;
		var scaleUp:Button = {
			index: buttons.length,
			label: textProgram.add(new Text(skinX + margin, skinY + margin, ">", textOptions)),
			skin: skinBuffer.addElement(new Elem(skinX, skinY, keyWidth, keyHeight, 0, 0, 0, 0, skinColor)),
			hitX: skinX,
			hitY: skinY,
			hitW: keyHitW,
			hitH: keyHitH,
			action: ScaleStep(1)
		};
		buttons.push(scaleUp);
		controlKeymap[KeyCode.RIGHT] = scaleUp;
	}
}

enum ButtonAction {
	Note(frequencyIndex:Int);
	ScaleStep(direction:Int);
}

@:publicFields
@:structInit
class Button {
	var index:Int;
	var label:Text;
	var skin:Elem;
	var hitX:Int;
	var hitY:Int;
	var hitW:Int;
	var hitH:Int;
	var isDown:Bool = false;
	var action:ButtonAction = null;
}

enum State {
	CHOOSE_LAYOUT;
	KEYJAZZ;
}