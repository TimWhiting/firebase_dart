@JS('gapi')
library gapi;

import 'dart:js_interop';

@JS()
external void load(String libraries, LoadConfig config);

@JS()
extension type LoadConfig._(JSObject _) implements JSObject {
  external LoadConfig({JSFunction callback, JSFunction onerror, num timeout, JSFunction ontimeout});
  external JSFunction get callback;
  external JSFunction get onerror;
  external num get timeout;
  external JSFunction get ontimeout;
}
