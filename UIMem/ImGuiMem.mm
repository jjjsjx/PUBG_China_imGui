#import "ShiSnGeWindow.h"
#import "ImGuiMem.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#import "YMUIWindow.h"
#import <shisangeIMGUI/imgui_impl_metal.h>
#import <shisangeIMGUI/imgui.h>
#import <Foundation/Foundation.h>
#import "PubgLoad.h"
#import "gameVM.h"
#import "QQ350722326.h"
#import <UIKit/UIKit.h>
#import "ESP.h"
#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height

@interface ImGuiMem () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;

@end


@implementation ImGuiMem

+ (instancetype)sharedInstance {
    static ImGuiMem *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithFrame:[YMUIWindow sharedInstance].bounds];
        [[ShiSnGeWindow sharedInstance] addSubview:sharedInstance];
    });
    return sharedInstance;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.secureTextEntry=YES;
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        
        if (!self.device) abort();
        
        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImGuiIO& io = ImGui::GetIO(); (void)io;
        
        ImGui::StyleColorsDark();
        //系统默认字体
        //    NSString *FontPath = @"/System/Library/Fonts/LanguageSupport/PingFang.ttc";
        //    io.Fonts->AddFontFromFileTTF(FontPath.UTF8String, 40.f,NULL,io.Fonts->GetGlyphRangesChineseFull());
        //第三方字体
        ImFontConfig config;
        config.FontDataOwnedByAtlas = false;
        io.Fonts->AddFontFromMemoryTTF((void *)jijia_data, jijia_size, 16, NULL,io.Fonts->GetGlyphRangesChineseFull());
        
        
        //加载
        ImGui_ImplMetal_Init(_device);
        
        CGFloat w = CGRectGetWidth(frame);
        CGFloat h = CGRectGetHeight(frame);
        self.mtkView = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h) device:_device];
        self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
        self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        self.mtkView.clipsToBounds = YES;
        self.mtkView.delegate = self;
        self.frame=[YMUIWindow sharedInstance].bounds;
        
        [self.subviews.firstObject addSubview:self.mtkView];
        
        // 禁用键盘响应
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat w = CGRectGetWidth(self.frame);
    CGFloat h = CGRectGetHeight(self.frame);
    self.mtkView.frame = CGRectMake(0, 0, w, h);
}

#pragma mark - MTKViewDelegate


- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;
    
    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 60);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui shisange"];
        
        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();
        
        //默认窗口大小
        CGFloat width =350;//宽度
        CGFloat height =300;//高度
        ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_FirstUseEver);//大小
        
        //默认显示位置 屏幕中央
        CGFloat x = (([ShiSnGeWindow sharedInstance].frame.size.width) - width) / 2;
        CGFloat y = (([ShiSnGeWindow sharedInstance].frame.size.height) - height) / 2;
        
        ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);//默认位置
        //开始绘制==========================
        ImDrawList*MsDrawList = ImGui::GetForegroundDrawList();//读取整个菜单元素
        [self Drawing:MsDrawList];
        
        ImGui::Render();
        ImDrawData* draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
        
        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
        
    }
    [commandBuffer commit];
}

