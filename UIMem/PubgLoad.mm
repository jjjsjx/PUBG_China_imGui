//
//  PubgLoad.m
//  pubg
//
//  Created by 李良林 on 2021/2/14.
//

#import "YMUIWindow.h"
#import "ShiSnGeWindow.h"
#import "ShiSanGeViewController.h"
#import "gameVM.h"
#import "PubgLoad.h"
#import <UIKit/UIKit.h>
#import "ImGuiMem.h"
#import "QQ350722326.h"

#import <AVFoundation/AVFoundation.h>
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
        [ImGuiMem sharedInstance];
        [[YMUIWindow sharedInstance] addSubview:[ImGuiMem sharedInstance]];
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)jtyl{
    //音量
    AVAudioSession*audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
}
- (void)volumeChanged:(NSNotification *)notification {
    float 最新音量 = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    if (初始音量!=最新音量) {
        初始音量=最新音量;
        [self volumeChanged];
    }
    NSLog(@"Current volume: %f", 最新音量);
}

- (void)volumeChanged {
    MenDeal = !MenDeal;
    if (getGame()) {
        //移除已经添加到窗口中的 ImGuiMem 实例
        [[ImGuiMem sharedInstance] removeFromSuperview];
        //根据 MenDeal 的值添加新的 ImGuiMem 实例
        if (MenDeal) {
            [[ShiSnGeWindow sharedInstance] addSubview:[ImGuiMem sharedInstance]];
        } else {
            [[YMUIWindow sharedInstance] addSubview:[ImGuiMem sharedInstance]];
        }
        [ImGuiMem sharedInstance].userInteractionEnabled = MenDeal;

        
    }else{
        绘制总开关=false;
    }
    
}


@end
