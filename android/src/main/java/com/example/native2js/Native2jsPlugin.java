package com.example.native2js;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import com.eclipsesource.v8.V8;
import com.eclipsesource.v8.JavaVoidCallback;
import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Object;
import java.util.*;

/** Native2jsPlugin */
public class Native2jsPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private static Map<Integer, V8> engines = new HashMap<Integer, V8>();
  // private static List engines = List();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "js.zhang/native2js");
    channel.setMethodCallHandler(this);
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "js.zhang/native2js");
    channel.setMethodCallHandler(new Native2jsPlugin());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("init")) {
      Integer id = Integer.parseInt(call.arguments.toString());
      V8 runtime = V8.createV8Runtime();
      engines.put(id, runtime);
      result.success(id);
    }else if (call.method.equals("callJs")) {
      Map<?, ?> arguments = (Map<?, ?>)call.arguments;
      Integer id = Integer.parseInt(arguments.get("id").toString());
      V8 runtime = engines.get(id);
      Object res = runtime.executeScript(arguments.get("js").toString());
      result.success(res.toString());
    } else if (call.method.equals("registerCall")) {
      Map<?, ?> arguments = (Map<?, ?>)call.arguments;
      String fn = arguments.get("fn").toString();
      Integer id = Integer.parseInt(arguments.get("id").toString());
      V8 runtime = engines.get(id);
      runtime.registerJavaMethod(new JsRegistryCallabck(channel, id, fn), fn);
      result.success(0);
    } else if (call.method.equals("dispose")) {
      Integer id = Integer.parseInt(call.arguments.toString());
      V8 runtime = engines.get(id);
      runtime.release();
      engines.remove(id);
      result.success(0);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}

class JsRegistryCallabck implements JavaVoidCallback {
  private MethodChannel channel;
  private Integer id;
  private String name;

  JsRegistryCallabck(MethodChannel channel, Integer id, String name) {
    super();
    this.channel = channel;
    this.id = id;
    this.name = name;
  }

  @Override
  public void invoke(final V8Object receiver, final V8Array parameters) {
    Object x = parameters.get(0);
    HashMap res = new HashMap();
    res.put("id", id);
    res.put("fn", name);

    if (x.getClass().toString().equals("class com.eclipsesource.v8.V8Object")) {
      V8Object y = (V8Object)parameters.get(0);
      String[] keys = y.getKeys();
      Map a = new HashMap();

      for (int i = 0; i < keys.length; i++) {
        a.put(keys[i], y.get(keys[i]));
      }

      res.put("res", a);
    } else {
      res.put("res", x);
    }
    
    channel.invokeMethod("call", res);
  }
}