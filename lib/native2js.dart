import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';

class JsEngine {
  Map<String, Function> __callFns = Map();
  int __id;
  bool _disposed = false;
  Function(JsEngine) onReady;
  String injectJs;

  static int _id = 0;
  static final MethodChannel _channel = const MethodChannel('js.zhang/native2js')..setMethodCallHandler(_handleMethodCall);
  static Map<int, JsEngine> _instances = Map();

  static getAndroidVersion() async {
    return await _channel.invokeMethod('getPlatformVersion');
  }

  JsEngine({this.injectJs, this.onReady}) {
    _instances[__id = _id++] = this;
    _init();
  }

  Future _init() async {
    await _channel.invokeMethod('init', __id);
    await _registerGlobals();

    if (injectJs != null) {
      File file = File(injectJs);
      await evaluate(file.readAsStringSync());
    }

    if (onReady != null) {
      onReady(this);
    }
  }

  Future<dynamic> evaluate(String js) async {
    if (_disposed) return;

    return await _channel.invokeMethod('callJs', {
      'id': __id,
      'js': js,
    });
  }

  register(String x, Function f) async {
    if (_disposed) return;

    __callFns[x] = f;
    await _channel.invokeMethod('registerCall', {
      'id': __id,
      'fn': x,
    });
  }

  get callFns {
    return __callFns;
  }

  dispose() async {
    await _channel.invokeMethod('dispose', __id);
    _instances[__id] = null;
    __callFns = null;
    _disposed = true;
  }

  _registerGlobals() async {
    await evaluate('var self = this; var global = self;');
    await register('__log', (dynamic data) => print('js console: ${data.toString()}'));
    await evaluate('var console = {log: function() {[].forEach.call(arguments, function(x) {__log(x);})}};');
    await evaluate('');
    await register('__callTimer', (Map timer) {
      double wait = timer['wait'];
      Timer(Duration(milliseconds: wait.toInt()), () => evaluate('setTimeout.__call(${timer['id']})'));
    });
    await evaluate('''
      function setTimeout(fn, wait) {
        var id = ++setTimeout.__id;

        if (!wait) {
          wait = 1;
        }

        setTimeout.__fns[id] = fn;
        __callTimer({
          id: id,
          wait: wait
        });
        
        return id;
      };

      function clearTimeout(id) {
        delete setTimeout.__fns[id];
      }
      
      setTimeout.__id = 0;
      setTimeout.__fns = {};
      setTimeout.__call = function(id) {
        var fn = setTimeout.__fns[id];
        
        if (fn) {
          fn();
          clearTimeout(id);
        }
      };
    ''');
  }

  static Future _handleMethodCall(MethodCall methodCall) {
    if (methodCall.method == 'call') {
      Map data = methodCall.arguments;
      JsEngine engine = _instances[data['id']];
      engine.callFns[data['fn']](data['res']);
    } else if (methodCall.method == 'error') {
      print('js error: $methodCall');
    }

    return null;
  }
}
