// ignore_for_file: non_constant_identifier_names

@JS('gapi.iframes')
library gapi.iframes;

import 'package:web/web.dart';

import 'dart:js_interop';

@JS()
external Context getContext();

@JS()
extension type Iframe(JSObject _) implements JSObject  {
  external JSPromise ping();

  external void restyle(IframeRestyleOptions parameters);

  external void send(
      String type, JSObject data, JSFunction onDone, IframesFilter filter);

  external void register(String eventName, IframeEventHandler callback,
      [IframesFilter filter]);
  external void unregister(String eventName, IframeEventHandler callback);
}

@JS()
@anonymous
extension type Context(JSObject _) implements JSObject {
  external void openChild(IframeOptions options);

  external void open(IframeOptions options, [JSFunction onOpen]); // Function(IFrame)
}

@JS()
@anonymous
extension type IframeAttributes._(JSObject _) implements JSObject {
  external CSSStyleDeclaration? get style;

  external IframeAttributes({CSSStyleDeclaration style});
}

@JS()
@anonymous
extension type IframeRestyleOptions._(JSObject _) implements JSObject {
  external bool? get setHideOnLeave;

  external IframeRestyleOptions({bool? setHideOnLeave});
}

@JS()
@anonymous
extension type IframeEvent(JSObject _) implements JSObject {
  external String type;

  external IframeAuthEvent? authEvent;
}

@JS()
@anonymous
extension type IframeEventHandlerResponse._(JSObject _) implements JSObject {
  external String get status;

  external IframeEventHandlerResponse({String status});
}

typedef IframeEventHandler = JSFunction; // IframeEventHandlerResponse Function(IframeEvent, Iframe);

@JS()
@anonymous
extension type IframeAuthEvent(JSObject _) implements JSObject  {
  external String? eventId;

  external String? postBody;

  external String? sessionId;

  external String? providerId;

  external String? tenantId;

  external String type;

  external String? urlResponse;

  external IframeError? error;
}

@JS()
@anonymous
extension type IframeError(JSObject _) implements JSObject {
  external String code;

  external String message;
}

@JS()
@anonymous
extension type IframeOptions._(JSObject _) implements JSObject {
  external String get url;
  external HTMLElement? get where;
  external IframeAttributes? get attributes;
  external IframesFilter? messageHandlersFilter;
  external bool? dontclear;

  external IframeOptions(
      {required String url,
      HTMLElement? where,
      IframeAttributes? attributes,
      IframesFilter? messageHandlersFilter,
      bool? dontclear});
}

@JS()
external IframesFilter get CROSS_ORIGIN_IFRAMES_FILTER;

@JS()
extension type IframesFilter(JSObject _) implements JSObject {}
