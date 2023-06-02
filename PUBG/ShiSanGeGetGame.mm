
#import <mach-o/dyld.h>
#import <mach/mach.h>
#include <mach/mach.h>
#include <sys/sysctl.h>
#include <math.h>
#import <dlfcn.h>
#import <stdio.h>
#include <string>

#import "PUBGDataModel.h"
#import "ShiSanGeGetGame.h"
#import "gameVM.h"
#import "ESP.h"
#import "PUBGTypeHeader.h"

#define kWidth  [UIScreen mainScreen].bounds.size.width//获取屏幕宽度
#define kHeight [UIScreen mainScreen].bounds.size.height//获取屏幕高度
//声明全局Task
static mach_port_t task;
long GBase;
long Gworld;
long GName;
static FMinimalViewInfo POV;
#pragma mark - 内存读写
extern "C" kern_return_t
mach_vm_region_recurse(
                       vm_map_t                 map,
                       mach_vm_address_t        *address,
                       mach_vm_size_t           *size,
                       uint32_t                 *depth,
                       vm_region_recurse_info_t info,
                       mach_msg_type_number_t   *infoCnt);
static bool isValidAddress(long addr) {
    return addr > 0x100000000 && addr < 0x2000000000;
}

static bool Read(long addr, void *buffer, int len)
{
    if (!isValidAddress(addr)) return false;
    vm_size_t size = 0;
    kern_return_t error = vm_read_overwrite(task, (vm_address_t)addr, len, (vm_address_t)buffer, &size);
    if(error != KERN_SUCCESS || size != len)
    {
        return false;
    }
    return true;
}

template<typename T> T Read(long address) {
    T data;
    Read(address, reinterpret_cast<void *>(&data), sizeof(T));
    return data;
}
#pragma mark - 进程相关

//获取PID
static int getPIDByName(const char *processName) {
    size_t length = 0;
    static const int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    int err = sysctl((int *)mib, (sizeof(mib) / sizeof(*mib)) - 1, NULL, &length, NULL, 0);
    if (err == -1) {
        err = errno;
    }
    if (err == 0) {
        struct kinfo_proc *procBuffer = (struct kinfo_proc *)malloc(length);
        if(procBuffer == NULL) {
            return -1;
        }
        sysctl( (int *)mib, (sizeof(mib) / sizeof(*mib)) - 1, procBuffer, &length, NULL, 0);
        int count = (int)length / sizeof(struct kinfo_proc);
        for (int i = 0; i < count; ++i) {
            const char *procname = procBuffer[i].kp_proc.p_comm;
            if (strstr(procname, processName)) {
                return procBuffer[i].kp_proc.p_pid;
            }
        }
    }
    return -1;
}
//获取Task
static task_t getTaskForPID(pid_t pid) {
    task = MACH_PORT_NULL;
    kern_return_t kr = task_for_pid(mach_task_self(), pid, &task);
    if (kr != KERN_SUCCESS) {
        return MACH_PORT_NULL;
    }
    return task;
}
// 读取进程BaseAddress

static vm_map_offset_t GetBaseAddress(mach_port_t task)
{
    vm_map_offset_t vmoffset = 0;
    vm_map_size_t vmsize = 0;
    uint32_t nesting_depth = 0;
    struct vm_region_submap_info_64 vbr;
    mach_msg_type_number_t vbrcount = 16;
    kern_return_t kret = mach_vm_region_recurse(task, &vmoffset, &vmsize, &nesting_depth, (vm_region_recurse_info_t)&vbr, &vbrcount);
    if (kret == KERN_SUCCESS) {
        NSLog(@"[十三哥] %s : %016llX %lld bytes.", __func__, vmoffset, vmsize);
    } else {
        NSLog(@"[十三哥] %s : FAIL.", __func__);
    }

    return vmoffset;
}
bool getGame(const char *processName){
    pid_t gamePid = getPIDByName(processName);
    if (gamePid != -1) {
        task = getTaskForPID(gamePid);
        if (task) {
            GBase = GetBaseAddress(task);
            if (isValidAddress(GBase)){
                return YES;
            }
            
        }
    }
    
    return NO;
}

#pragma mark - 读取游戏模型名字
static std::string GetFName(long actorAddress) {
    UInt32 FNameID = Read<UInt32>(actorAddress + 0x18);
    uintptr_t TNameEntryArray = Read<uintptr_t>(GBase + GName);
    uintptr_t FNameEntryArr = Read<uintptr_t>(TNameEntryArray + ((FNameID / 0x4000) * 8));
    uintptr_t FNameEntry = Read<uintptr_t>(FNameEntryArr + ((FNameID % 0x4000) * 8));

    unsigned int size = 100;
    std::string name(size, '\0');
    Read(FNameEntry + 0xE, (void *)name.data(), size * sizeof(char));
    name.resize(strlen(name.c_str()));
    name.shrink_to_fit();

    return name;
}

static std::string getPlayerName(uintptr_t player) {
    char Name[128];
    unsigned short buf16[16] = {0};
    uintptr_t PlayerName = Read<uintptr_t>(player + 0xb50);
    if (!isValidAddress(PlayerName)) return std::string();;
    
    if (Read(PlayerName, buf16, 28)) return std::string();

    unsigned short *tempbuf16 = buf16;
    char *tempbuf8 = Name;
    char *buf8 = tempbuf8 + 32;
    for (int i = 0; i < 28 && tempbuf8 + 3 < buf8; i++) {
        if (*tempbuf16 <= 0x007F) {
            *tempbuf8++ = (char) *tempbuf16;
        } else if (*tempbuf16 <= 0x07FF) {
            *tempbuf8++ = (*tempbuf16 >> 6) | 0xC0;
            *tempbuf8++ = (*tempbuf16 & 0x3F) | 0x80;
        } else {
            *tempbuf8++ = (*tempbuf16 >> 12) | 0xE0;
            *tempbuf8++ = ((*tempbuf16 >> 6) & 0x3F) | 0x80;
            *tempbuf8++ = (*tempbuf16 & 0x3F) | 0x80;
        }
        tempbuf16++;
    }
    *tempbuf8 = '\0';

    return std::string(Name);
}

