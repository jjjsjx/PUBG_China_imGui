//
//  WX:NongShiFu123 QQ:350722326
//  Created by 十三哥 on 2023/5/31.
//  Git:https://github.com/nongshifu/PUBG_China_imGui
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (checkStatus)<UIAlertViewDelegate>

extern BOOL 验证状态;
extern NSString*验证信息;
extern NSString*到期时间;
- (void)YzCode:(void (^)(void))completion;
@end

NS_ASSUME_NONNULL_END
