/// Timeouts and cancellation for the PDF engines.
library;

import 'dart:async';

import 'engine.dart';

/// The result of [future], unless [timeout] passes first ([TimeoutException])
/// or [abortTrigger] completes first ([PdfAbortedException]). [onCancel] runs
/// in both of those cases.
///
/// A late error of [future] is always handled, so it can never surface as an
/// uncaught error.
Future<T> guard<T>(
  Future<T> future, {
  required Duration timeout,
  required String what,
  Future<void>? abortTrigger,
  void Function()? onCancel,
}) {
  final out = Completer<T>();
  void cancel(Object error) {
    if (out.isCompleted) return;
    out.completeError(error, StackTrace.current);
    onCancel?.call();
  }

  final timer = Timer(
    timeout,
    () =>
        cancel(TimeoutException('lifeastroapi/pdf: $what timed out', timeout)),
  );
  if (abortTrigger != null) {
    // As in the client: a trigger that fails cancels too.
    unawaited(abortTrigger.then(
      (_) => cancel(const PdfAbortedException()),
      onError: (Object _) => cancel(const PdfAbortedException()),
    ));
  }
  unawaited(future.then((value) {
    if (!out.isCompleted) out.complete(value);
  }, onError: (Object error, StackTrace stack) {
    if (!out.isCompleted) out.completeError(error, stack);
  }));
  return out.future.whenComplete(timer.cancel);
}
