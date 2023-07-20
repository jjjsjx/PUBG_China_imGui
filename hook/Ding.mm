#line 1 "/Users/shisange/Desktop/IOSTest/IOSTest/IOSTest.xm"



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


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class SpringBoard;
static void (*_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id);

#line 22 "/Users/shisange/Desktop/IOSTest/IOSTest/IOSTest.xm"


static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id application) {
    _logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$(self, _cmd, application);
    
    window = [YMUIWindow sharedInstance];
    window.rootViewController = [YMUIViewController sharedInstance];
    
    windowb = [ShiSnGeWindow sharedInstance];
    windowb.rootViewController = [ShiSanGeViewController sharedInstance];
    
    
    
    [YMUIWindow sharedInstance];
    [ShiSnGeWindow sharedInstance];
    NSLog(@"[yiming] SpringBoard is hooked");
}


static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); { MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$);}} }
#line 41 "/Users/shisange/Desktop/IOSTest/IOSTest/IOSTest.xm"
