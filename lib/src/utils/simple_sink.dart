/// Describe a writer
class SimpleSink<T> implements Sink<T> {
  final Function(T data) addImpl;
  final Function() closeImpl;
  SimpleSink({
    required this.addImpl,
    required this.closeImpl,
  });
  @override
  void add(T data) => addImpl(data);

  @override
  void close() => closeImpl();
}