#pragma mark - 字符串工具函数
//全匹配
static bool isEqual(std::string s1, std::string s2) {
    return (s1 == s2);
}
//关键字
static bool isContain(std::string str, const char* check) {
    size_t found = str.find(check);
    return (found != std::string::npos);
}

#pragma mark - 获取资源名字 分类
static bool isPlayer(std::string FName) {
    return isContain(FName, "BP_TrainPlayerPawn") || isContain(FName, "BP_PlayerPawn");
}

static std::string getzaijuFName(std::string FName) {
    if (isContain(FName, "Scooter")) {
        return "小绵羊";
    }
    if (isContain(FName, "Motorcycle_C")) {
        return "摩托车";
    }
    if (isContain(FName, "MotorcycleCart")) {
        return "三蹦子";
    }
    if (isContain(FName, "VH_Buggy")) {
        return "蹦蹦";
    }
    if (isContain(FName, "PickUp_0")) {
        return "皮卡";
    }
    if (isContain(FName, "Mirado_")) {
        return "跑车";
    }
    if (isContain(FName, "Dacia")) {
        return "轿车";
    }
    if (isContain(FName, "UAZ")) {
        return "吉普";
    }
    if (isContain(FName, "AquaRail_")) {
        return "冲锋艇";
    }
    if (isContain(FName, "ny.01")) {
        return "皮卡车";
    }
    if (isContain(FName, "Destru")) {
        return "汽油";
    }
    if (isContain(FName, "CoupeRB")) {
        return "双座跑车";
    }
    if (isContain(FName, "SciFi_Moto")) {
        return "波波球";
    }
    
    if (isContain(FName, "PickUpListWrapperActor")) {
        return "骨灰盒";
    }
    
    if (isContain(FName, "DropPlane")) {
        return "空投飞机";
    }
    if (isContain(FName, "AirDrop")) {
        return "[好东西]空投箱";
    }
    
    if (isContain(FName, "BRDM")) {
        return "装甲车";
    }
    if (isContain(FName,"PG117")) {
        return "大船";
    }
    
    return "";
}

static std::string getqiagnxieFName(std::string FName) {
    if (isContain(FName,"M416")) {
        return "M416";
    }
    if (isContain(FName,"M417")) {
        return "[好东西]M417";
    }
    if (isContain(FName,"VAL")) {
        return "VAL";
    }
    if (isContain(FName,"AKM")) {
        return "AKM";
    }
    if (isContain(FName,"AUG")) {
        return "AUG";
    }
    if (isContain(FName,"Groza")) {
        return "[好东西]Groza";
    }
    if (isContain(FName,"M16A4")) {
        return "M16A4";
    }
    if (isContain(FName,"SKS")) {
        return "SKS";
    }
    if (isContain(FName,"VSS")) {
        return "VSS";
    }
    if (isContain(FName,"AWM")) {
        return "[好东西]AWM";
    }
    
    if (isContain(FName,"AMR")) {
        return "[好东西]AMR";
    }
    if (isContain(FName,"UMP")) {
        return "UMP45";
    }
    if (isContain(FName,"DP28")) {
        return "大盘鸡";
    }
    if (isContain(FName,"Vector")) {
        return "维克托";
    }
    if (isContain(FName,"M762")) {
        return "M762";
    }
    if (isContain(FName,"M249")) {
        return "M249";
    }
    if (isContain(FName,"M24")) {
        return "M24";
    }
    if (isContain(FName,"SCAR")) {
        return "SCAR-L";
    }
    if (isContain(FName,"QBZ")) {
        return "QBZ";
    }
    if (isContain(FName,"MG3")) {
        return "[好东西]MG3";
    }
    if (isContain(FName,"98")) {
        return "Kar98k";
    }
    if (isContain(FName,"Mini14")) {
        return "Mini14";
    }
    if (isContain(FName,"Mk14")) {
        return "Mk14";
    }
    if (isContain(FName,"P90CG17")) {
        return "[好东西]P90CG17";
    }
    if (isContain(FName,"revivalAED")) {
        return "[好东西]自救器";
    }
    return "";
}

static std::string getArmorWithFName(std::string FName) {
    if (isContain(FName, "PickUp_BP_Helmet_Lv2_C") || isEqual(FName, "PickUp_BP_Helmet_Lv2_A_C") || isEqual(FName, "PickUp_BP_Helmet_Lv2_B_C")) {
        return "二级头";
    }
    if (isContain(FName, "PickUp_BP_Armor_Lv2_C") || isEqual(FName, "PickUp_BP_Armor_Lv2_A_C") || isEqual(FName, "PickUp_BP_Armor_Lv2_B_C")) {
        return "二级甲";
    }
    if (isContain(FName, "PickUp_BP_Bag_Lv2_C") || isEqual(FName, "PickUp_BP_Bag_Lv2_A_C") || isEqual(FName, "PickUp_BP_Bag_Lv2_B_C")) {
        return "二级包";
    }
    if (isContain(FName, "PickUp_BP_Helmet_Lv3_C") || isEqual(FName, "PickUp_BP_Helmet_Lv3_A_C") || isEqual(FName, "PickUp_BP_Helmet_Lv3_B_C")) {
        return "三级头";
    }
    if (isContain(FName, "PickUp_BP_Armor_Lv3_C") || isEqual(FName, "PickUp_BP_Armor_Lv3_A_C") || isEqual(FName, "PickUp_BP_Armor_Lv3_B_C")) {
        return "三级甲";
    }
    return "";
}

static std::string getSightWithFName(std::string FName) {
    if (isContain(FName, "BP_MZJ_3X_Pickup_C")) {
        return "3倍瞄准镜";
    }
    if (isContain(FName, "BP_MZJ_4X_Pickup_C")) {
        return "4倍瞄准镜";
    }
    if (isContain(FName, "BP_MZJ_6X_Pickup_C")) {
        return "6倍瞄准镜";
    }
    return "";
}

