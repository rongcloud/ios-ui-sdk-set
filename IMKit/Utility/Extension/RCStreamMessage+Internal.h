//
//  RCStreamMessage+Internal.h
//  RongIMLibCore
//
//  Created by shuai shao on 2025/2/20.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <RongIMLibCore/RCStreamMessage.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCReferenceInfo ()

/// 被引用消息的发送者 ID。
@property (nonatomic, strong) NSString *senderId;

/// 被引用消息的 messageUId。服务器消息唯一 ID（在同一个 AppKey 下全局唯一）
@property (nonatomic, strong) NSString *messageUId;

@property (nonatomic, strong, nullable) RCMessageContent *content;

@end

@interface RCStreamMessage ()

/// 流数据第一个数据包内容，后续客户端需要修改本地存储
@property (nonatomic, copy) NSString *content;

/// 流式消息的文本格式。
/// - Note:
/// 只有首包时会下发，续包不会再次下发。
@property (nonatomic, copy) NSString *type;

/// 流拉取完成标识（客户端需要按需赋值）
@property (nonatomic, assign) BOOL isComplete;

/// 标识业务服务器的异常状态，0 为正常结束。
@property (nonatomic, assign) NSInteger completeReason;

/// 标识 IM 服务器的异常状态，0 为正常结束。
@property (nonatomic, assign) NSInteger stopReason;

/// 流拉取完成标识（客户端需要按需赋值）
@property (nonatomic, assign) BOOL isSync;

@property (nonatomic, strong, nullable) RCReferenceInfo *referMsg;

#pragma mark - Internal

/// 序列号，由服务器保持流拉取顺序，客户端不关注
@property (nonatomic, assign) long seq;

/// 自定义编解码，编解码。
//@property (nonatomic, copy) NSString *encode;

/// 消息 UID。
@property (nonatomic, copy) NSString *messageUID;

/// 拉流地址。
@property (nonatomic, copy) NSString *streamUrl;

@end

NS_ASSUME_NONNULL_END
