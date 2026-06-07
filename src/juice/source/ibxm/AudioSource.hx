package juice.source.ibxm;

import haxe.io.Float32Array;
import juice.IAudioSource;

#if hl
import ibxm.bindings.hl.IbxmHl.IbxmSource;
#elseif cpp
import ibxm.bindings.cpp.IbxmCpp.IbxmSource;
#else
import ibxm.bindings.js.IbxmJs.IbxmSource;
#end

class AudioSource implements IAudioSource {
	final ibxm:IbxmSource;

	public function new(ibxm:IbxmSource) {
		this.ibxm = ibxm;
	}

	public function getAudio(left:Float32Array, right:Float32Array, numSamples:Int):Void {
		ibxm.getAudio(left, right, numSamples);
	}

	public function getAudioInterleaved(output:Float32Array, numSamples:Int):Void {
		ibxm.getAudioInterleaved(output, numSamples);
	}
}
