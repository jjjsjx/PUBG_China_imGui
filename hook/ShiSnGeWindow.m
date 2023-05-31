//
//  ShiSnGeWindow.m
//  Ding
//
//  Created by 十三哥 on 2023/5/25.
//

#import "ShiSnGeWindow.h"

@implementation ShiSnGeWindow
static id _sharedInstance;
static dispatch_once_t _onceToken;
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.windowLevel = UIWindowLevelStatusBar+99999;
        self.clipsToBounds = YES;
        [self setHidden:NO];
        [self setAlpha:1.0];
        [self setBackgroundColor:[UIColor clearColor]];
        
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self.rootViewController.view) {
        return nil;
    }
    NSLog(@"aaaa%s",__func__);
    return view;
}

+ (void)setUserInteractionEnabled:(BOOL)enabled {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [self setUserInteractionEnabled:enabled forView:keyWindow];
}

+ (void)setUserInteractionEnabled:(BOOL)enabled forView:(UIView *)view {
    view.userInteractionEnabled = enabled;
    for (UIView *subview in view.subviews) {
        [self setUserInteractionEnabled:enabled forView:subview];
    }
}
+ (instancetype)sharedInstance
{
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
    });
    return _sharedInstance;
}
+ (void)removeAllSubviewsFromView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        [subview removeFromSuperview];
    }
}
@end
