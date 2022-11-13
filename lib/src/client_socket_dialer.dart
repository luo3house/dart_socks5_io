import 'dart:async';
import 'dart:io';

import 'utils/socket_like.dart';

import 'client_state.dart';
import 'socks.dart';

class Socks5ClientSocketDialer {
  /// The proxy host, should be [String] or [InternetAddress]
  final dynamic proxyHost;

  /// The proxy port
  final int proxyPort;

  /// Auth methods
  final List<AuthMethod> authMethods;

  Socks5ClientSocketDialer(
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

// class Socks5ClientDialer implements StreamConsumer<List<int>> {
//   final RawSocket _socket;
//   final _dataStreamController = StreamController<List<int>>.broadcast();
//   final List<AuthMethod> authMethods;

//   /// Create a socks5 client socket
//   Socks5ClientDialer(
//     this._socket, {
//     this.authMethods = const [],
//   }) {
//     _socket.listen((event) {
//       switch (event) {
//         case RawSocketEvent.closed:
//           _dataStreamController.close();
//           break;
//         case RawSocketEvent.readClosed:
//           const err = "read from a closed socket";
//           _dataStreamController.addError(err);
//           break;
//         case RawSocketEvent.read:
//           final buffer = _socket.read(_socket.available());
//           if (buffer == null) return;
//           _dataStreamController.add(buffer);
//           break;
//         default:
//       }
//     });
//   }

//   Stream<List<int>> get dataStream => _dataStreamController.stream;

//   Future<Socks5ClientDialer> connect(String targetHost, int targetPort) async {
//     final client = Socks5ClientController(
//       reader: dataStream,
//       writer: SimpleSink(
//         addImpl: (buffer) => write(buffer),
//         closeImpl: () => throw UnsupportedError(
//           "closing stream may cause errors, use socket.close() instead.",
//         ),
//       ),
//     );
//     try {
//       await client.connect(targetHost, targetPort);
//       return this;
//     } catch (err) {
//       rethrow;
//     }
//   }

//   // direct

//   int write(
//     List<int> buffer, [
//     int offset = 0,
//     int? count,
//   ]) =>
//       _socket.write(buffer, offset, count);

//   // stream pipe

//   Future pipe(StreamConsumer<List<int>> consumer) => dataStream.pipe(consumer);

//   // StreamConsumer

//   @override
//   Future close() => _socket.close();

//   @override
//   Future addStream(Stream<List<int>> stream) {
//     var completer = Completer();
//     stream.listen(
//       write,
//       onDone: () => completer.complete(),
//       onError: (err) => completer.completeError(err),
//     );
//     return completer.future;
//   }
// }

// // /// Socks5ClientDialer, wraps and intercepts the raw socket
// // class Socks5ClientDialer extends Socks5Client
// //     implements StreamConsumer<List<int>> {
// //   final RawSocket socket;
// //   final _dataSource = StreamController<List<int>>.broadcast();

// //   /// Create a socks5 client socket
// //   Socks5ClientDialer(
// //     this.socket, {
// //     List<AuthMethod> authMethods = const [],
// //   }) {
// //     final reader = StreamController<List<int>>.broadcast();
// //     final writer = _SimpleSink<List<int>>(
// //       addImpl: (data) => socket.write(data),
// //       closeImpl: () => socket.close(),
// //     );
// //     super();

// //     // socket.listen((event) {
// //     //   switch (event) {
// //     //     case RawSocketEvent.closed:
// //     //       _dataSource.close();
// //     //       break;
// //     //     case RawSocketEvent.readClosed:
// //     //       const err = "read from a closed socket";
// //     //       _dataSource.close();
// //     //       break;
// //     //     case RawSocketEvent.read:
// //     //       final buffer = socket.read(socket.available());
// //     //       if (buffer == null) return;
// //     //       _dataSource.add(buffer);
// //     //       break;
// //     //     default:
// //     //   }
// //     // });
// //   }

// //   /// Use broadcast dataStream.listen to retrieve upstream data
// //   Stream<Uint8List> get dataStream => _dataSource.stream;

// //   /// Connect to remote server
// //   Future connect(String targetHost, int targetPort) async {
// //     var readResponse = Completer<Uint8List>();
// //     late StreamSubscription sub;
// //     Future<Uint8List> waitForResponse() {
// //       readResponse = Completer();
// //       return readResponse.future;
// //     }

// //     sub = dataStream.listen((buffer) => readResponse.complete(buffer));
// //     Uint8List buffer;
// //     socket.write(Protocol.encodeAuthRequest(authMethods));
// //     buffer = await waitForResponse();
// //     Protocol.decodeAuthResponse(buffer);
// //     socket
// //         .write(Protocol.encodeCommandRequest(targetHost, targetPort, command));
// //     buffer = await waitForResponse();
// //     Protocol.decodeCommandResponse(buffer);
// //     sub.cancel();
// //     _connected = true;
// //   }

// //   /// Write data to upstream
// //   int write(
// //     List<int> buffer, [
// //     int offset = 0,
// //     int? count,
// //   ]) =>
// //       socket.write(buffer, offset, count);

// //   /// StreamConsumer compatible
// //   @override
// //   Future close() => socket.close();

// //   /// StreamConsumer compatible
// //   @override
// //   Future addStream(Stream<Uint8List> stream) async {
// //     var completer = Completer();
// //     stream.listen(
// //       write,
// //       onDone: () => completer.complete(),
// //       onError: (err) => completer.completeError(err),
// //     );
// //     return completer.future;
// //   }
// // }
