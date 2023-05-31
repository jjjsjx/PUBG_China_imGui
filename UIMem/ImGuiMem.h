//
//  ImGuiDrawView.h
//  ImGuiTest
//
//  Created by yiming on 2021/6/2.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface ImGuiMem : UITextField <UITextFieldDelegate>
extern bool 绘制总开关,过直播开关;
+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
