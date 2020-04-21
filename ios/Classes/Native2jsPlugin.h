#import <Flutter/Flutter.h>

@interface Native2jsPlugin : NSObject<FlutterPlugin>
@property (readwrite, nonatomic, strong) FlutterMethodChannel *channel;
@end
