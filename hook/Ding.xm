
// See http://iphonedevwiki.net/index.php/Logos

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import <UIKit/UIKit.h>
#import "YMUIWindow.h"
#import "YMUIViewController.h"

#import "ShiSnGeWindow.h"
#import "ShiSanGeViewController.h"


static YMUIWindow *window = nil;
static YMUIViewController *controller = nil;

static ShiSnGeWindow *windowb = nil;
static ShiSanGeViewController *controllerb = nil;

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    window = [YMUIWindow sharedInstance];
    window.rootViewController = [YMUIViewController sharedInstance];
    
    windowb = [ShiSnGeWindow sharedInstance];
    windowb.rootViewController = [ShiSanGeViewController sharedInstance];
    
    
    
    [YMUIWindow sharedInstance];
    [ShiSnGeWindow sharedInstance];
    NSLog(@"[yiming] SpringBoard is hooked");
}

%end
