//
//  YMUIWindow.h
//  ChatsNinja
//
//  Created by yiming on 2022/10/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YMUIWindow : UIWindow
+ (instancetype)sharedInstance;
+ (void)setUserInteractionEnabled:(BOOL)enabled;
+ (void)removeAllSubviewsFromView:(UIView *)view;
@end

NS_ASSUME_NONNULL_END