static std::string getAccessoryWithFName(std::string FName) {
    if (isContain(FName, "BP_QK_Mid_Compensator_Pickup_C")) {
        return "冲锋枪补偿器";
    }
    if (isContain(FName, "BP_QK_Large_Compensator_Pickup_C")) {
        return "步枪补偿器";
    }
    if (isContain(FName, "BP_QT_UZI_Pickup_C")) {
        return "UZI枪托";
    }
    if (isContain(FName, "BP_QT_A_Pickup_C")) {
        return "战术枪托";
    }
    
    if (isContain(FName, "BP_WB_LightGrip_Pickup_C")) {
        return "轻型握把";
    }
    return "";
}

static std::string getBulletWithFName(std::string FName) {
    if (isContain(FName, "BP_Ammo_762mm_Pickup_C")) {
        return "[子弹]762";
    }
    if (isContain(FName, "BP_Ammo_556mm_Pickup_C")) {
        return "[子弹]556";
    }
    return "";
}

static std::string getDrugWithFName(std::string FName) {
    if (isContain(FName, "Injection_Pickup_C")) {
        return "肾上腺素";
    }
    if (isContain(FName, "Firstaid_Pickup_C")) {
        return "急救包";
    }
    
    if (isContain(FName, "Drink_Pickup_C")) {
        return "能量饮料";
    }
    return "";
}

static std::string getEarlyWarningWithFName(std::string FName) {
    if (isContain(FName, "ProjGrenade_BP_C")) {
        return "小心手雷！";
    }
    if (isContain(FName, "ProjFire_BP_C")) {
        return "小心闪光弹！";
    }
    if (isContain(FName, "ProjBurn_BP_C")) {
        return "小心燃烧瓶！";
    }
    return "";
}

static std::string getReFName(std::string FName ,int Fenlei) {
    if (isContain(FName, "ProjGrenade_BP_C")) {
        return "小心手雷！";
    }
    if (isContain(FName, "ProjFire_BP_C")) {
        return "小心闪光弹！";
    }
    if (isContain(FName, "ProjBurn_BP_C")) {
        return "小心燃烧瓶！";
    }
    return std::string();
}

#pragma mark - 坐标转换===============
static FVector3D minusTheVector(FVector3D first, FVector3D second)
{
    static FVector3D ret;
    ret.X = first.X - second.X;
    ret.Y = first.Y - second.Y;
    ret.Z = first.Z - second.Z;
    return ret;
}

static float theDot(FVector3D v1, FVector3D v2)
{
    return v1.X * v2.X + v1.Y * v2.Y + v1.Z * v2.Z;
}

static float getDistance(FVector3D a, FVector3D b)
{
    static FVector3D ret;
    ret.X = a.X - b.X;
    ret.Y = a.Y - b.Y;
    ret.Z = a.Z - b.Z;
    return sqrt(ret.X * ret.X + ret.Y * ret.Y + ret.Z * ret.Z);
}

static D3DXMATRIX toMATRIX(FRotator rot)
{
    static float RadPitch, RadYaw, RadRoll, SP, CP, SY, CY, SR, CR;
    D3DXMATRIX M;
    
    RadPitch = rot.Pitch * M_PI / 180;
    RadYaw = rot.Yaw * M_PI / 180;
    RadRoll = rot.Roll * M_PI / 180;
    
    SP = sin(RadPitch);
    CP = cos(RadPitch);
    SY = sin(RadYaw);
    CY = cos(RadYaw);
    SR = sin(RadRoll);
    CR = cos(RadRoll);
    
    M._11 = CP * CY;
    M._12 = CP * SY;
    M._13 = SP;
    M._14 = 0.f;
    
    M._21 = SR * SP * CY - CR * SY;
    M._22 = SR * SP * SY + CR * CY;
    M._23 = -SR * CP;
    M._24 = 0.f;
    
    M._31 = -(CR * SP * CY + SR * SY);
    M._32 = CY * SR - CR * SP * SY;
    M._33 = CR * CP;
    M._34 = 0.f;
    
    M._41 = 0.f;
    M._42 = 0.f;
    M._43 = 0.f;
    M._44 = 1.f;
    
    return M;
}

#pragma mark - 世界坐标转屏幕2D坐标
static void getTheAxes(FRotator rot, FVector3D *x, FVector3D *y, FVector3D *z){
    D3DXMATRIX M = toMATRIX(rot);
    
    x->X = M._11;
    x->Y = M._12;
    x->Z = M._13;
    
    y->X = M._21;
    y->Y = M._22;
    y->Z = M._23;
    
    z->X = M._31;
    z->Y = M._32;
    z->Z = M._33;
}
static FVector2D worldToScreen(FVector3D worldLocation, FMinimalViewInfo camViewInfo){
    static FVector2D Screenlocation;
    static FVector2D canvas;
    canvas.X=kWidth;
    canvas.Y=kHeight;
    FVector3D vAxisX, vAxisY, vAxisZ;
    getTheAxes(camViewInfo.Rotation, &vAxisX, &vAxisY, &vAxisZ);
    
    FVector3D vDelta = minusTheVector(worldLocation, camViewInfo.Location);
    FVector3D vTransformed;
    
    vTransformed.X = theDot(vDelta, vAxisY);
    vTransformed.Y = theDot(vDelta, vAxisZ);
    vTransformed.Z = theDot(vDelta, vAxisX);
    
    if (vTransformed.Z < 1.0f) {
        vTransformed.Z = 1.0f;
    }
    
    float FOV = camViewInfo.FOV;
    float ScreenCenterX = canvas.X / 2;
    float ScreenCenterY = canvas.Y / 2;
    float BonesX=ScreenCenterX + vTransformed.X * (ScreenCenterX / tanf(FOV * (float)M_PI / 360.f)) / vTransformed.Z;
    float BonesY=ScreenCenterY - vTransformed.Y * (ScreenCenterX / tanf(FOV * (float)M_PI / 360.f)) / vTransformed.Z;
    
    
    Screenlocation.X = BonesX;
    Screenlocation.Y = BonesY;
    
    return Screenlocation;
}
static FVectorRect worldToScreenForRect(FVector3D worldLocation, FMinimalViewInfo camViewInfo)
{
    FVectorRect rect;
    
    FVector3D Pos2 = worldLocation;
    Pos2.Z += 90.f;
    
    
    FVector2D CalcPos = worldToScreen(worldLocation ,camViewInfo);
    
    FVector2D CalcPos2 = worldToScreen(Pos2 ,camViewInfo);
    
    rect.H = CalcPos.Y - CalcPos2.Y;
    rect.W = rect.H / 2.5;
    rect.X = CalcPos.X - rect.W;
    rect.Y = CalcPos2.Y;
    rect.W = rect.W * 2;
    rect.H = rect.H * 2;
    
    return rect;
}

