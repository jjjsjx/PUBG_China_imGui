//
//  WX:NongShiFu123 QQ:350722326
//  Created by 十三哥 on 2023/5/31.
//  Git:https://github.com/nongshifu/PUBG_China_imGui
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface ImGuiMem : UITextField <UITextFieldDelegate>
extern bool 绘制总开关,过直播开关;
+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
