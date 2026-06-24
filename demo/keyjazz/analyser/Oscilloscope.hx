package analyser;

import haxe.io.Float32Array;
import peote.view.*;
import peote.view.element.Elem;
import peote.view.intern.Util;

@:publicFields
class Oscilloscope extends Display {
	var buffer:Buffer<Elem>;
	var program:Program;
	var elem:Elem;

	var textureData:TextureData;
	var texture:Texture;

	var channelSize:Int;
	var leftChannel:Float32Array;
	var rightChannel:Float32Array;
	var writePos:Int = 0;

	function new(x:Int, y:Int, w:Int, h:Int, deviceSampleRate:Int, durationSeconds:Float, pv:PeoteView) {
		super(x, y, w, h);

		buffer = new Buffer<Elem>(1, 1);
		elem = buffer.addElement(new Elem(0, 0, w, h, 0, 0, 0, 0, 0x0000000));

		program = new Program(buffer);
		program.blendEnabled = true;
		addProgram(program);
		
		var maxTextureSize = pv.gl.getParameter(pv.gl.MAX_TEXTURE_SIZE);
		var maxPixels = maxTextureSize * maxTextureSize;
		var durationSize = durationSeconds * deviceSampleRate;
		var minTextureSize = Std.int(Math.min(durationSize, maxPixels));

		// size texture to fit samples
		var texH = Std.int(Math.max(1, Math.ceil(minTextureSize / maxTextureSize)));
		var texW = Std.int(Math.min(maxTextureSize, Math.ceil(minTextureSize / texH)));
		textureData = new TextureData(texW, texH, TextureFormat.RG);
		texture = Texture.fromData(textureData);
		program.addTexture(texture);

		channelSize = texW * texH;
		leftChannel = new Float32Array(channelSize);
		rightChannel = new Float32Array(channelSize);

		// not all samples are rendered because the display resolution is lower than the texture
		// this can leave gaps when the line is thin
		// derive line thickness from texel resolution so there are no gaps
		var texelsPerPixel = channelSize / w;
		var lineThicknessPx = Math.max(1, texelsPerPixel);
		var lineThickness = Util.toFloatString(lineThicknessPx / h);

		var leftColor = Util.color2vec4(0x6D9DC5FF);
		var rightColor = Util.color2vec4(0xEB9486FF);
		var texWidth = Util.toFloatString(texW);
		var texHeight = Util.toFloatString(texH);

		// use blend mode ONE because we bake the alpha in the shader and do not want the shader to multiply the alpha again
		program.blendSrc = BlendFactor.ONE;
		program.injectIntoFragmentShader('
		vec4 composeOscilloscope(int pcmTexID, float thickness, vec4 leftColor, vec4 rightColor) {

			// sampling the pcm data from the texture (interpolated between samples)
			float rowPos = vTexCoord.x * $texHeight;
			float rowPosPrevious = rowPos - 1.0 / $texWidth;
			vec2 samples = getTextureColor(pcmTexID, vec2(fract(rowPos), floor(rowPos) / $texHeight)).rg;
			vec2 samplesPrevious = getTextureColor(pcmTexID, vec2(fract(rowPosPrevious), floor(rowPosPrevious) / $texHeight)).rg;
			vec2 channelCenters = vec2(0.0, 0.5);
			vec2 y = samples * 0.5 + channelCenters;
			vec2 yPrevious = samplesPrevious * 0.5 + channelCenters;
			vec2 yMin = min(y, yPrevious);
			vec2 yMax = max(y, yPrevious);

			// edge of oscilloscope line (outside has 0 alpha)
			vec2 dist = max(vec2(0.0), max(yMin - vTexCoord.y, vTexCoord.y - yMax));
			vec2 alpha = 1.0 - smoothstep(thickness * 0.5, thickness, dist);
			
			// baking the alpha into rgb colors here
			vec3 left = leftColor.rgb * alpha.x;
			vec3 right = rightColor.rgb * alpha.y;
			return vec4(left + right, alpha.x + alpha.y - alpha.x * alpha.y);
		}');

		program.setColorFormula('composeOscilloscope(default_ID, $lineThickness, $leftColor, $rightColor)');

		// init with silence
		update(new Float32Array(0));
	}

	public function update(stereoSamples:Float32Array) {
		var n = stereoSamples.length >> 1;
		for (i in 0...n) {
			leftChannel[writePos % channelSize] = stereoSamples[i * 2];
			rightChannel[writePos % channelSize] = stereoSamples[i * 2 + 1];
			writePos++;
		}

		var readStart = writePos % channelSize;
		for (i in 0...channelSize) {
			var idx = (readStart + i) % channelSize;
			var byteL = Std.int(Math.min(1.0, Math.max(0.0, leftChannel[idx] * 0.5 + 0.5)) * 255);
			var byteR = Std.int(Math.min(1.0, Math.max(0.0, rightChannel[idx] * 0.5 + 0.5)) * 255);
			textureData.set_RG(i % textureData.width, Std.int(i / textureData.width), byteL, byteR);
		}
		texture.setData(textureData);
	}
}
