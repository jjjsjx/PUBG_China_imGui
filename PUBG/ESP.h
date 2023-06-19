//
//  ESP.h
//  PUBG
//
//  Created by 十三哥 on 2023/5/31.
//
#import <shisangeIMGUI/imgui_impl_metal.h>
#import <shisangeIMGUI/imgui.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern ImVec4 血条颜色;
extern ImVec4 方框颜色;
extern ImVec4 射线颜色;
extern ImVec4 骨骼颜色;
extern ImVec4 距离颜色;
extern ImVec4 手持武器颜色;
extern ImVec4 名字颜色;

extern bool  绘制总开关,过直播开关, 无后座开关,自瞄开关,追踪开关,手雷预警开关,聚点开关,防抖开关;
extern bool  射线开关,骨骼开关,方框开关,距离开关,血条开关,名字开关,背景开关,边缘开关,附近人数开关,手持武器开关;
extern bool  物资总开关,载具开关,药品开关,投掷物开关,枪械开关,配件开关,子弹开关,其他物资开关,高级物资开关,倍镜开关,头盔开关,护甲开关,背包开关,物资调试开关;
extern float 追踪距离;
extern float 追踪圆圈;
extern int 追踪部位;
extern float 自瞄速度;

@interface ESP : UIView
+ (instancetype)sharedInstance;
- (void)绘制玩家:(ImDrawList*)MsDrawList;
@end

NS_ASSUME_NONNULL_END
