# socks5_io

[![Pub Version](https://img.shields.io/pub/v/socks5_io)](https://pub.dev/packages/socks5_io)

IO based socks5 implementation at dartlang.

## Install

Add dependency to `pubspec.yaml`.

```yaml
dependencies:
  socks5_io: ^0.0.1
```

## Quick Start

```dart
// Connect to a socks5 server using raw tcp socket
final proxySocket = await RawSocket.connect(InternetAddress.loopbackIPv4, 10000);

// Wrap the socket with Socks5Client
final socks5 = Socks5Client(proxySocket);

// Request for connecting to a remote server
socks5.connect("www3.okin-jp.net", 25565).then((_) {

  // Now the tunnel is ready, any data sent will be transfer via tunnel

  // Listen upstream data
  socks5.dataStream.listen((buffer) {
    // Uint8List
  })

  // OK, Because socks5 client completely did the handshake job
  proxySocket.write([1,2,3]);

  // OK, Because socks5.write is an alias of socket.write
  socks5.write([4,5,6]);

  // OK, socks5 supports StreamConsumer
  anotherSocket.pipe(socks5);

  // DO NOT listen source socket data, it is intercepted by socks5
  // proxySocket.listen(...)
}).catchError((err) {

  // Handle handshake error
});
```

## Acknowledgement

- Golang Code Reference `golang.org/x/net`.

- [Pub Package `socks5`](https://pub.dev/packages/socks5)

  It is not null safety

## LICENSE

MIT
