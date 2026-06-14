class AudioStreamProcessor extends AudioWorkletProcessor {
	constructor(options) {
		super();

		// queues for left and right channels
		this.leftBufferQueue = [];
		this.rightBufferQueue = [];

		// currently being processed
		this.currentLeftBuffer = null;
		this.currentRightBuffer = null;

		this.leftBufferIndex = 0;
		this.rightBufferIndex = 0;

		this.bufferSize = (options.processorOptions && options.processorOptions.bufferSize) || 1024;
		this.streamConsumed = 0;
		this.samplesProcessed = 0;
		this.silentSamples = 0;
		this.isPlaying = false;

		// route messages sent from main thread
		this.port.onmessage = (event) => {
			if (event.data.type === 'stream.buffer.data') {
				// queue audio stream
				this.leftBufferQueue.push(event.data.leftBuffer);
				this.rightBufferQueue.push(event.data.rightBuffer);
			} else if (event.data.type === 'stream.play') {
				this.isPlaying = true;
				this.port.postMessage({ type: 'stream.buffer.request' });
			} else if (event.data.type === 'stream.stop') {
				this.isPlaying = false;
				this.streamConsumed = 0;
				// reset buffers
				this.leftBufferQueue = [];
				this.rightBufferQueue = [];
				this.currentLeftBuffer = null;
				this.currentRightBuffer = null;
				this.leftBufferIndex = 0;
				this.rightBufferIndex = 0;
			} else if (event.data.type === 'stream.pause') {
				this.isPlaying = false;
				// keep buffers for resume
			} else if (event.data.type === 'stream.resume') {
				this.isPlaying = true;
				this.port.postMessage({ type: 'stream.buffer.request' });
			}
		};
	}

	process(inputs, outputs, parameters) {
		const output = outputs[0];
		const leftChannel = output[0];
		const rightChannel = output[1];

		for (let i = 0; i < leftChannel.length; i++) {
			if (this.isPlaying) {
				const leftSample = this.getNextLeftSample();
				const rightSample = this.getNextRightSample();

				leftChannel[i] = leftSample;
				rightChannel[i] = rightSample;

				// count silent stream (when both channels are silent)
				if (leftSample === 0 && rightSample === 0) {
					this.silentSamples++;
				} else {
					this.silentSamples = 0;
				}

				this.streamConsumed++;
				if (this.streamConsumed >= this.bufferSize) {
					this.streamConsumed = 0;
					this.port.postMessage({ type: 'stream.buffer.request' });
				}
			} else {
				// output silence because !isPlaying
				leftChannel[i] = 0;
				rightChannel[i] = 0;
			}
			this.samplesProcessed++;
		}

		// log status every 8192 stream
		// if (this.samplesProcessed % 8192 === 0) {
		// 	this.port.postMessage({
		// 		type: 'bufferStatus',
		// 		queueLength: this.leftBufferQueue.length,
		// 		samplesProcessed: this.samplesProcessed,
		// 		silentSamples: this.silentSamples,
		// 		isPlaying: this.isPlaying
		// 	});
		// }

		return true;
	}

	getNextLeftSample() {
		if (!this.currentLeftBuffer || this.leftBufferIndex >= this.currentLeftBuffer.length) {
			if (this.leftBufferQueue.length > 0) {
				this.currentLeftBuffer = this.leftBufferQueue.shift();
				this.leftBufferIndex = 0;
			} else {
				return 0;
			}
		}

		if (this.currentLeftBuffer && this.leftBufferIndex < this.currentLeftBuffer.length) {
			return this.currentLeftBuffer[this.leftBufferIndex++];
		}
		return 0;
	}

	getNextRightSample() {
		if (!this.currentRightBuffer || this.rightBufferIndex >= this.currentRightBuffer.length) {
			if (this.rightBufferQueue.length > 0) {
				this.currentRightBuffer = this.rightBufferQueue.shift();
				this.rightBufferIndex = 0;
			} else {
				return 0;
			}
		}

		if (this.currentRightBuffer && this.rightBufferIndex < this.currentRightBuffer.length) {
			return this.currentRightBuffer[this.rightBufferIndex++];
		}
		return 0;
	}
}

registerProcessor('audio-stream-processor', AudioStreamProcessor);