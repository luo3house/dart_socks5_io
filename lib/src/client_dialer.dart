import 'dart:async';
import 'dart:io';

import 'utils/socket_like.dart';

import 'client_state.dart';
import 'socks.dart';

/// The dialer to create a remote connection
class Socks5ClientDialer {
  /// The proxy host, should be [String] or [InternetAddress]
  final dynamic proxyHost;

  /// The proxy port
  final int proxyPort;

  /// Auth methods
  final List<AuthMethod> authMethods;

  Socks5ClientDialer(
    this.proxyHost,
    this.proxyPort, {
    this.authMethods = const [],
  });

  Future<SocketLike> connect(String remoteHost, int remotePort) async {
    late RawSocket socket;
    late StreamSubscription stateSub;
    try {
      // RawSocket
      socket = await RawSocket.connect(proxyHost, proxyPort);
      final wrappedSocket = SocketLike.wrapRawSocket(socket);

      // Socket workaround
      // socket = await Socket.connect(host, port);
      // final wrappedSocket = SocketLike.wrapSocket(socket);

      final state = Socks5ClientState(
        write: (buffer) async => wrappedSocket.getWriter().add(buffer),
      );

      // temporary subscribe, do socks5 handshake
      stateSub = wrappedSocket.getReader().listen(
          (buffer) => state.notifyData(buffer),
          onError: (err) => state.notifyError(err),
          onDone: () => state.notifyError("read from a closed stream"));
      await state.connect(remoteHost, remotePort);
      stateSub.cancel();

      return wrappedSocket;
    } catch (err) {
      // ignore: unnecessary_null_comparison
      if (socket != null) socket.close();
      // ignore: unnecessary_null_comparison
      if (stateSub != null) await stateSub.cancel();
      rethrow;
    }
  }
}