#pragma mark - 玩家骨骼相关=========
static D3DXMATRIX toMatrixWithScale(FVector4D rotation, FVector3D translation, FVector3D scale3D){
    static D3DXMATRIX ret;
    
    float x2, y2, z2, xx2, yy2, zz2, yz2, wx2, xy2, wz2, xz2, wy2 = 0.f;
    ret._41 = translation.X;
    ret._42 = translation.Y;
    ret._43 = translation.Z;
    
    x2 = rotation.X * 2;
    y2 = rotation.Y * 2;
    z2 = rotation.Z * 2;
    
    xx2 = rotation.X * x2;
    yy2 = rotation.Y * y2;
    zz2 = rotation.Z * z2;
    
    ret._11 = (1 - (yy2 + zz2)) * scale3D.X;
    ret._22 = (1 - (xx2 + zz2)) * scale3D.Y;
    ret._33 = (1 - (xx2 + yy2)) * scale3D.Z;
    
    yz2 = rotation.Y * z2;
    wx2 = rotation.W * x2;
    ret._32 = (yz2 - wx2) * scale3D.Z;
    ret._23 = (yz2 + wx2) * scale3D.Y;
    
    xy2 = rotation.X * y2;
    wz2 = rotation.W * z2;
    ret._21 = (xy2 - wz2) * scale3D.Y;
    ret._12 = (xy2 + wz2) * scale3D.X;
    
    xz2 = rotation.X * z2;
    wy2 = rotation.W * y2;
    ret._31 = (xz2 + wy2) * scale3D.Z;
    ret._13 = (xz2 - wy2) * scale3D.X;
    
    ret._14 = 0.f;
    ret._24 = 0.f;
    ret._34 = 0.f;
    ret._44 = 1.f;
    
    return ret;
}

static D3DXMATRIX matrixMultiplication(D3DXMATRIX M1, D3DXMATRIX M2)
{
    static D3DXMATRIX ret;
    ret._11 = M1._11 * M2._11 + M1._12 * M2._21 + M1._13 * M2._31 + M1._14 * M2._41;
    ret._12 = M1._11 * M2._12 + M1._12 * M2._22 + M1._13 * M2._32 + M1._14 * M2._42;
    ret._13 = M1._11 * M2._13 + M1._12 * M2._23 + M1._13 * M2._33 + M1._14 * M2._43;
    ret._14 = M1._11 * M2._14 + M1._12 * M2._24 + M1._13 * M2._34 + M1._14 * M2._44;
    ret._21 = M1._21 * M2._11 + M1._22 * M2._21 + M1._23 * M2._31 + M1._24 * M2._41;
    ret._22 = M1._21 * M2._12 + M1._22 * M2._22 + M1._23 * M2._32 + M1._24 * M2._42;
    ret._23 = M1._21 * M2._13 + M1._22 * M2._23 + M1._23 * M2._33 + M1._24 * M2._43;
    ret._24 = M1._21 * M2._14 + M1._22 * M2._24 + M1._23 * M2._34 + M1._24 * M2._44;
    ret._31 = M1._31 * M2._11 + M1._32 * M2._21 + M1._33 * M2._31 + M1._34 * M2._41;
    ret._32 = M1._31 * M2._12 + M1._32 * M2._22 + M1._33 * M2._32 + M1._34 * M2._42;
    ret._33 = M1._31 * M2._13 + M1._32 * M2._23 + M1._33 * M2._33 + M1._34 * M2._43;
    ret._34 = M1._31 * M2._14 + M1._32 * M2._24 + M1._33 * M2._34 + M1._34 * M2._44;
    ret._41 = M1._41 * M2._11 + M1._42 * M2._21 + M1._43 * M2._31 + M1._44 * M2._41;
    ret._42 = M1._41 * M2._12 + M1._42 * M2._22 + M1._43 * M2._32 + M1._44 * M2._42;
    ret._43 = M1._41 * M2._13 + M1._42 * M2._23 + M1._43 * M2._33 + M1._44 * M2._43;
    ret._44 = M1._41 * M2._14 + M1._42 * M2._24 + M1._43 * M2._34 + M1._44 * M2._44;
    return ret;
}

static FTransform getMatrixConversion(uintptr_t address){
    static FTransform ret;
    int len = sizeof(float);
    Read(address, &ret.Rotation.X, len);
    Read(address+4, &ret.Rotation.Y, len);
    Read(address+8, &ret.Rotation.Z, len);
    Read(address+12, &ret.Rotation.W, len);

    Read(address+16, &ret.Translation.X, len);
    Read(address+20, &ret.Translation.Y, len);
    Read(address+24, &ret.Translation.Z, len);

    Read(address+32, &ret.Scale3D.X, len);
    Read(address+36, &ret.Scale3D.Y, len);
    Read(address+40, &ret.Scale3D.Z, len);

    return ret;
}
static FVector3D getBoneWithRotation(uintptr_t mesh, int Id, FTransform publicObj){
    static FTransform BoneMatrix;
    static FVector3D output = {0, 0, 0};
    
    uintptr_t addr;
   
    if (!Read(mesh + 0x6f0, &addr, sizeof(uintptr_t))) {
        return output;
    }
    BoneMatrix = getMatrixConversion(addr + Id * 0x30);
    
    D3DXMATRIX LocalSkeletonMatrix =toMatrixWithScale(BoneMatrix.Rotation, BoneMatrix.Translation, BoneMatrix.Scale3D);
    
    D3DXMATRIX PartTotheWorld = toMatrixWithScale(publicObj.Rotation, publicObj.Translation, publicObj.Scale3D);
    
    D3DXMATRIX NewMatrix = matrixMultiplication(LocalSkeletonMatrix, PartTotheWorld);
    
    FVector3D BoneCoordinates;
    BoneCoordinates.X = NewMatrix._41;
    BoneCoordinates.Y = NewMatrix._42;
    BoneCoordinates.Z = NewMatrix._43;
    
    return BoneCoordinates;
}

