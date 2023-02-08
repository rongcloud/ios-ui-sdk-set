//
//  RongLocationKitAdaptiveHeader.h
//  RongLocationKit
//
//  Created by zgh on 2022/2/17.
//
// 私有头文件，不能在 public 的 .h 中引用

#if __has_include(<RongIMKit/RongIMKit.h>)

#import <RongIMKit/RongIMKit.h>

#else

#import "RongIMKit.h"

#endif
