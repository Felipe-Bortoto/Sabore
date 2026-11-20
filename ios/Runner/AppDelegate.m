#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.pluginRegistrant = self;
  return [super application:application
      didFinishLaunchingWithOptions:launchOptions];
}

- (void)registerWithRegistry:(NSObject<FlutterPluginRegistry> *)registry {
  [GeneratedPluginRegistrant registerWithRegistry:registry];
}

@end