static FVector3D getRelativeLocation(uintptr_t actor){
    uintptr_t RootComponent = Read<uintptr_t>(actor + 0x270);
    static FVector3D value;
    
    Read(RootComponent + 0x1d0, &value, sizeof(FVector3D));
    return value;
}
#pragma mark - 追踪函数
static bool getInsideFov(FVector2D bone, float radius) {
    FVector2D Cenpoint;
    Cenpoint.X = bone.X - (kWidth / 2);
    Cenpoint.Y = bone.Y - (kHeight / 2);
    if (Cenpoint.X * Cenpoint.X + Cenpoint.Y * Cenpoint.Y <= radius * radius) {
        return true;
    }
    return false;
}

static int getCenterOffsetForVector(FVector2D point) {
    return sqrt(pow(point.X - kWidth/2, 2.0) + pow(point.Y - kHeight/2, 2.0));
}

static FRotator calcAngle(FVector3D aimPos) {
    FRotator rot;
    rot.Yaw = ((float)(atan2f(aimPos.Y, aimPos.X)) * (float)(180.f / M_PI));
    rot.Pitch = ((float)(atan2f(aimPos.Z,
                                sqrtf(aimPos.X * aimPos.X +
                                      aimPos.Y * aimPos.Y +
                                      aimPos.Z * aimPos.Z))) * (float)(180.f / M_PI));
    rot.Roll = 0.f;
    return rot;
}

static FRotator clamp(FRotator Rotation) {
    if (Rotation.Yaw > 180.f) {
        Rotation.Yaw -= 360.f;
    } else if (Rotation.Yaw < -180.f) {
        Rotation.Yaw += 360.f;
    }
    
    if (Rotation.Pitch > 180.f) {
        Rotation.Pitch -= 360.f;
    } else if (Rotation.Pitch < -180.f) {
        Rotation.Pitch += 360.f;
    }
    
    if (Rotation.Pitch < -89.f) {
        Rotation.Pitch = -89.f;
    } else if (Rotation.Pitch > 89.f) {
        Rotation.Pitch = 89.f;
    }
    
    Rotation.Roll = 0.f;
    
    return Rotation;
}

#pragma mark - IFuckYou
@interface ShiSanGeGetGame ()
@property (nonatomic,strong) NSMutableArray * 人物缓存;
@property (nonatomic,strong) NSMutableArray * 物资缓存;
@end

