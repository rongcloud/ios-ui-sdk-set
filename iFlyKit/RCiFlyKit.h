//
//  RCiFlyKit.h
//  RongiFlyKit
//
//  Created by Sin on 16/11/22.
//  Copyright © 2016年 Sin. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 讯飞输入法核心类
 */
@interface RCiFlyKit : NSObject

/**
 注册讯飞 appkey
 @param key  讯飞 SDK 的 Appkey
 @discussion  [RCiFlyKit setiFlyAppKey:@"12345678"];
 @discussion  如果需要修改讯飞 SDK 的 Appkey，请在 IMKit 初始化之后调用这个方法，保证 IMKit
 加载该模块的时候，使用正确的讯飞 Appkey
 @discussion  讯飞的 Appkey 和 SDK 是绑定的，请参考讯飞官网 (https://www.xfyun.cn/doc/asr/voicedictation/iOS-SDK.html)
 注册账号，在讯飞开放平台申请应用获得 Appkey, 下载与 Appkey 绑定的 iflyMSC.framework 库,导入项目之后再调用该接口

 */
+ (void)setiFlyAppkey:(NSString *)key;

@end
