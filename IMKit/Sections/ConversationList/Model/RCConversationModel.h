//
//  RCConversationModel.h
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

/*!
 *  \~chinese
 会话Cell数据模型的显示类型
 
 *  \~english
 The display type of the conversation Cell data model 
 */
typedef NS_ENUM(NSUInteger, RCConversationModelType) {
    /*!
     *  \~chinese
     默认显示
     
     *  \~english
     Default display
     */
    RC_CONVERSATION_MODEL_TYPE_NORMAL = 1,
    /*!
     *  \~chinese
     聚合显示
     
     *  \~english
     Aggregate display
     */
    RC_CONVERSATION_MODEL_TYPE_COLLECTION = 2,
    /*!
     *  \~chinese
     用户自定义的会话显示
     
     *  \~english
     User-defined conversation display
     */
    RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION = 3,
    /*!
     *  \~chinese
     公众服务的会话显示
     
     *  \~english
     The conversation of the public service shows
     */
    RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE = 4
};

/*!
 *  \~chinese
 会话Cell的数据模型类
 
 *  \~english
 Data model classes for conversation Cell
 */
@interface RCConversationModel : NSObject

/*!
 *  \~chinese
 会话Cell数据模型的显示类型
 
 *  \~english
 The display type of the conversation Cell data model
 */
@property (nonatomic, assign) RCConversationModelType conversationModelType;

/*!
 *  \~chinese
 用户自定义的扩展数据
 
 *  \~english
 User-defined extended data
 */
@property (nonatomic, strong) id extend;

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
 会话的标题
 
 *  \~english
 Title of the conversation
 */
@property (nonatomic, copy) NSString *conversationTitle;

/*!
 *  \~chinese
 会话中的未读消息数
 
 *  \~english
 Number of unread messages in the conversation
 */
@property (nonatomic, assign) NSInteger unreadMessageCount;

/*!
 *  \~chinese
 当前会话是否置顶
 
 *  \~english
 Whether the current conversation is at the top
 */
@property (nonatomic, assign) BOOL isTop;

/*!
 *  \~chinese
当前会话是否是免打扰状态
 
 *  \~english
 Whether the current conversation is in a do not Disturb state
*/
@property (nonatomic, assign) RCConversationNotificationStatus blockStatus;

/*!
 *  \~chinese
 置顶Cell的背景颜色
 
 *  \~english
 The background color of the top Cell.
 */
@property (nonatomic, strong) UIColor *topCellBackgroundColor;

/*!
 *  \~chinese
 非置顶的Cell的背景颜色
 
 *  \~english
 Background color of untopped Cell.
 */
@property (nonatomic, strong) UIColor *cellBackgroundColor;

/*!
 *  \~chinese
 会话中最后一条消息的接收状态
 
 *  \~english
 The receiving status of the last message in the conversation
 */
@property (nonatomic, assign) RCReceivedStatus receivedStatus;

/*!
 *  \~chinese
 会话中最后一条消息的发送状态
 
 *  \~english
 The sending status of the last message in the conversation
 */
@property (nonatomic, assign) RCSentStatus sentStatus;

/*!
 *  \~chinese
 会话中最后一条消息的接收时间（Unix时间戳、毫秒）
 
 *  \~english
 Time of receipt of the last message in the conversation (Unix timestamp, milliseconds)
 */
@property (nonatomic, assign) long long receivedTime;

/*!
 *  \~chinese
 会话中最后一条消息的发送时间（Unix时间戳、毫秒）
 
 *  \~english
 Time when the last message in the conversation is sent (Unix timestamp, milliseconds)
 */
@property (nonatomic, assign) long long sentTime;

/*!
 *  \~chinese
 会话中存在的草稿
 
 *  \~english
 Drafts that exist in the conversation
 */
@property (nonatomic, copy) NSString *draft;

/*!
 *  \~chinese
 会话中最后一条消息的类型名
 
 *  \~english
 The type name of the last message in the conversation
 */
@property (nonatomic, copy) NSString *objectName;

/*!
 *  \~chinese
 会话中最后一条消息的发送者用户ID
 
 *  \~english
 User ID, the sender of the last message in the conversation
 */
@property (nonatomic, copy) NSString *senderUserId;

/*!
 *  \~chinese
 会话中最后一条消息的消息ID
 
 *  \~english
 Message ID of the last message in the conversation
 */
@property (nonatomic, assign) long lastestMessageId;

/*!
 *  \~chinese
 会话中最后一条消息的内容
 
 *  \~english
 The content of the last message in the conversation
 */
@property (nonatomic, strong) RCMessageContent *lastestMessage;

/*!
 *  \~chinese
 会话中最后一条消息的方向
 
 *  \~english
 The direction of the last message in the conversation
 */
@property (nonatomic, assign) RCMessageDirection lastestMessageDirection;

/*!
 *  \~chinese
 会话中最后一条消息的json Dictionary
 
 *  \~english
 The json Dictionary of the last message in the conversation
 */
@property (nonatomic, strong) NSDictionary *jsonDict;

/*!
 *  \~chinese
 会话中有被提及的消息（有@你的消息）
 
 *  \~english
 There is a mentioned message in the conversation (there is a @ message for you)
 */
@property (nonatomic, assign, readonly) BOOL hasUnreadMentioned;

/*!
 *  \~chinese
会话中有被@的消息数量
 
 *  \~english
 The number of @ messages in the conversation
*/
@property (nonatomic, assign) int mentionedCount;

/*!
 *  \~chinese
 初始化会话显示数据模型

 @param conversation          会话
 @param extend                用户自定义的扩展数据
 @return 会话Cell的数据模型对象
 
 *  \~english
 Initialize conversation display data model.

 @param conversation Conversation.
 @param extend User-defined extended data.
 @ return conversation Cell data model object.
 */
- (instancetype)initWithConversation:(RCConversation *)conversation extend:(id)extend;

/*!
 *  \~chinese
 更新数据模型中的消息

 @param message 此会话中最新的消息
 
 *  \~english
 Update messages in the data model.

 @param message The latest messages in this conversation
 */
- (void)updateWithMessage:(RCMessage *)message;

/*!
 *  \~chinese
 会话和数据模型是否匹配

 @param conversationType 会话类型
 @param targetId         目标会话ID
 @return 会话和数据模型是否匹配
 
 *  \~english
 Whether the conversation and data model match.

 @param conversationType Conversation type
 @param targetId Target conversation ID.
 @ return Whether the conversation matches the data model.
 */
- (BOOL)isMatching:(RCConversationType)conversationType targetId:(NSString *)targetId;
@end
