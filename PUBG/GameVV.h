//
//  PUBGDrawDataFactory.h
//  ChatsNinja
//
//  Created by yiming on 2022/10/2.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <vector>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach-o/dyld_images.h>
#include <sys/sysctl.h>
#include <dlfcn.h>

#import "PUBGTypeHeader.h"

#define kAddrMax 0xFFFFFFFFF

NS_ASSUME_NONNULL_BEGIN
int getProcesses(NSString *Name);
mach_port_t getTask(int pid);
vm_map_offset_t getBaseAddress(mach_port_t task);

bool getGame();

@interface GameVV : NSObject
- (void)getNSArray;
- (NSMutableArray*)getData;
- (NSMutableArray*)getwzData;
+ (instancetype)factory;


@end

NS_ASSUME_NONNULL_END
