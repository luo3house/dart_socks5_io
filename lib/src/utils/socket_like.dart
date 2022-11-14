import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'simple_sink.dart';
import 'read_writer.dart';

/// Describe a class act like a socket
///
/// May be a wrapped [RawSocket], or [Socket]
///
/// SocketLike can be piped, e.g. anotherStream.pipe(socketLike)
abstract class SocketLike
    implements ReadWriter<List<int>, List<int>>, StreamConsumer<List<int>> {
  factory SocketLike.wrapRawSocket(RawSocket socket) {
    final readerSource = StreamController<List<int>>.broadcast();
    late StreamSubscription sub;
    sub = socket.listen(
      cancelOnError: true,
      onError: (err) => readerSource.addError(err),
      onDone: () {
        readerSource.close();
        sub.cancel();
      },
      (event) {
        switch (event) {
          case RawSocketEvent.closed:
            readerSource.close();
            break;
          case RawSocketEvent.readClosed:
            readerSource.addError('read from a closed stream');
            break;
          case RawSocketEvent.read:
            final buffer = socket.read(socket.available());
            if (buffer != null) {
              readerSource.add(buffer);
            }
            break;
          default:
        }
      },
    );
    final rw = ReadWriter.rw<List<int>, List<int>>(
      reader: readerSource.stream,
      writer: SimpleSink(
        addImpl: (buffer) => socket.write(buffer),
        closeImpl: () => socket.close(),
      ),
    );
    return _SimpleSocketLike(
      getReaderImpl: () => rw.getReader(),
      getWriterImpl: () => rw.getWriter(),
      destroyImpl: () => socket.close(),
      setOptionImpl: socket.setOption,
      getRawOptionImpl: socket.getRawOption,
      setRawOptionImpl: socket.setRawOption,
      getPortImpl: () => socket.port,
      getRemotePortImpl: () => socket.remotePort,
      getAddressImpl: () => socket.address,
      getRemoteAddressImpl: () => socket.remoteAddress,
      closeImpl: () => socket.close(),
    );
  }

  factory SocketLike.wrapSocket(Socket socket) {
    final readerStream = socket.asBroadcastStream();
    final rw = ReadWriter.rw<List<int>, List<int>>(
      reader: readerStream,
      writer: SimpleSink(
        addImpl: (buffer) => socket.add(buffer),
        closeImpl: () => socket.destroy(),
      ),
    );
    return _SimpleSocketLike(
      getReaderImpl: () => rw.getReader(),
      getWriterImpl: () => rw.getWriter(),
      destroyImpl: () => socket.close(),
      setOptionImpl: socket.setOption,
      getRawOptionImpl: socket.getRawOption,
      setRawOptionImpl: socket.setRawOption,
      getPortImpl: () => socket.port,
      getRemotePortImpl: () => socket.remotePort,
      getAddressImpl: () => socket.address,
      getRemoteAddressImpl: () => socket.remoteAddress,
      closeImpl: () => socket.close(),
    );
  }

  void destroy();

  bool setOption(SocketOption option, bool enabled);

  Uint8List getRawOption(RawSocketOption option);

  void setRawOption(RawSocketOption option);

  int get port;

  int get remotePort;

  InternetAddress get address;

  InternetAddress get remoteAddress;

  @override
  close();
}

class _SimpleSocketLike implements SocketLike {
  final Stream<List<int>> Function() getReaderImpl;
  final Sink<List<int>> Function() getWriterImpl;
  final dynamic Function() destroyImpl;
  final bool Function(SocketOption option, bool enabled) setOptionImpl;
  final Uint8List Function(RawSocketOption option) getRawOptionImpl;
  final dynamic Function(RawSocketOption option) setRawOptionImpl;
  final int Function() getPortImpl;
  final int Function() getRemotePortImpl;
  final InternetAddress Function() getAddressImpl;
  final InternetAddress Function() getRemoteAddressImpl;
  final Future Function() closeImpl;
  const _SimpleSocketLike({
    required this.getReaderImpl,
    required this.getWriterImpl,
    required this.destroyImpl,
    required this.setOptionImpl,
    required this.getRawOptionImpl,
    required this.setRawOptionImpl,
    required this.getPortImpl,
    required this.getRemotePortImpl,
    required this.getAddressImpl,
    required this.getRemoteAddressImpl,
    required this.closeImpl,
  });

  @override
  Future addStream(Stream stream) {
    final completer = Completer();
    stream.listen(
      (buffer) => getWriter().add(buffer),
      onError: (err) => completer.complete(err),
      onDone: () => completer.complete(),
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  InternetAddress get address => getAddressImpl();

  @override
  Future close() {
    return closeImpl();
  }

  @override
  void destroy() {
    return destroyImpl();
  }

  @override
  Uint8List getRawOption(RawSocketOption option) {
    return getRawOptionImpl(option);
  }

  @override
  Stream<List<int>> getReader() {
    return getReaderImpl();
  }

  @override
  Sink<List<int>> getWriter() {
    return getWriterImpl();
  }

  @override
  int get port => getPortImpl();

  @override
  InternetAddress get remoteAddress => getRemoteAddressImpl();

  @override
  int get remotePort => getRemotePortImpl();

  @override
  bool setOption(SocketOption option, bool enabled) {
    return setOptionImpl(option, enabled);
  }

  @override
  void setRawOption(RawSocketOption option) {
    return setRawOption(option);
  }
}
