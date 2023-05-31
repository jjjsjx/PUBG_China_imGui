

#import "YMUIViewController.h"
static id _sharedInstance;
static dispatch_once_t _onceToken;
@interface YMUIViewController ()
@end

@implementation YMUIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupViews];
}

#pragma mark - 视图

- (void)setupViews
{

}

- (void)showAlet
{

}

#pragma mark - 事件

//- (BOOL)shouldAutorotate
//{
//    // 是否自动旋转
//    return YES;
//}
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
