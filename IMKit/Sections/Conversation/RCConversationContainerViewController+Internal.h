#import "RCConversationContainerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCConversationContainerViewController (Internal)

- (void)closeConversationAnimated:(BOOL)animated;

/// SDK 列表删除成功后同步页面状态，不执行数据删除。
/// 按会话类型、目标 ID 和频道 ID 匹配；聚合会话条目按会话类型匹配。
- (void)conversationWasDeleted:(RCConversationModel *)model;

@end

NS_ASSUME_NONNULL_END
