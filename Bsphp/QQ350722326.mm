//
//  ViewController.h
//  Radar
//
//  Created by 十三哥 on 2022/8/19.
//

#import "QQ350722326.h"
#import "LRKeychain.h"
#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

#import "NSString+MD5.h"
#import "Config.h"

#import <AdSupport/ASIdentifierManager.h>
#import "MBProgressHUD+NJ.h"
#include <sys/sysctl.h>
#include <string>
#import <dlfcn.h>
static NSTimer*timer;
NSString*验证信息;
NSString*到期时间;
BOOL 验证状态;

@implementation NSObject (checkStatus)

- (void)YzCode:(void (^)(void))completion
{
    //授权码验证
    MyLog(@"授权码验证函数");
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"api"] = @"login.ic";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_Hans_CN"];
    dateFormatter.calendar = [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
    [dateFormatter setDateFormat:@"yyyy-MM-dd#HH:mm:ss"];
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    param[@"BSphpSeSsL"] = [dateStr MD5Digest];
   
    NSString *nowDateStr = [dateStr stringByReplacingOccurrencesOfString:@"#" withString:@" "];
    param[@"date"] = nowDateStr;
    param[@"md5"] = @"";
    param[@"mutualkey"] = BSPHP_MUTUALKEY;
    param[@"icid"] =[[NSUserDefaults standardUserDefaults]objectForKey:@"km"];
    param[@"icpwd"] = @"";
    param[@"key"] = [self getUDID];
    param[@"maxoror"] = [self getUDID];
    [NetTool Post_AppendURL:BSPHP_HOST myparameters:param mysuccess:^(id responseObject)
     {
        NSError*error;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
        MyLog(@"dicterror=%@",error);
        if (dict)
        {
            NSString *dataString = dict[@"response"][@"data"];
            NSRange range = [dataString rangeOfString:@"|1081|"];
            if (range.location != NSNotFound)
            {
                NSArray *arr = [dataString componentsSeparatedByString:@"|"];
                if (arr.count >= 6)
                {
                     MyLog(@"验证成功");
                    if(![dataString containsString:[NSObject getUDID]]){
                        验证信息=@"授权错误，机器码不正确\n联系管理员解绑或更换卡密";
                        验证状态=NO;
                        if(completion){
                            completion();
                        }
                    }else{
                        
                        到期时间 = [NSString stringWithFormat:@"%@",arr[4]];
                        验证信息=[NSString stringWithFormat:@"验证成功 到期时间:%@",arr[4]];
                        MyLog(@"验证成功=%@",arr[4]);
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            验证状态=YES;
                        });
                        if(completion){
                            completion();
                        }
                    }
                }
            }
            else
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    验证信息= dict[@"response"][@"data"];;
                    MyLog(@"验证失败=%@",验证信息);
                    验证状态=NO;
                    if(completion){
                        completion();
                    }
                });
                
                
            }
        }else{
            验证信息= dict[@"response"][@"data"];;
            验证状态=NO;
            if(completion){
                completion();
            }
        }
    } myfailure:^(NSError *error)
     {
        验证信息= [NSString stringWithFormat:@"error=%@",error];
        验证状态=NO;
        if(completion){
            completion();
        }
    }];
    
    
}
-(NSString*)getUDID{
    MyLog(@"getUDID函数");
    NSString* UDID;
    static CFStringRef (*$MGCopyAnswer)(CFStringRef);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    $MGCopyAnswer = reinterpret_cast<CFStringRef (*)(CFStringRef)>(dlsym(gestalt, "MGCopyAnswer"));
    UDID=(__bridge NSString *)$MGCopyAnswer(CFSTR("SerialNumber"));
    MyLog(@"getUDID函数==%@",UDID);
    return UDID;
}

@end




