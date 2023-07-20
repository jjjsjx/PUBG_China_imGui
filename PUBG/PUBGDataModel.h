//
//  PUBGDataModel.h
//  ChatsNinja
//
//  Created by yiming on 2022/10/2.
//

#import <Foundation/Foundation.h>
#import "PUBGTypeHeader.h"
#import <UIKit/UIKit.h>
#include <string>
NS_ASSUME_NONNULL_BEGIN

@interface PUBGPlayerWZ : NSObject
//物资距离
@property (nonatomic,  assign) float JuLi;
//物资2D坐标系
@property (nonatomic,  assign) FVector2D WuZhi2D;
//物资
@property (nonatomic,  assign) uintptr_t Player;
//物资模型名字
@property (nonatomic,  assign) NSString  * Name;
//分类
@property (nonatomic,  assign) int  Fenlei;
@end



@interface PUBGPlayerModel : NSObject
// 编号
@property (nonatomic,  assign) int TeamID;
@property (nonatomic,  assign) int chiqiang;
// 名称
@property (nonatomic,  assign) NSString *PlayerName;
// 距离
@property (nonatomic,  assign) CGFloat  Distance;
// 血量
@property (nonatomic,  assign) CGFloat  Health;
// 方框
@property (nonatomic,  assign) FVectorRect  rect;
//持枪
@property (nonatomic,  assign) NSString  * WeaponName;
// AI，1是人机，0是真人
@property (nonatomic,  assign) BOOL  isAI;
// 屏幕内外 YES 内 NO 外
@property (nonatomic,  assign) BOOL  isPm;
// 骨架
@property (nonatomic,  assign) FVector2D  _0;
@property (nonatomic,  assign) FVector2D  _1;
@property (nonatomic,  assign) FVector2D  _2;
@property (nonatomic,  assign) FVector2D  _3;
@property (nonatomic,  assign) FVector2D  _4;
@property (nonatomic,  assign) FVector2D  _5;
@property (nonatomic,  assign) FVector2D  _6;
@property (nonatomic,  assign) FVector2D  _7;
@property (nonatomic,  assign) FVector2D  _8;
@property (nonatomic,  assign) FVector2D  _9;
@property (nonatomic,  assign) FVector2D  _10;
@property (nonatomic,  assign) FVector2D  _11;
@property (nonatomic,  assign) FVector2D  _12;
@property (nonatomic,  assign) FVector2D  _13;
@property (nonatomic,  assign) FVector2D  _14;
@property (nonatomic,  assign) FVector2D  _15;
@property (nonatomic,  assign) FVector2D  _16;
@property (nonatomic,  assign) FVector2D  _17;
@end

NS_ASSUME_NONNULL_END
