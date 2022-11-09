import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'socks.dart';

/// Socks5Client, wraps and intercepts the raw socket
class Socks5Client implements StreamConsumer<Uint8List> {
  final RawSocket socket;
  final List<AuthMethod> authMethods;
  final Command command = Command.connect;
  final _dataStreamController = StreamController<Uint8List>.broadcast();
  var _connected = false;

  /// Create a socks5 client
  Socks5Client(
    this.socket, {
    this.authMethods = const [],
  }) {
    socket.listen((event) {
      switch (event) {
        case RawSocketEvent.closed:
          _dataStreamController.close();
          break;
        case RawSocketEvent.readClosed:
          const err = "read from a closed socket";
          _dataStreamController.close();
          break;
        case RawSocketEvent.read:
          final buffer = socket.read(socket.available());
          if (buffer == null) return;
          _dataStreamController.add(buffer);
          break;
        default:
      }
    });
  }

  /// If socks5 successfully connected to remote
  bool get connected => _connected;

  /// Use broadcast dataStream.listen to retrieve upstream data
  Stream<Uint8List> get dataStream => _dataStreamController.stream;

  /// Connect to remote server
  Future connect(String targetHost, int targetPort) async {
    var readResponse = Completer<Uint8List>();
    late StreamSubscription sub;
    Future<Uint8List> waitForResponse() {
      readResponse = Completer();
      return readResponse.future;
    }

    sub = dataStream.listen((buffer) => readResponse.complete(buffer));
    Uint8List buffer;
    socket.write(Protocol.encodeAuthRequest(authMethods));
    buffer = await waitForResponse();
    Protocol.decodeAuthResponse(buffer);
    socket
        .write(Protocol.encodeCommandRequest(targetHost, targetPort, command));
    buffer = await waitForResponse();
    Protocol.decodeCommandResponse(buffer);
    sub.cancel();
    _connected = true;
  }

  /// Write data to upstream
  int write(
    List<int> buffer, [
    int offset = 0,
    int? count,
  ]) =>
      socket.write(buffer, offset, count);

  /// StreamConsumer compatible
  @override
  Future close() => socket.close();

  /// StreamConsumer compatible
  @override
  Future addStream(Stream<Uint8List> stream) async {
    var completer = Completer();
    stream.listen(
      write,
      onDone: () => completer.complete(),
      onError: (err) => completer.completeError(err),
    );
    return completer.future;
  }
}
