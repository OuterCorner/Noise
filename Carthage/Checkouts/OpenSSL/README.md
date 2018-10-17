# OpenSSL.framework

This project neatly packs OpenSSL into a dynamic framework for iOS and macOS.

Current OpenSSL version used: 1.1.1

## Installation

You have a few different options:

 *  Include the OpenSSL.xcodeproj as a dependency in your project. This is what the projects under ```Examples/``` are doing.
 *  Use a pre-built OpenSSL.framework. You can find them under [Releases](https://github.com/OuterCorner/OpenSSL/releases).


## Usage

After importing the umbrella header:

```ObjC
#import <OpenSSL/OpenSSL.h>
```
And start using OpenSSL APIs as usual.

```ObjC
Byte buffer[128];
    
int rc = RAND_bytes(buffer, sizeof(buffer));
```

See example projects under ```Examples/```.

## Issues

When including this framework in your project, you'll have to set **Allow Non-modular Includes In Framework Modules** to YES.

```
CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES
```

This is needed because the current version of OpenSSL public headers reference system headers.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

The build scripts for this project were based on:

 * [sqlcipher/openssl-xcode](https://github.com/sqlcipher/openssl-xcode)
 * [keeshux/openssl-apple](https://github.com/keeshux/openssl-apple)


