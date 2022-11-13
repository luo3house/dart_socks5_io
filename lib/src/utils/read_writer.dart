import 'dart:async';

abstract class ReadWriter<In, Out> {
  factory ReadWriter({
    required Stream<In> reader,
    required Sink<Out> writer,
  }) =>
      _SimpleReadWriter(reader: reader, writer: writer);
  Stream<In> getReader();
  Sink<Out> getWriter();
}

class _SimpleReadWriter<In, Out> implements ReadWriter<In, Out> {
  final Stream<In> reader;
  final Sink<Out> writer;
  const _SimpleReadWriter({
    required this.reader,
    required this.writer,
  });

  @override
  Stream<In> getReader() => reader;

  @override
  Sink<Out> getWriter() => writer;
}
