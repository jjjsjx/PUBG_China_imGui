//
//  WX:NongShiFu123 QQ:350722326
//  Created by 十三哥 on 2023/5/31.
//  Git:https://github.com/nongshifu/PUBG_China_imGui
//
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#import "gameVV.h"
#import "PubgLoad.h"
#import "ImGuiMem.h"
#import "QQ350722326.h"
#import "ShiSnGeWindow.h"
#import "YMUIWindow.h"
@interface PubgLoad()

@end

@implementation PubgLoad

static id _sharedInstance;
static dispatch_once_t _onceToken;
static float 初始音量;
bool MenDeal;
+ (void)load
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"load");
        [[PubgLoad sharedInstance] jtyl];
    });
}
+ (instancetype)sharedInstance
{
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)jtyl{
    //音量
    AVAudioSession*audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    NSLog(@"音量");
}
- (void)volumeChanged:(NSNotification *)notification {
    float 最新音量 = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    if (初始音量!=最新音量) {
        初始音量=最新音量;
        MenDeal = !MenDeal;
        //读取游戏进程 存在才显示菜单 游戏关闭则隐藏菜单
        if (getGame()){
            [self volumeChanged];
        }else{
            MenDeal=false;
            绘制总开关=false;
        }
        
    }
    NSLog(@"Current volume: %f", 最新音量);
}

- (void)volumeChanged {
    //根据 MenDeal 的值添加新的 ImGuiMem 实例
    [[ImGuiMem sharedInstance] removeFromSuperview];
    if (MenDeal) {
        [[ShiSnGeWindow sharedInstance] addSubview:[ImGuiMem sharedInstance]];
    } else {
        [[YMUIWindow sharedInstance] addSubview:[ImGuiMem sharedInstance]];

    }
    //跨进程注销生效 因此需要显示菜单就验证一次 防止到期
    [NSObject YzCode:^{
        
    }];
}


@end
