//
//  RCMessageModel.h
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

/*!
 *  \~chinese
 消息Cell的数据模型类
 
 *  \~english
 Data model class of message Cell. 
 */
@interface RCMessageModel : NSObject

/*!
 *  \~chinese
 是否显示时间
 
 *  \~english
 Whether to display the time
 */
@property (nonatomic, assign) BOOL isDisplayMessageTime;

/*!
 *  \~chinese
 是否显示用户名
 
 *  \~english
 Whether to display the user name
 */
@property (nonatomic, assign) BOOL isDisplayNickname;

/*!
 *  \~chinese
 用户信息
 
 *  \~english
 User information
 */
@property (nonatomic, strong) RCUserInfo *userInfo;

/*!
 *  \~chinese
 会话类型
 
 *  \~english
 Conversation type
 */
@property (nonatomic, assign) RCConversationType conversationType;

/*!
 *  \~chinese
 目标会话ID
 
 *  \~english
 Target conversation ID
 */
@property (nonatomic, copy) NSString *targetId;

/*!
 *  \~chinese
 消息ID
 
 *  \~english
 Message ID
 */
@property (nonatomic, assign) long messageId;

/*!
 *  \~chinese
 消息方向
 
 *  \~english
 Message direction
 */
@property (nonatomic, assign) RCMessageDirection messageDirection;

/*!
 *  \~chinese
 发送者的用户ID
 
 *  \~english
 Sender's user ID
 */
@property (nonatomic, copy) NSString *senderUserId;

/*!
 *  \~chinese
 消息的接收状态
 
 *  \~english
 The receiving status of the message
 */
@property (nonatomic, assign) RCReceivedStatus receivedStatus;

/*!
 *  \~chinese
 消息的发送状态
 
 *  \~english
 The sending status of the message
 */
@property (nonatomic, assign) RCSentStatus sentStatus;

/*!
 *  \~chinese
 消息的接收时间（Unix时间戳、毫秒）
 
 *  \~english
 The time the message is received (Unix timestamp, milliseconds)
 */
@property (nonatomic, assign) long long receivedTime;

/*!
 *  \~chinese
 消息的发送时间（Unix时间戳、毫秒）
 
 *  \~english
 The time the message is sent (Unix timestamp, milliseconds)
 */
@property (nonatomic, assign) long long sentTime;

/*!
 *  \~chinese
 消息的类型名
 
 *  \~english
 The type name of the message
 */
@property (nonatomic, copy) NSString *objectName;

/*!
 *  \~chinese
 消息的内容
 
 *  \~english
 The content of the message
 */
@property (nonatomic, strong) RCMessageContent *content;

/*!
 *  \~chinese
 阅读回执状态
 
 *  \~english
 Reading receipt status
 */
@property (nonatomic, strong) RCReadReceiptInfo *readReceiptInfo;

/*!
 *  \~chinese
 消息的附加字段
 
 *  \~english
 Additional fields of the message
 */
@property (nonatomic, copy) NSString *extra;

/*!
 *  \~chinese
 消息展示时的Cell高度

 @discussion 用于大量消息的显示优化
 
 *  \~english
 The height of the Cell when the message is displayed.

 @ discussion It is used to optimize the display of a large number of messages.
 */
@property (nonatomic) CGSize cellSize;
/*!
 *  \~chinese
 全局唯一ID

 @discussion 服务器消息唯一ID（在同一个Appkey下全局唯一）
 
 *  \~english
 Globally unique ID.

 @ discussion server message unique ID (globally unique under the same Appkey).
 */
@property (nonatomic, copy) NSString *messageUId;

/*!
 *  \~chinese
 消息是否可以发送请求回执
 
 *  \~english
 Can the message send a request receipt?

 */
@property (nonatomic, assign) BOOL isCanSendReadReceipt;

/*!
 *  \~chinese
 已读人数
 
 *  \~english
 Number of people read

 */
@property (nonatomic, assign) NSInteger readReceiptCount;

/*!
 *  \~chinese
 消息是否可以包含扩展信息
 
 @discussion 该属性在消息发送时确定，发送之后不能再做修改
 @discussion 扩展信息只支持单聊和群组，其它会话类型不能设置扩展信息
 
 *  \~english
 Whether the message can contain extended information.

 @ discussion This property is determined when the message is sent and cannot be modified after it is sent.
 @ discussion Extension information only supports single chat and group. Other conversation types cannot set extension information.
*/
@property (nonatomic, assign) BOOL canIncludeExpansion;

/*!
 *  \~chinese
 消息扩展信息列表
 
 @discussion 扩展信息只支持单聊和群组，其它会话类型不能设置扩展信息
 
 *  \~english
 Message extension information list.

 @ discussion Extension information only supports single chat and group. Other conversation types cannot set extension information.
*/
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *expansionDic;

/*!
 *  \~chinese
 初始化消息Cell的数据模型

 @param rcMessage   消息实体
 @return            消息Cell的数据模型对象
 
 *  \~english
 Initialize the data model of message Cell.

 @param rcMessage Message entity.
 @ return message Cell's data model object.
 */
+ (instancetype)modelWithMessage:(RCMessage *)rcMessage;

/*!
 *  \~chinese
 初始化消息Cell的数据模型

 @param rcMessage   消息实体
 @return            消息Cell的数据模型对象
 
 *  \~english
 Initialize the data model of message Cell.

 @param rcMessage Message entity.
 @ return message Cell's data model object.
 */
- (instancetype)initWithMessage:(RCMessage *)rcMessage;
@end