#pragma mark - IMGUI菜单
char 输入框内容[256] = "";
static bool 全选;
static bool 全选绘制;
static bool 一次调用;
- (void)Drawing:(ImDrawList*)drawList
{
    
    if(MenDeal){
        ImGui::Begin("十三哥微信: NongShiFu123");
        
        ImGui::Checkbox("总开关", &绘制总开关);
        ImGui::SameLine();
        ImGui::Checkbox("附近人数", &附近人数开关);
        ImGui::SameLine();
        if(ImGui::Checkbox("过直播", &过直播开关)){
            self.secureTextEntry=过直播开关;
        }
            
        
        ImGui::SameLine();
        ImGui::SameLine();
        ImGui::SameLine();
        if(ImGui::Button("注销")){
            exit(0);
        }
        ImGui::NewLine();
        if (!验证状态) {
            NSString*km=[[NSUserDefaults standardUserDefaults] objectForKey:@"km"];
            bool validated = false;
            ImGui::Text("请先验证");
            ImGui::Text("%s", [验证信息 UTF8String]);
            ImGui::Text("卡密:%s", [km UTF8String]);
            if (ImGui::Button("复制卡密")) {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string=km;
            }
            ImGui::NewLine();
            // 输入框
            ImGui::InputText("##input", 输入框内容, sizeof(输入框内容));
            
            // 粘贴按钮
            if (ImGui::Button("粘贴")) {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                NSString *text = pasteboard.string;
                if (text != nil) {
                    NSLog(@"粘贴=%@",text);
                    strncpy(输入框内容, text.UTF8String, sizeof(输入框内容));
                    ImGui::SetNextItemWidth(-1);
                    ImGui::InputText("##input", 输入框内容, sizeof(输入框内容));
                }
            }
            ImGui::SameLine();
            if (ImGui::Button("清除")) {
                strncpy(输入框内容, @"".UTF8String, sizeof(输入框内容));
                
            }
            ImGui::SameLine();
            
            ImGui::SameLine();
            
            // 确认按钮
            if (ImGui::Button("确认激活")) {
                validated = true;
                if (validated) {
                    validated = false;
                    // 验证通过的逻辑
                    NSString *inputString = [NSString stringWithUTF8String:输入框内容];
                    [[NSUserDefaults standardUserDefaults] setObject:inputString forKey:@"km"];
//                    [NSObject YzCode:^{
//                        NSLog(@"验证");
//                    }];
                   
                }
            }
            
            
        }else{
            //选项卡例子=============
            ImGui::BeginTabBar("绘制功能"); // 开始一个选项卡栏
            
            if (ImGui::BeginTabItem("绘制功能")) // 开始第一个选项卡
            {
                
                // 在这里添加第一个选项卡的内容
                ImGui::Checkbox("信息背景", &背景开关);
                if(ImGui::Checkbox("全选绘制", &全选绘制)){
                    射线开关=全选绘制;
                    血条开关=全选绘制;
                    骨骼开关=全选绘制;
                    名字开关=全选绘制;
                    距离开关=全选绘制;
                    
                }
                ImGui::Checkbox("射线", &射线开关);
                ImGui::SameLine();
                ImGui::ColorEdit4("射线颜色", (float*) &射线颜色);
                
                
                ImGui::Checkbox("血条", &血条开关);
                ImGui::SameLine();
                ImGui::ColorEdit4("血条颜色", (float*) &血条颜色);
                
                ImGui::Checkbox("骨骼", &骨骼开关);
                ImGui::SameLine();
                ImGui::ColorEdit4("骨骼颜色", (float*) &骨骼颜色);
                
                ImGui::Checkbox("名字", &名字开关);
                ImGui::SameLine();
                ImGui::ColorEdit4("名字颜色", (float*) &名字颜色);
                
                ImGui::Checkbox("距离", &距离开关);
                ImGui::SameLine();
                ImGui::ColorEdit4("距离颜色", (float*) &距离颜色);
                
                
                ImGui::Text("绘制越多,越是消耗性能掉帧.高配土豪可忽略。。。");
                
                ImGui::EndTabItem(); // 结束第一个选项卡
            }
            
            if (ImGui::BeginTabItem("物资绘制")) // 开始第二个选项卡
            {
                // 在这里添加第二个选项卡的内容
                ImGui::Checkbox("物资总开关", &物资总开关);
                ImGui::SameLine();
                ImGui::Checkbox("手雷预警", &手雷预警开关);
                ImGui::SameLine();
                if(ImGui::Checkbox("全选物资", &全选)){
                    手持武器开关=全选;高级物资开关=全选;载具开关=全选;倍镜开关=全选;药品开关=全选;枪械开关=全选;配件开关=全选;头盔开关=全选;
                    护甲开关=全选;背包开关=全选;投掷物开关=全选;子弹开关=全选;其他物资开关=全选;
                }
                ImGui::SameLine();
                ImGui::Checkbox("调试模式", &物资调试开关);
                ImGui::NewLine();
                
                ImGui::Checkbox("手持", &手持武器开关);
                ImGui::SameLine();
                ImGui::Checkbox("高级", &高级物资开关);
                ImGui::SameLine();
                ImGui::Checkbox("载具", &载具开关);
                ImGui::SameLine();
                ImGui::Checkbox("倍镜", &倍镜开关);
                
                
                ImGui::Checkbox("药品", &药品开关);
                ImGui::SameLine();
                ImGui::Checkbox("枪械", &枪械开关);
                ImGui::SameLine();
                ImGui::Checkbox("配件", &配件开关);
                
                
                
                ImGui::Checkbox("头盔", &头盔开关);
                ImGui::SameLine();
                ImGui::Checkbox("护甲", &护甲开关);
                ImGui::SameLine();
                ImGui::Checkbox("背包", &背包开关);
                ImGui::SameLine();
                ImGui::Checkbox("投掷物", &投掷物开关);
                
                
                ImGui::Checkbox("子弹", &子弹开关);
                ImGui::SameLine();
                ImGui::Checkbox("其他", &其他物资开关);
                
                ImGui::SameLine();
                ImGui::NewLine();
                ImGui::NewLine();
                ImGui::Text("物资开启可能会掉帧");
                
                ImGui::EndTabItem();
            }
            
            if (ImGui::BeginTabItem("高级功能")) // 开始第二个选项卡
            {
                ImGui::Checkbox("无后座", &无后座开关);ImGui::SameLine();
                ImGui::Checkbox("追踪", &追踪开关);
                ImGui::SliderFloat("追踪半径", &追踪圆圈, 0, 100);
                ImGui::SliderFloat("追踪距离", &追踪距离, 0, 300);
                static const char* items[] = { "头", "胸", "脊柱", "盆骨" , "脚"};
                static int 复选;
                
                if (ImGui::RadioButton(items[0], &复选, 0)) {
                    // 当用户勾选了 "头" 时，将追踪位置设置为6
                    追踪部位 = 6;
                }
                ImGui::SameLine();
                
                if (ImGui::RadioButton(items[1], &复选, 1)) {
                    // 当用户勾选了 "胸" 时，将追踪位置设置为4
                    追踪部位 = 4;
                }
                ImGui::SameLine();
                
                if (ImGui::RadioButton(items[2], &复选, 2)) {
                    // 当用户勾选了 "脊柱" 时，将追踪位置设置为3
                    追踪部位 = 3;
                }
                ImGui::SameLine();
                
                if (ImGui::RadioButton(items[3], &复选, 3)) {
                    // 当用户勾选了 "盆骨" 时，将追踪位置设置为2
                    追踪部位 = 2;
                }
                ImGui::SameLine();
                
                if (ImGui::RadioButton(items[4], &复选, 4)) {
                    // 当用户勾选了 "脚" 时，将追踪位置设置为59
                    追踪部位 = 59;
                }
                
                
                
                ImGui::NewLine();
                ImGui::Checkbox("自瞄", &自瞄开关);
                ImGui::SliderFloat("自瞄速度", &自瞄速度, 1, 20);
                
                ImGui::NewLine();
                ImGui::NewLine();
                
                
                const char* cstr = strdup([到期时间 UTF8String]);
                ImGui::Text("人生如戏-全靠演技 到期时间:%s",cstr);
                ImGui::EndTabItem();
            }
            if (ImGui::BeginTabItem("验证")) // 开始第二个选项卡
            {
                ImGui::NewLine();
                NSString*km=[[NSUserDefaults standardUserDefaults] objectForKey:@"km"];
                const char* kmcstr = strdup([km UTF8String]);
                ImGui::NewLine();
                ImGui::Text("卡密:%s",kmcstr);
                if (ImGui::Button("复制本地卡密")) {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    pasteboard.string=km;
                    
                }
                ImGui::NewLine();
                const char* cstr = strdup([到期时间 UTF8String]);
                ImVec4 color = ImVec4(1.0f, 0.0f, 0.0f, 1.0f); // 红色
                ImGui::PushStyleColor(ImGuiCol_Text, color);
                ImGui::Text("到期时间:%s", cstr);
                ImGui::PopStyleColor();
                
                ImGui::NextColumn();
                ImGui::EndTabItem();
            }
            
            
            ImGui::EndTabBar(); // 结束选项卡栏
            ImGui::NewLine();
            
        }
        
        
        
        ImGui::NewLine();
        ImGui::Text("QQ:350722326 %.1f (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
        
        
        
        ImGui::End();
        
        
    }
    if (绘制总开关 && 验证状态) {
        [[ESP sharedInstance] 绘制玩家:drawList];
    }
    
}
#pragma mark - 触摸互动
#pragma mark - 触摸互动
- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self];
    
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);
    
    
    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled) {
            
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

@end

