//
//  RCGroupFollowCellViewModel.h
//  RongIMKit
//
//  Created by zgh on 2024/11/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseCellViewModel.h"
#import <RongIMLibCore/RongIMLibCore.h>

NS_ASSUME_NONNULL_BEGIN
@class RCGroupFollowCellViewModel;
@protocol RCGroupFollowCellViewModelDelegate <NSObject>
/// 点击移除按钮事件
/// - Since: 5.12.2
- (void)actionButtonDidClick:(RCGroupFollowCellViewModel *)cellViewModel;

@end
/// cellViewModel
/// - Since: 5.12.2
@interface RCGroupFollowCellViewModel : RCBaseCellViewModel<RCCellViewModelProtocol>
/// 群成员
@property (nonatomic, strong, readonly) RCGroupMemberInfo *memberInfo;

/// 备注（好友设置了备注才有）
@property (nonatomic, copy, nullable) NSString *remark;

/// 代理
@property (nonatomic, weak) id<RCGroupFollowCellViewModelDelegate> delegate;

/// 是否隐藏按钮
@property (nonatomic, assign) BOOL hiddenButton;

/// 注册 cell
+ (void)registerCellForTableView:(UITableView *)tableView;

/// 实例化 RCGroupFollowCellViewModel
- (instancetype)initWithMember:(RCGroupMemberInfo *)memberInfo;

@end

NS_ASSUME_NONNULL_END
