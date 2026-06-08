# juice

Squeeze some sounds out of haxe~~lime~~

## Audio streaming API

### IAudioSource

Responsible for producing the individual audio samples that are played through IAudioDriver.

### IAudioDriver

Responsible for feeding the IAudioSource samples into an audio stream.

#### driver.lime

Here we use lime's OpenAL `sourceQueueBuffer` to stream.

#### driver.js

Here we stream through `AudioWorklet` where available. It requires https when not running locally. Or will fall back to deprecated `AudioProcessingEvent`.

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
- comments
- decide where ibxm source should live