import 'dart:async';
import 'dart:convert';

import 'package:socks5_io/socks5_io.dart';
import 'package:socks5_io/src/utils/socket_like.dart';

main() async {
  final List<dynamic> proxy = ["127.0.0.1", 7890];
  final List<dynamic> target = ["example.org", 80];

  final dialer = Socks5ClientSocketDialer(proxy[0], proxy[1]);
  dialer.connect(target[0], target[1]).then((SocketLike socks5) {
    final completer = Completer();

    // handle remote server response
    socks5.getReader().listen((buffer) {
      completer.complete(ascii.decode(buffer));
    });

    // send request (non-blocking)
    socks5.getWriter().add(ascii.encode([
          "GET / HTTP/1.1",
          "Host: example.org:80",
          "User-Agent: curl/7.79.1",
          "Accept: */*",
          "\r\n",
        ].join("\r\n")));

    completer.future.then((responseText) {
      print(responseText);
      socks5.close();
    });
  }).catchError((err) {/* handle connect error */});
}
