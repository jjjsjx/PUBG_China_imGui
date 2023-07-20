

#import "YMUIViewController.h"
static id _sharedInstance;
static dispatch_once_t _onceToken;
@interface YMUIViewController ()
@end

@implementation YMUIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (BOOL)_ignoresHitTest {
    return YES;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // 当前 VC 支持的屏幕方向
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    // 优先的屏幕方向
    return UIInterfaceOrientationLandscapeRight;
}
+ (instancetype)sharedInstance
{
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

@end
