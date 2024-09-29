import 'dart:async';

import 'socks.dart';

enum _State { ready, connecting, connected }

/// The state perform socks5 client handshake work
///
/// Once connected to remote, the state should NOT handle anything at all.
///
/// For socket example, see [Socks5ClientDialer].
class Socks5ClientState {
  final Future Function(List<int> buffer) write;
  final List<AuthMethod> authMethods;
  final Command command = Command.connect;
  var _state = _State.ready;
  Completer<List<int>>? _readResponse;

  Socks5ClientState({
    required this.write,
    this.authMethods = const [],
  });

  bool get connected => _state == _State.connected;

  // protected
  waitForResponse() {
    final completer = _readResponse = Completer();
    return completer.future.whenComplete(() => _readResponse = null);
  }

  notifyData(List<int> buffer) {
    if (connected) return;
    _readResponse?.complete(buffer);
  }

  notifyError(Object error, [StackTrace? trace]) {
    if (connected) return;
    _readResponse?.completeError(error, trace);
  }

  Future connect(String targetHost, int targetPort) async {
    switch (_state) {
      case _State.ready:
        break;
      case _State.connecting:
        throw "client is connecting";
      case _State.connected:
        return;
    }
    try {
      List<int> buffer;
      // 1. write auth request
      write(Protocol.encodeAuthRequest(authMethods));
      buffer = await waitForResponse();
      Protocol.decodeAuthResponse(buffer);
      // 2. write command request
      write(Protocol.encodeCommandRequest(targetHost, targetPort, command));
      buffer = await waitForResponse();
      _state = _State.connected;
    } catch (protocolErr) {
      _state = _State.ready;
      _readResponse = null;
      rethrow;
    }
  }
}
