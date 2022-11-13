# socks5_io

[![Pub Version](https://img.shields.io/pub/v/socks5_io)](https://pub.dev/packages/socks5_io)

IO based socks5 implementation at dartlang.

## Install

Add dependency to `pubspec.yaml`.

```yaml
dependencies:
  socks5_io: ^0.1.0
```

## Quick Start

```dart
final List<dynamic> proxy = ["127.0.0.1", 7890];
final List<dynamic> target = ["example.org", 80];

final dialer = Socks5ClientSocketDialer("127.0.0.1", 7890);
dialer.connect("example.org", 80).then((socks5) {

  // handle remote server response
  socks5.getReader().listen((buffer) {
    print(ascii.decode(buffer));
    socks5.close();
  },
    onError: (err) => {/* handle transfer error */},
    onDone: () => {/* handle target closed */},
  );

  // send request (non-blocking)
  socks5.getWriter().add(ascii.encode([
    "GET / HTTP/1.1",
    "Host: example.org:80",
    "User-Agent: socks5_io/0.1.0",
    "Accept: */*",
    "\r\n",
  ].join("\r\n")));

}).catchError((err) {/* handle connect error */});
```

See more at folder `example/`.

## Acknowledgement

- Golang Code Reference `golang.org/x/net`.

- [Pub Package `socks5`](https://pub.dev/packages/socks5)

  But it is not null safety

## LICENSE

MIT