@implementation ShiSanGeGetGame
+ (instancetype)sharedInstance
{
    static ShiSanGeGetGame *fact;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fact = [[ShiSanGeGetGame alloc] init];
    });
    return fact;
}
#pragma mark - 追踪函数
- (FRotator)clamp:(FRotator)Rotation
{
    if (Rotation.Yaw > 180.f) {
        Rotation.Yaw -= 360.f;
    } else if (Rotation.Yaw < -180.f) {
        Rotation.Yaw += 360.f;
    }
    
    if (Rotation.Pitch > 180.f) {
        Rotation.Pitch -= 360.f;
    } else if (Rotation.Pitch < -180.f) {
        Rotation.Pitch += 360.f;
    }
    
    if (Rotation.Pitch < -89.f) {
        Rotation.Pitch = -89.f;
    } else if (Rotation.Pitch > 89.f) {
        Rotation.Pitch = 89.f;
    }
    
    Rotation.Roll = 0.f;
    
    return Rotation;
}
#pragma mark - 手持武器
- (NSString*)souchistr:(int)wqid{
    static NSDictionary *souchiNames = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        souchiNames = @{
            @(0): @"拳头",
            @(101001): @"AKM",
            @(101002): @"M16A-4",
            @(101003): @"SCAR-L",
            @(101004): @"M416",
            @(101005): @"Groza",
            @(101006): @"AUG",
            @(101007): @"QBZ",
            @(101008): @"M762",
            @(101009): @"Mk47",
            @(101010): @"C36C",
            @(101011): @"AC-VAL",
            @(101012): @"突击枪",
            @(103001): @"Kar98k",
            @(103002): @"M24",
            @(103003): @"AWM",
            @(103004): @"SKS",
            @(103005): @"VSS",
            @(103006): @"Mini14",
            @(103007): @"MK-14",
            @(103008): @"Win94",
            @(103009):@"SLR",
            @(103010): @"QBU",
            @(103011): @"莫辛纳甘",
            @(103012): @"AMR",
            @(103013): @"M417",
            @(103014): @"MK20",
            @(102001): @"Uzi",
            @(102105): @"P90",
            @(102002): @"UMP9",
            @(102003): @"Vector",
            @(102004): @"TommyGun",
            @(102005): @"野牛",
            @(102007): @"MP5K",
            @(104001): @"S686",
            @(104002): @"S1897",
            @(104003): @"S12K",
            @(104004): @"DBS",
            @(104006): @"SawedOff",
            @(104100): @"SPAS-12",
            @(106001): @"P92",
            @(106002): @"P1911",
            @(106003): @"R1895",
            @(106004): @"P18C",
            @(106005): @"R45",
            @(106010): @"沙漠之鹰"
        };
    });
    return souchiNames[@(wqid)] ?: @"";
}
#pragma mark 遍历字典
- (void)CacheData {
    self.人物缓存=NULL;
    self.人物缓存 = @[].mutableCopy;
    self.物资缓存=NULL;
    self.物资缓存 = @[].mutableCopy;
    Gworld = Read<uintptr_t>(GBase + 0xAAB00C0);
    GName = Read<uintptr_t>(GBase + 0xA88D458);
    const float hpValues[] = {100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200};
    const int hpValueCount = sizeof(hpValues) / sizeof(float);
    // 获取视角信息
    uintptr_t NetDriver = Read<uintptr_t>(Gworld + 0x98);
    uintptr_t ServerConnection = Read<uintptr_t>(NetDriver + 0x88);
    uintptr_t PlayerController = Read<uintptr_t>(ServerConnection + 0x30);
    uintptr_t mySelf = Read<uintptr_t>(PlayerController + 0x6d0);
    
    uint64_t level = Read<uintptr_t>(Gworld + 0x90);
    uint64_t actorArray = Read<uintptr_t>(level + 0xA0);
    int actorCount = Read<int>(level + 0xA8);
    //初始化
    static std::string ClassName;
    static std::string wzName;
    
    for (int i = 0; i < actorCount; i++) {
        uintptr_t player = Read<uintptr_t>(actorArray + i * 8);
        ClassName = GetFName(actorArray);
        NSLog(@"ClassName==%s",ClassName.c_str());
        if (ClassName.empty()) continue;
        //不包含PlayerPawn的都是物质
        if (!isContain(ClassName, "PlayerPawn")) {
            ShiSanGeGetGame*model=[[ShiSanGeGetGame alloc] init];
            if(物资总开关){
                if (物资调试开关) {
                    FVector3D WorldLocation = getRelativeLocation(player);
                    float juli = getDistance(WorldLocation, POV.Location) / 100;
                    //调试模式仅10米内物资
                    if (juli<10) {
                        model.Name=ClassName;//调试模式下 直接吧模型名字添加到物资名字进行绘制 方便自己识别记住名字登记
                        model.Player=player;//储存物资编号
                        [self.物资缓存 addObject:model];
                    }
                    
                }else{
                    //优先吧最常见的 的东西 最长开的东西放在前面 当多个开关开启时 因为物资都在附近10米左右 避免先进行无效物资匹配
                    if (投掷物开关 || 手雷预警开关) {
                        //判断字符串包含 手雷 闪光 获取 后期铝热蛋等自己调试模式添加
                        if (isContain(ClassName, "Grenade")) {
                            model.Name="雷";//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                        if (isContain(ClassName, "Fire")) {
                            model.Name="闪";//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                        if (isContain(ClassName, "Burn")) {
                            model.Name="火";//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                        
                    }
                    if (高级物资开关 ) {
                        wzName=getReFName(ClassName, 8);
                        if (!wzName.empty()){
                            model.Name=wzName;
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                    }
                    if (药品开关 ) {
                        wzName=getReFName(ClassName, 2);
                        if (!wzName.empty()){
                            model.Name=wzName;//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                    }
                    if (枪械开关 ) {
                        wzName=getReFName(ClassName, 4);
                        if (!wzName.empty()){
                            model.Name=wzName;//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                    }
                    if (载具开关 ) {
                        wzName=getReFName(ClassName, 1);
                        if (!wzName.empty()){
                            model.Name=wzName;//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                            
                        }
                    }
                    if (配件开关 ) {
                        wzName=getReFName(ClassName, 5);
                        if (!wzName.empty()){
                            model.Name=wzName;//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                    }
                    if (倍镜开关 ) {
                        wzName=getReFName(ClassName, 9);
                        if (!wzName.empty()){
                            model.Name=wzName;//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                    }
                    if (头盔开关 ) {
                        wzName=getReFName(ClassName, 10);
                        if (!wzName.empty()){
                            model.Name=wzName;//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                    }
                    if (护甲开关 ) {
                        wzName=getReFName(ClassName, 11);
                        if (!wzName.empty()){
                            model.Name=wzName;//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                    }
                    if (背包开关 ) {
                        wzName=getReFName(ClassName, 12);
                        if (!wzName.empty()){
                            model.Name=wzName;//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                    }
                    if (子弹开关 ) {
                        wzName=getReFName(ClassName, 6);
                        if (!wzName.empty()){
                            model.Name=wzName;//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                    }
                    if (其他物资开关 ) {
                        wzName=getReFName(ClassName, 7);
                        if (!wzName.empty()){
                            model.Name=wzName;//储存查询到的真正名字字符串
                            model.Player=player;//储存物资编号
                            [self.物资缓存 addObject:model];//匹配到就添加到数组
                            continue;//添加会记得跳出本次匹配 避免执行后面的if
                        }
                    }
                   
                }
            }
            
        }else{
            //玩家
            float hpmax = Read<float>(player + 0xed0);
            for (int j = 0; j < hpValueCount; j++) {
                if (hpmax == hpValues[j]) {
                    // 读取玩家模型数据
                    bool bDead = Read<bool>(player + 0xf30) & 1;
                    if (bDead) continue;
                    //排除自己
                    if (player == mySelf) continue;
                    int TeamID = Read<int>(player + 0xbc0);
                    int MyTeamID = Read<int>(PlayerController + 0xb00);
                    if (TeamID == MyTeamID) continue;
                    //存储玩家数组
                    [self.人物缓存 addObject:@(player)];
                    continue;//添加玩家后就下一个玩家了 跳出本次循环
                }
            }
        }
        
        
    }
    
}
- (void)getData:(PUBGBlock)block {
    
    //初始化骨骼关节点
    static int Bones[18] = {6,5,4,3,2,1,12,13,14,33,34,35,53,54,55,57,58,59};
    static FVector2D Bones_Pos[18];
    
    // 获取视角信息
    // 获取视角信息
    uintptr_t NetDriver = Read<uintptr_t>(Gworld + 0x98);
    if(!isValidAddress(NetDriver))return;
    uintptr_t ServerConnection = Read<uintptr_t>(NetDriver + 0x88);
    if(!isValidAddress(ServerConnection))return;
    uintptr_t PlayerController = Read<uintptr_t>(ServerConnection + 0x30);
    if(!isValidAddress(PlayerController))return;
    uintptr_t mySelf = Read<uintptr_t>(PlayerController + 0x6d0);
    if(!isValidAddress(mySelf))return;
    //无后座相关
    uintptr_t PlayerCameraManager = Read<uintptr_t>(PlayerController + 0x758);
    if(!isValidAddress(PlayerCameraManager))return;
    Read(PlayerCameraManager + 0x12e0 + 0x10, &POV ,sizeof(FMinimalViewInfo));
    if(无后座开关){
        
        uintptr_t WeaponManagerComponent =Read<uintptr_t>(mySelf+ 0x24e0);
        uintptr_t CurrentWeaponReplicated =Read<uintptr_t>(WeaponManagerComponent+ 0x728);
        uintptr_t ShootWeaponEntityComp=Read<uintptr_t>(CurrentWeaponReplicated+ 0x12f8);
        float RecoilKickADS = 0.001;
        Read(ShootWeaponEntityComp + 0x16a0, &RecoilKickADS, sizeof(float));
        Read(ShootWeaponEntityComp + 0x16ac, &RecoilKickADS, sizeof(float));
    }
    
    // 初始化玩家字典
    NSMutableArray *playerArray = @[].mutableCopy;//玩家字典
    NSMutableArray *wzArray = @[].mutableCopy;//物资字典
    for (NSNumber *Player in self.人物缓存) {
        uintptr_t player = [Player unsignedIntegerValue];
        PUBGPlayermodel *model = [[PUBGPlayermodel alloc] init];
        //获取地图3D坐标
        FVector3D WorldLocation = getRelativeLocation(player);
        //玩家方框
        model.rect=worldToScreenForRect(WorldLocation, POV);
        //屏幕外面就只绘制射线 只获取方框就行 避免读取其他数据无用功 if(屏幕里面)continue; 添加数组后跳出当前玩家
        if (model.rect.X<0 || model.rect.Y<0 || model.rect.X+model.rect.W>kWidth || model.rect.Y+model.rect.H>kHeight) {
            model.isPm=NO;//标记屏幕状态为NO 代表屏幕外面
            [playerArray addObject:model];//添加到模型
            continue;//添加到玩家模型后跳出循环下一个玩家
        }
        
        
        //以下是屏幕里面 正常读取其他数据
        // 计算距离
        model.Distance = getDistance(WorldLocation, POV.Location) / 100;
        //判断迷雾 距离为负数或者0 距离超过500米 跳过本次玩家
        if (model.Distance<=0 || model.Distance>500) continue;
        //判断迷雾 超出地图外面 跳出循环
        if (WorldLocation.X<0 || WorldLocation.Y<0) continue;
        //人机
        model.isAI = Read<BOOL>(player + 0xbdc) != 0;
        //标记为屏幕里面
        model.isPm=YES;
        //血量 判断血量开关开启才去计算血量 避免浪费资源
        if (血条开关) {
            model.Health = Read<float>(player + 0xec8) / Read<float>(player + 0xed0) * 100;
        }
        //名字 读取名字转字符串 比较占用资源 判断名字开启才去读取名字 并且根据ai 更名
        if (名字开关) {
            std::string PlyerName=getPlayerName(player);
            if (PlyerName.empty()) continue;
            model.PlayerName = PlyerName;
            if (model.isAI) model.PlayerName = "Ai_人机";
            //队标 和名字一起显示的 所以在名字开关里
            model.TeamID = Read<int>(player + 0xbc0);
        }
        
        
        //骨骼===========================
        uintptr_t Mesh = Read<uintptr_t>(player + 0x750);
        FTransform RelativeScale3D = getMatrixConversion(Mesh + 0x1C0);
        
        // 骨骼有很多关节点都要把3D转屏幕坐标 占用资源 开关开启才去计算
        if (骨骼开关) {
            //循环18个骨骼关节点
            for (int j = 0; j < 18; j++) {
                FVector3D boneWorldLocation = getBoneWithRotation(Mesh, Bones[j], RelativeScale3D);
                Bones_Pos[j] = worldToScreen(boneWorldLocation, POV);
                
            }
            //循环完毕 骨骼点储存到玩家模型
            model._0 = Bones_Pos[0];
            model._1 = Bones_Pos[1];
            model._2 = Bones_Pos[2];
            model._3 = Bones_Pos[3];
            model._4 = Bones_Pos[4];
            model._5 = Bones_Pos[5];
            model._6 = Bones_Pos[6];
            model._7 = Bones_Pos[7];
            model._8 = Bones_Pos[8];
            model._9 = Bones_Pos[9];
            model._10 = Bones_Pos[10];
            model._11 = Bones_Pos[11];
            model._12 = Bones_Pos[12];
            model._13 = Bones_Pos[13];
            model._14 = Bones_Pos[14];
            model._15 = Bones_Pos[15];
            model._16 = Bones_Pos[16];
            model._17 = Bones_Pos[17];
        }
        
        //追踪 开关 和函数逻辑
        if(追踪开关){
            FVector3D AimbotWorldLocation = getBoneWithRotation(Mesh, 追踪部位, RelativeScale3D);
            FVector2D AimbotScreenLocation = worldToScreen(AimbotWorldLocation, POV);
            float markDistance = kWidth;
            CGPoint markScreenPos = CGPointMake(kWidth/2, kHeight/2);
            
            if (getInsideFov(AimbotScreenLocation, 追踪圆圈)) {
               
                int tDistance = getCenterOffsetForVector(AimbotScreenLocation);
                if (tDistance <= 追踪圆圈 && tDistance < markDistance) {
                    markDistance = tDistance;
                    markScreenPos.x = AimbotScreenLocation.X;
                    markScreenPos.y = AimbotScreenLocation.Y;
                    // 自己枪械开镜或者开火
                    BOOL bIsWeaponFiring = Read<bool>(mySelf + 0x1a08);
                    BOOL bIsGunADS = Read<bool>(mySelf + 0x1208);
                    if (bIsWeaponFiring || bIsGunADS ) {
                        // 自瞄目标距离
                        float distance = getDistance(AimbotWorldLocation, POV.Location) / 100;
                        
                        float temp = 1.23f;
                        float Gravity = 5.72f;
                        
                        if (distance < 5000.f)       temp = 1.8f;  else if (distance < 10000.f) temp = 1.72f;
                        else if (distance < 15000.f) temp = 1.23f; else if (distance < 20000.f) temp = 1.24f;
                        else if (distance < 25000.f) temp = 1.25f; else if (distance < 30000.f) temp = 1.26f;
                        
                        uintptr_t WeaponManagerComponent =Read<uintptr_t>(mySelf+ 0x24e0);
                        uintptr_t CurrentWeaponReplicated =Read<uintptr_t>(WeaponManagerComponent+ 0x728);
                        uintptr_t ShootWeaponEntityComp=Read<uintptr_t>(CurrentWeaponReplicated+ 0x12f8);
                        float BulletFireSpeed = Read<float>(ShootWeaponEntityComp + 0x130c);
                        
                        float BulletFlyTime = distance / BulletFireSpeed;
                        float secFlyTime = BulletFlyTime * temp;
                        
                        // 目标移动速度
                        
                        FVector3D VelocitySafty = Read<FVector3D>(player + 0xfb4);
                        
                        // 预判目标位置
                        FVector3D delta;
                        delta.X = VelocitySafty.X * secFlyTime;
                        delta.Y = VelocitySafty.Y * secFlyTime;
                        delta.Z = VelocitySafty.Z * secFlyTime;
                        
                        if (distance > 10000.f) {
                            delta.Z += 0.5 * Gravity * BulletFlyTime * BulletFlyTime * 5.0f;
                        }
                        
                        FVector3D targetlocation;
                        targetlocation.X = AimbotWorldLocation.X - POV.Location.X + delta.X;
                        targetlocation.Y = AimbotWorldLocation.Y - POV.Location.Y + delta.Y;
                        targetlocation.Z = AimbotWorldLocation.Z - POV.Location.Z + delta.Z;
                        
                        // 目标位置角度
                        FRotator Rotation = calcAngle(targetlocation);
                        
                        // 自己位置角度
                        FRotator ControlRotation;
                        Read(PlayerController + 0x6f8, &ControlRotation, sizeof(FRotator));
                        
                        // 平滑自瞄角度
                        FRotator clampRotation;
                        clampRotation.Yaw = Rotation.Yaw - ControlRotation.Yaw;
                        clampRotation.Pitch = Rotation.Pitch - ControlRotation.Pitch;
                        clampRotation.Roll = Rotation.Roll - ControlRotation.Roll;
                        
                        FRotator aimbotRotation;
                        aimbotRotation.Yaw = ControlRotation.Yaw + [self clamp:clampRotation].Yaw * 自瞄速度;
                        aimbotRotation.Pitch = ControlRotation.Pitch + [self clamp:clampRotation].Pitch * 自瞄速度;
                        float pitch = atan2f(targetlocation.Z, sqrt(pow(targetlocation.X, 2) + pow(targetlocation.Y, 2))) * 57.29577951308f;
                        float yaw = atan2f(targetlocation.Y, targetlocation.X) * 57.29577951308f;
                        
                        
                        float Yaw = aimbotRotation.Yaw;
                        float Pitch = aimbotRotation.Pitch;
                        if (!isnan(Yaw) && !isnan(Pitch)) {
                            
                            // 开火自瞄
                            if(自瞄开关){
                                if(model.Health!=0 && bIsGunADS && model.Distance<=追踪距离)
                                {
                                    //开镜自瞄
                                    Read(PlayerController + 0x6f8, &Pitch, sizeof(float));
                                    Read(PlayerController + 0x6f8 + 4, &Yaw, sizeof(float));
                                }
                                if (model.Health!=0 && model.Distance<=追踪距离) {
                                    
                                    //开火自瞄
                                    Read(PlayerController + 0x6f8 + 4, &Pitch, sizeof(float));
                                    Read(PlayerController + 0x6f8+ 4, &Yaw, sizeof(float));
                                    
                                }
                            }
                            if(追踪开关){
                                if ( model.Distance <= 追踪距离) {
                                    
                                    Read(PlayerController + 0x768, &pitch, sizeof(float));
                                    Read(PlayerController + 0x768+ 4, &yaw, sizeof(float));
                                    
                                    
                                }
                                
                            }
                        }
                    }
                    
                    
                }
                
            }
        }
        
        //读取持枪数据
        if (手持武器开关) {
            int WeaponId = 0;
            uintptr_t WeaponManagerComponent =Read<uintptr_t>(player+ 0x24e0);
            uintptr_t CurrentWeaponReplicated = Read<uintptr_t>(WeaponManagerComponent+0x728);
            uintptr_t MyShootWeaponEntityComp = Read<uintptr_t>(CurrentWeaponReplicated+0x12f8);
            WeaponId= Read<int>(MyShootWeaponEntityComp+0x148);
            model.WeaponName=[self souchistr:WeaponId];
        }
        
        //添加到模型
        [playerArray addObject:model];
        
        
    }
    
    for (int i=0;i<self.物资缓存.count;i++){
        ShiSanGeGetGame *model=self.物资缓存[i];
        uintptr_t player = model.Player;
        if(!isValidAddress(player))return;
        //玩家字典那是1秒一次的 真正绘制可能0.01秒 所以这里要从新更新物资的具体屏幕坐标
        FVector3D WorldLocation = getRelativeLocation(player);
        model.JuLi = getDistance(WorldLocation, POV.Location) / 100;// 储存计算距离
        model.WuZhi2D=worldToScreen(WorldLocation, POV);//存储物资屏幕坐标系
        //例外情况 当开启调试模式 只进行10米没的物资调试
        if (物资调试开关) {
            if (model.JuLi <10) {
                [wzArray addObject:model];//添加到数组
            }
        }else{
            //最后添加到物资字典
            [wzArray addObject:model];
        }
        
    }
    //物资和玩家都添加完毕 推送给绘制函数进行绘制
    if (block) {
        block(playerArray,wzArray);
    }
    
}


@end

@implementation PUBGPlayermodel

@end
