# Noise.framework

![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20iOS-lightgrey.svg)
![Carthage](https://img.shields.io/badge/Carthage-compatible-green.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

This project provides an macOS and iOS compatible framework to develop protocol based on the [Noise Protocol Framework](https://noiseprotocol.org). 
It wraps the [noise-c](https://github.com/rweather/noise-c) library in an easy to use object-oriented fashion. 

It's written in Objective-C and is Swift friendly.

## Installation

You have a few different options:

### Manual installation

 *  Include the Noise.xcodeproj as a dependency in your project.  
 *  Use a pre-built Noise.framework. You can find them under [Releases](https://github.com/OuterCorner/Noise/releases).

In either case you'll also need to add the [OpenSSL.framework](https://github.com/OuterCorner/OpenSSL) dependency.

### Carthage

Add Noise as a dependency on your ```Cartfile```:

```
github "OuterCorner/Noise"
```
And run:

```
carthage update
```

By default Carthage will download the pre-build binaries (faster), if you want to compile from source pass ```--no-use-binaries``` to the update command above.

## Usage

The public headers are extensively documented and should be fairly easy to grasp. Here's a quick overview on how to use the framework.

Start by importing the umbrella header:

```ObjC
// Objective-C
#import <Noise/OpenSSL.h>
```

```Swift
// Swift
import Noise
```

### Noise session

The ```NPFSession``` class is central to the framework. You start by creating a session with the noise protocol you want to use:

```ObjC
// Objective-C
NPFSession *session = [[NPFSession alloc] initWithProtocolName:@"Noise_NK_25519_AESGCM_SHA256" role:NPFSessionRoleInitiator];
```
```Swift
// Swift
let session = NoiseSession(protocolName: "Noise_NK_25519_AESGCM_SHA256", role: .initiator)
```

After that you *must* call ```setup``` before starting a session, even if you're using an ```NN``` handshake pattern where no setup is required:


```ObjC
// Objective-C
[session setup:^(id<NPFSessionSetup> setup) {
  NPFKey *pubKey = [keyManager remotePublicKeyFor:@"some responder" ofType:NPFKeyAlgoCurve25519];
  setup.remotePublicKey = pubKey;
}];
```
```Swift
// Swift
session.setup { setup in
  let pubKey = keyManager.remotePublicKey(for: "some responder", type: .curve25519);
  setup.remotePublicKey = pubKey
}
```

You're now ready to start the session:

```ObjC
// Objective-C
NSError *error = nil;
if (![session start:&error]){
  // handle error
}
```
```Swift
// Swift
try session.start()
```

After starting a session, both the ```sendingHandle``` and ```receivingHandle``` properties are ready to be bound to your transport channel. 
You must read from ```sendingHandle``` and send any data to your peer, be it via TCP, Unix sockets, smoke signals… 
Conversely any data you receive from your peer you should write to ```receivingHandle```.

Since these are ```NSFileHandle```s you can install a readability handler to run everytime the session has data to send:

```ObjC
// Objective-C
session.sendingHandle.readabilityHandler = ^(NSFileHandle * fh) {
  NSData *data = [fh availableData];
  // write data to your transport channel
}
```

```Swift
// Swift
session.sendingHandle!.readabilityHandler = { fh in
  let data = fh.availableData
  // write data to your transport channel
}
```

### Handshake 

When starting a session the first step is to perform the chosen handshake. You can either implement the delegate method ```-session:handshakeComplete:``` or observe the session
s ```state``` to know when the handshake is complete.

If you're using a handshake pattern where you don't know the peer's public key beforehand, you can consult the ```NPFHandshakeState``` object passed to the delegate on handshake completion.

```ObjC
// Objective-C
- (void)session:(NPFSession *)session handshakeComplete:(NPFHandshakeState *)handshakeState
{
    NPFKey *remotePubKey = [handshakeState remotePublicKey]
    // do something with remotePubKey
}
```

```Swift
// Swift
func session(_ session: NoiseSession, handshakeComplete handshakeState: NoiseHandshakeState) {
  let remotePubKey = handshakeState.remotePublicKey
  // do something with remotePubKey
}
```

### Send and receiving messages

After the handshake is complete you can send messages via the ```-sendData:``` method and receive via the ```-session:didReceiveData:``` delegate method.


## Dependencies

This projects depends on [OpenSSL.framework](https://github.com/OuterCorner/OpenSSL). If you're using Carthage it will be downloaded automatically.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE).
