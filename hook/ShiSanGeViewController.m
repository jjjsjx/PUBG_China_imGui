//
//  ShiSanGeViewController.m
//  Ding
//
//  Created by 十三哥 on 2023/5/25.
//

#import "ShiSanGeViewController.h"

@interface ShiSanGeViewController ()

@end

static id _sharedInstance;
static dispatch_once_t _onceToken;

@implementation ShiSanGeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - 事件

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
