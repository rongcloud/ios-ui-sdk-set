//
//  RCStickerMessage.h
//  RongSticker
//
//  Created by liyan on 2018/8/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RongIMKitHeader.h"

/*!
 表情消息的类型名
 */
#define RCStickerMessageTypeIdentifier @"RC:StkMsg"

@interface RCStickerMessage : RCMessageContent

/*!
 表情包的标识
 */
@property (nonatomic, strong) NSString *packageId;

/*!
 表情在表情包中的序号
 */
@property (nonatomic, strong) NSString *stickerId;

/*!
 表情的内容
 */
@property (nonatomic, strong) NSString *digest;

/*!
 表情的宽
 */
@property (nonatomic, assign) long width;

/*!
 表情的高
 */
@property (nonatomic, assign) long height;

/*!
 附加信息
 */
@property (nonatomic, strong) NSString *extra;

/*!
 初始化表情消息

 @param packageId 表情包的标识
 @param stickerId 表情在表情包中的序号
 @param digest 表情对应的文本内容
 @param width 表情的宽
 @param height 表情的高

 @return          表情消息对象
 */
+ (instancetype)messageWithPackageId:(NSString *)packageId
                           stickerId:(NSString *)stickerId
                              digest:(NSString *)digest
                               width:(long)width
                              height:(long)height;

@end
