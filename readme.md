# juice

Squeeze some sounds out of haxe~~lime~~

## Audio streaming API

### ISampleStream

Responsible for producing the individual audio samples that are played through AudioDriver.

### AudioDriver

Responsible for feeding the ISampleStream samples into an audio device.

#### driver.lime

Here we use lime's OpenAL `sourceQueueBuffer` to stream.

#### driver.js

Here we stream through `AudioWorklet` where available. It requires https when not running locally. Or will fall back to deprecated `AudioProcessingEvent`.

### IVoice and VoiceStream

Used for polyphony, for example to be able to play multiple sample streams at once.

Currently we have an example voice Sampler.

## test

There's a very simple test of streaming a sine wave AudioSource in the `test-lime` folder.

It's using the `lime` AudioDriver for native/hashlink and the `js` AudioDriver for html5.

e.g.

```
cd test-lime
lime test hl
# or web (you need to click the window to activate becaus)
lime test html5
```

# todo

- proper readme
- pure tests (e.g. test driver.format)
- more voices (wavetable, fm) ?
- comments