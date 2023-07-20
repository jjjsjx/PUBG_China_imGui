

#import "YMUIWindow.h"

@interface YMUIWindow()
@end

@implementation YMUIWindow
static id _sharedInstance;
static dispatch_once_t _onceToken;
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.windowLevel = UIWindowLevelStatusBar;
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
    
    return view;
}


- (BOOL)_ignoresHitTest {
    
    return YES;
    
}
+ (BOOL)_isSecure
{
    return YES;
}

+ (instancetype)sharedInstance
{
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
    });
    return _sharedInstance;
}




@end
