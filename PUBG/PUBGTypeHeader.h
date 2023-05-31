//
//  PUBGDrawDataFactory.m
//  十三哥 编写
//
//  Created by yiming on 2023/05/23. 最少得代码 最全的功能
//

#ifndef PUBGTypeHeader_h
#define PUBGTypeHeader_h

typedef struct GameInfo {
    NSString *name;
    pid_t pid;
    mach_port_t task;
    uintptr_t base;
    int wztime;
} GameInfo;

typedef struct FVector2D {
    int X;
    int Y;
} FVector2D;

typedef struct FVector3D {
    float X;
    float Y;
    float Z;
} FVector3D;

typedef struct FVector4D {
    float X;
    float Y;
    float Z;
    float W;
} FVector4D;

typedef struct FVectorRect {
    float X;
    float Y;
    float W;
    float H;
} FVectorRect;

typedef struct FRotator {
    float Pitch;
    float Yaw;
    float Roll;
} FRotator;

typedef struct FMinimalViewInfo {
    FVector3D Location;
    FVector3D LocationLocalSpace;
    FRotator Rotation;
    float FOV;
} FMinimalViewInfo;

typedef struct FCameraCacheEntry {
    float TimeStamp;
    FMinimalViewInfo POV;
} FCameraCacheEntry;

typedef struct D3DXMATRIX {
    float _11, _12, _13, _14;
    float _21, _22, _23, _24;
    float _31, _32, _33, _34;
    float _41, _42, _43, _44;
} D3DXMATRIX;

typedef struct BonesStruct {
    FVector3D BonePos[22];
    FVector2D DrawPos[22];
    bool Visibles[22];
    bool Visible;
} BonesStruct;

typedef struct FTransform {
    FVector4D Rotation;
    FVector3D Translation;
    FVector3D Scale3D;
} FTransform;
//物资
typedef struct {
    NSString *className;
    uintptr_t player;
} Wuzhi;

#endif /* PUBGTypeHeader_h */
