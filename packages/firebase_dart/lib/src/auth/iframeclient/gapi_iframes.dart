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
      String type, dynamic data, Function onDone, IframesFilter filter);

  external void register(String eventName, IframeEventHandler callback,
      [IframesFilter filter]);
  external void unregister(String eventName, IframeEventHandler callback);
}

@JS()
extension type Context(JSObject _) implements JSObject {
  external void openChild(IframeOptions options);

  external void open(IframeOptions options, [Function(Iframe) onOpen]);
}

@JS()
extension type IframeAttributes._(JSObject _) implements JSObject {
  external CSSStyleDeclaration? get style;

  external IframeAttributes({CSSStyleDeclaration style});
}

@JS()
extension type IframeRestyleOptions._(JSObject _) implements JSObject {
  external bool? get setHideOnLeave;

  external IframeRestyleOptions({bool? setHideOnLeave});
}

@JS()
extension type IframeEvent(JSObject _) implements JSObject {
  external String type;

  external IframeAuthEvent? authEvent;
}

@JS()
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
abstract class IframeError {
  external String code;

  external String message;
}

@JS()
@anonymous
abstract class IframeOptions {
  external String get url;
  external HTMLElement? get where;
  external IframeAttributes? get attributes;
  external IframesFilter? messageHandlersFilter;
  external bool? dontclear;

  external factory IframeOptions(
      {String url,
      HTMLElement? where,
      IframeAttributes? attributes,
      IframesFilter? messageHandlersFilter,
      bool? dontclear});
}

@JS()
external IframesFilter get CROSS_ORIGIN_IFRAMES_FILTER;

@JS()
abstract class IframesFilter {}
