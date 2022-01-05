//
//  RCKitConfig.h
//  RongIMKit
//
//  Created by Sin on 2020/6/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCKitFontConf.h"
#import "RCKitMessageConf.h"
#import "RCKitUIConf.h"

#define RCKitConfigCenter [RCKitConfig defaultConfig]

/*!
 *  \~chinese
 IMKit 的全局配置按照模块进行划分
 
 *  \~english
 The global configuration of IMKit is divided by module
 */
@interface RCKitConfig : NSObject

+ (instancetype)defaultConfig;

/*!
 *  \~chinese
 消息配置
 
 *  \~english
 message configuration
 */
@property (nonatomic, strong) RCKitMessageConf *message;

/*!
 *  \~chinese
 UI 配置
 
 *  \~english
 UI configuration
 */
@property (nonatomic, strong) RCKitUIConf *ui;

/*!
 *  \~chinese
 字体配置
 
 *  \~english
 Font configuration
 */
@property (nonatomic, strong) RCKitFontConf *font;
@end
