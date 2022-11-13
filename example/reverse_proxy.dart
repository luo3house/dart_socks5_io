import 'dart:io';
import 'package:socks5_io/socks5_io.dart';

// Let's play Minecraft.
// Start a reverse proxy to tunneling tcp for Minecraft servers (25565)
// over a socks5 proxy (7890).

main() async {
  final local = <dynamic>[InternetAddress.anyIPv4, 25565];
  final proxy = <dynamic>["127.0.0.1", 7890];
  final target = <dynamic>["www3.okin-jp.net", 25565];

  final localServer = await ServerSocket.bind(local[0], local[1]);
  localServer.listen((Socket client) async {
    final proxyDialer = Socks5ClientSocketDialer(proxy[0], proxy[1]);

    proxyDialer.connect(target[0], target[1]).then((socks5Socket) {
      // socks5 -> client
      socks5Socket
          .getReader()
          .pipe(client)
          .catchError((err) {/* handle transfer error */});
      // client -> socks5
      client
          .map((buffer) => List<int>.from(buffer))
          .pipe(socks5Socket)
          .catchError((err) {/* handle transfer error */});
    }).catchError((err) {
      print("connect error: $err");
      client.close();
    });
  });
}
