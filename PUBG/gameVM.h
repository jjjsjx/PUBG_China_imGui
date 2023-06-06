//
//  PUBGDrawDataFactory.m
//  十三哥 编写
//
//  Created by yiming on 2023/05/23. 最少得代码 最全的功能
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach-o/dyld_images.h>
#include <sys/sysctl.h>
#include <dlfcn.h>
#import "PUBGTypeHeader.h"

#import <shisangeIMGUI/imgui_impl_metal.h>
#import <shisangeIMGUI/imgui.h>

#define kAddrMax 0xFFFFFFFFF
#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
NS_ASSUME_NONNULL_BEGIN
int getProcesses(NSString *Name);
mach_port_t getTask(int pid);
vm_map_offset_t getBaseAddress(mach_port_t task);
bool getGame();
typedef void (^PUBGBlock)(NSArray *playerArray,NSArray *wzArray);

@interface gameVM : NSObject
- (void)getData:(PUBGBlock)block;
+ (instancetype)sharedInstance;
- (void)CacheData;

@end


NS_ASSUME_NONNULL_END
