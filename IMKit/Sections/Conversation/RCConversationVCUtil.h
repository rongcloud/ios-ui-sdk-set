//
//  RCConversationVCUtil.h
//  RongIMKit
//
//  Created by Sin on 2020/6/8.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCMessageCellNotificationModel.h"
#import <RongIMLibCore/RongIMLibCore.h>

@class RCConversationViewController,RCMessageModel,RCEditInputBarConfig;

@interface RCConversationVCUtil : NSObject
- (instancetype)init:(RCConversationViewController *)chatVC;

#pragma mark - 消息处理
//聊天页面做具体的发送消息的动作
- (void)doSendMessage:(RCMessageContent *)messageContent pushContent:(NSString *)pushContent;
// 专属发送, 内部无焚毁逻辑
- (void)doOnlySendMessage:(RCMessageContent *)messageContent pushContent:(NSString *)pushContent;

//批量发送从相册中选择出来的媒体消息，包含图片，视频，gif
- (void)doSendSelectedMediaMessage:(NSArray *)selectedImages fullImageRequired:(BOOL)full;
//同步未读数
- (void)syncReadStatus;
- (void)syncReadStatus:(long long)sentTime needDelay:(BOOL)needDelay;
//发送已读回执
- (void)sendReadReceipt;
- (void)sendReadReceiptWithTime:(long long)time;
//批量发送已读回执
- (void)sendReadReceiptResponseForMessages:(NSArray *)array;
//停止播放语音消息
- (void)stopVoiceMessageIfNeed:(RCMessageModel *)model;
//通知消息 cell 的状态
- (void)sendMessageStatusNotification:(NSString *)actionNametatus messageId:(long)messageId progress:(NSInteger)progress;

- (void)sendMessageReadReceiptV5Notification:(RCMessageModel *)model;

#pragma mark - 阅后即焚
//初次使用阅后即焚给用户提示
- (BOOL)alertDestructMessageRemind;

#pragma mark - UI
//计算消息的额外高度，默认 14，显示时间加 44，显示名称加 16
- (CGFloat)referenceExtraHeight:(Class)cellClass messageModel:(RCMessageModel *)model;
//查找消息所在数据源的位置
- (NSIndexPath *)findDataIndexFromMessageList:(RCMessageModel *)model;
//计算会话页面所有消息 cell 是否需要显示时间
- (void)figureOutAllConversationDataRepository;
//计算特定的消息在消息列表中是否需要显示时间
- (void)figureOutLatestModel:(RCMessageModel *)model;
//适配未读数按钮 size
- (void)adaptUnreadButtonSize:(UILabel *)sender;

#pragma mark - 判断条件
//消息是否可以发送已读回执
- (BOOL)enabledReadReceiptMessage:(RCMessageModel *)model;
//是否可以撤回消息
- (BOOL)canRecallMessageOfModel:(RCMessageModel *)model;
//是否可以引用消息
- (BOOL)canReferenceMessage:(RCMessageModel *)message;

/// V2 引用回复开启时，将当前引用态附加到待发送消息上。
- (BOOL)applyQuoteInfoIfActiveToMessage:(RCMessage *)message;

/// IMKit 内部使用：根据消息 UId 批量查询消息。
+ (void)getMessagesByUIds:(nonnull NSArray<NSString *> *)messageUIds
         conversationType:(RCConversationType)conversationType
                 targetId:(nonnull NSString *)targetId
                channelId:(nullable NSString *)channelId
               completion:(nullable void (^)(NSArray<RCMessageResult *> *_Nonnull results, RCErrorCode code))completion;

/// IMKit 内部使用：为一批消息批量加载 V2 引用消息，并回调需要刷新的消息 model。
+ (void)loadQuotedMessagesForModels:(nonnull NSArray<RCMessageModel *> *)models
                          completion:(nullable void (^)(NSArray<RCMessageModel *> *_Nonnull reloadModels))completion;

/// IMKit 内部使用：标记本地已知的 V2 被引用消息终态，避免再次触发 getMessagesByUIds 远端补拉。
+ (void)markQuoteMessageUIds:(nonnull NSArray<NSString *> *)messageUIds
            conversationType:(RCConversationType)conversationType
                    targetId:(nonnull NSString *)targetId
                   channelId:(nullable NSString *)channelId
                       status:(RCQuoteMessageStatus)status;


/// 根据消息ID获取model
/// - Parameter messageID
- (RCMessageModel *)modelByMessageID:(NSInteger)messageID;

/// 根据消息 UId 获取页面中的 model
- (RCMessageModel *)modelByMessageUId:(NSString *)messageUId;

#pragma mark - Util
//保存草稿
- (void)saveDraftIfNeed;
//获取高清语音消息缓存路径
- (NSString *)getHQVoiceMessageCachePath;

- (RCInformationNotificationMessage *)getInfoNotificationMessageByErrorCode:(RCErrorCode)errorCode;

+ (CGFloat)incrementOfTimeLabelBy:(RCMessageModel *)model;

#pragma mark - Edit

/// 获取编辑状态
- (RCEditInputBarConfig *)getCacheEditConfig;

/// 清理编辑状态
- (void)clearEditingState;

@end
