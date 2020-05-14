#import "Native2jsPlugin.h"
@import JavaScriptCore;

@implementation Native2jsPlugin
static NSMutableDictionary * engines;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"js.zhang/native2js"
            binaryMessenger:[registrar messenger]];
  Native2jsPlugin* instance = [[Native2jsPlugin alloc] init];
  instance.channel = channel;
  engines = [[NSMutableDictionary alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"init" isEqualToString:call.method]) {
    NSNumber * _id = call.arguments;
    JSContext * engine = engines[_id] = [[JSContext alloc] init];
    // 暂时不采用ios实现，采用flutter统一实现
    // engine[@"setTimeout"] = ^(JSValue* function, JSValue* timeout) {
    //   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([timeout toInt32] * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
    //       [function callWithArguments:@[]];
    //   });
    // };
    //异常处理
    engine.exceptionHandler = ^(JSContext *context, JSValue *exception){
      NSMutableDictionary * res = [[NSMutableDictionary alloc] init];
      NSDictionary * error = [exception toDictionary];

      res[@"id"] = _id;
      res[@"message"] = @{
        @"message": [exception toString],
        @"line": error[@"line"]
      };
      [self.channel invokeMethod:@"error" arguments:res];
    };
    
    result(0);
  } else if ([@"dispose" isEqualToString:call.method]) {
    NSNumber * _id = call.arguments;
    engines[_id] = nil;
    [engines removeObjectForKey:_id];
    result(0);
  } else if ([@"callJs" isEqualToString:call.method]) {
    NSNumber * _id = call.arguments[@"id"];
    NSString * _js = call.arguments[@"js"];

    if (engines[_id] == nil) {
      result(0);
    } else {
      JSValue * res = [engines[_id] evaluateScript:_js];
      result([res toString]);
    }
  } else if ([@"registerCall" isEqualToString:call.method]) {
    NSString * fn = call.arguments[@"fn"];
    NSNumber * _id = call.arguments[@"id"];
    engines[_id][fn] = ^(id data){
      NSMutableDictionary * res = [[NSMutableDictionary alloc] init];
      res[@"id"] = _id;
      res[@"fn"] = fn;
      res[@"res"] = data;
      [self.channel invokeMethod:@"call" arguments:res];
    };
    result(0);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
