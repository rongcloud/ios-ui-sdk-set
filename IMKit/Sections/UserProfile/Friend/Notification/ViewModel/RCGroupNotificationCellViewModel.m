//
//  RCGroupNotificationCellViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/14.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNotificationCellViewModel.h"
#import "RCGroupNotificationCell.h"
#import "RCKitCommonDefine.h"
#import "RCIMThreadLock.h"

@interface RCGroupNotificationCellViewModel()
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, assign) BOOL fetchingGroupName;
@property (nonatomic, weak) RCGroupNotificationCell *cell;
@property (nonatomic, strong) RCIMThreadLock *lock;
@property (nonatomic, weak) UIViewController <RCListViewModelResponder> *responder;
@property (nonatomic, assign) CGFloat cellHeight;

- (UITableView *)tableViewForCell:(UITableViewCell *)cell;
- (CGFloat)contentHeightForCell:(UITableViewCell *)cell;
@end

@implementation RCGroupNotificationCellViewModel

- (instancetype)initWithApplicationInfo:(RCGroupApplicationInfo *)application
{
    self = [super init];
    if (self) {
        self.application = application;
        self.lock = [RCIMThreadLock new];
    }
    return self;
}

/// 注册 cell
+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCGroupNotificationCell class] forCellReuseIdentifier:RCGroupNotificationCellIdentifier];
}

/// 绑定响应者
- (void)bindResponder:(UIViewController <RCListViewModelResponder>*)responder {
    self.responder = responder;
}

- (void)fetchGroupNameIfNeed {
    __block RCGroupNotificationCell *cell = nil;
    __block NSString *groupName = nil;
    __block BOOL shouldFetch = NO;
    NSString *groupId = self.application.groupId;
    [self.lock performWriteLockBlock:^{
        groupName = self.groupName;
        cell = self.cell;
        if (!groupName && groupId.length > 0 && !self.fetchingGroupName) {
            self.fetchingGroupName = YES;
            shouldFetch = YES;
        }
    }];

    cell.labName.text = groupName;
    if (!shouldFetch) {
        return;
    }

    [[RCCoreClient sharedCoreClient] getGroupsInfo:@[groupId]
                                         success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
        NSString *name = nil;
        if (groupInfos.count) {
            RCGroupInfo *info = [groupInfos firstObject];
            name = info.groupName;
        }
        [self.lock performWriteLockBlock:^{
            self.groupName = name;
            self.fetchingGroupName = NO;
        }];
        [self reloadCell];
    } error:^(RCErrorCode errorCode) {
        [self.lock performWriteLockBlock:^{
            self.fetchingGroupName = NO;
        }];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:RCGroupNotificationCellIdentifier
                                                                          forIndexPath:indexPath];
    self.cell = cell;
    cell.hideSeparatorLine = self.hideSeparatorLine;
    [self fetchGroupNameIfNeed];
    [cell updateWithViewModel:self];
    cell.labTips.text = [self tipsOfOperator:self.application];
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellHeight;
}

/// 接受申请
- (void)approveApplication {
    // 收到的邀请
    if (self.application.direction == RCGroupApplicationDirectionInvitationReceived) {
        [[RCCoreClient sharedCoreClient] acceptGroupInvite:self.application.groupId inviterId:self.application.inviterInfo.userId success:^{
            self.application.status = RCGroupApplicationStatusJoined;
            [self reloadCell];
        } error:^(RCErrorCode errorCode) {
            NSString *tips = RCLocalizedString(@"GroupInvitationAcceptFailed");
            if (errorCode == RC_GROUP_MEMBERS_COUNT_EXCEED_LIMIT) {
                tips = RCLocalizedString(@"GroupAcceptMemberCountExceedLimit");
            } else if (errorCode == RC_GROUP_JOIN_COUNT_EXCEED_LIMIT) {
                NSString *name = self.application.joinMemberInfo.name;
                if (name.length == 0) {
                    name = self.application.joinMemberInfo.userId;
                }
                if (name.length > 0) {
                    tips = [NSString stringWithFormat:RCLocalizedString(@"GroupJoinCountExceedLimit"), name];
                }
            }
            [self showTips:tips];
        }];
    } else if (self.application.direction == RCGroupApplicationDirectionApplicationReceived) {
        [[RCCoreClient sharedCoreClient] acceptGroupApplication:self.application.groupId inviterId:self.application.inviterInfo.userId applicantId:self.application.joinMemberInfo.userId success:^(RCErrorCode processCode) {
            if (processCode == RC_GROUP_NEED_INVITEE_ACCEPT) {// 有邀请人
                self.application.status = RCGroupApplicationStatusInviteeUnHandled;
            } else if(processCode == RC_SUCCESS ) {// 申请加入群
                self.application.status = RCGroupApplicationStatusJoined;
            }
            [self reloadCell];
            } error:^(RCErrorCode errorCode) {
                NSString *tips = RCLocalizedString(@"GroupOtherInvitationAcceptFailed");
                if (errorCode == RC_GROUP_MEMBERS_COUNT_EXCEED_LIMIT) {
                    tips = RCLocalizedString(@"GroupAcceptMemberCountExceedLimit");
                } else if (errorCode == RC_GROUP_JOIN_COUNT_EXCEED_LIMIT) {
                    NSString *name = self.application.joinMemberInfo.name;
                    if (name.length == 0) {
                        name = self.application.joinMemberInfo.userId;
                    }
                    if (name.length > 0) {
                        tips = [NSString stringWithFormat:RCLocalizedString(@"GroupJoinCountExceedLimit"), name];
                    }
                }
                [self showTips:tips];
            }];
    }

}

/// 拒绝申请
- (void)rejectApplication {
    // 收到的邀请
    if (self.application.direction == RCGroupApplicationDirectionInvitationReceived) {
        [[RCCoreClient sharedCoreClient] refuseGroupInvite:self.application.groupId
                                                 inviterId:self.application.inviterInfo.userId
                                                    reason:@""  success:^{
            self.application.status = RCGroupApplicationStatusInviteeRefused;
            [self reloadCell];
        } error:^(RCErrorCode errorCode) {
            [self showTips:RCLocalizedString(@"GroupInvitationRefuseFailed")];
        }];
    } else if (self.application.direction == RCGroupApplicationDirectionApplicationReceived) {
        [[RCCoreClient sharedCoreClient]  refuseGroupApplication:self.application.groupId inviterId:self.application.inviterInfo.userId applicantId:self.application.joinMemberInfo.userId
                                                         reason:@"" success:^ {
         
            if (self.application.status == RCGroupApplicationStatusManagerUnHandled) {
                self.application.status = RCGroupApplicationStatusManagerRefused;
            } else if (self.application.status == RCGroupApplicationStatusInviteeRefused) {
                self.application.status = RCGroupApplicationStatusInviteeRefused;
            }
            [self reloadCell];
            } error:^(RCErrorCode errorCode) {
                [self showTips:RCLocalizedString(@"GroupOtherInvitationRefuseFailed")];
            }];
    }
}

- (void)showTips:(NSString *)tips {
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder showTips:tips];
        });
    }
}

- (void)reloadCell {
    dispatch_async(dispatch_get_main_queue(), ^{
        RCGroupNotificationCell *cell = self.cell;
        if (!cell || cell.viewModel != self) {
            return;
        }
        UITableView *tableView = [self tableViewForCell:cell];
        CGFloat previousContentHeight = [self contentHeightForCell:cell];
        // Only the cell content changes. An async callback can outlive a
        // data-source reset, so do not address a cached row here.
        [cell updateWithViewModel:self];
        __block NSString *groupName = nil;
        [self.lock performReadLockBlock:^{
            groupName = self.groupName;
        }];
        cell.labName.text = groupName;
        cell.labTips.text = [self tipsOfOperator:self.application];
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        // A cell layout does not invalidate UITableView's cached self-sizing height.
        // Reload only when its fitted height changes; unlike a row/batch update,
        // reloadData also tolerates a data-source reset while the callback was queued.
        CGFloat contentHeight = [self contentHeightForCell:cell];
        if (tableView && fabs(contentHeight - previousContentHeight) > 0.5 &&
            [tableView indexPathForCell:cell]) {
            [tableView reloadData];
            [tableView layoutIfNeeded];
        }
    });
}

- (UITableView *)tableViewForCell:(UITableViewCell *)cell {
    UIView *view = cell.superview;
    while (view && ![view isKindOfClass:[UITableView class]]) {
        view = view.superview;
    }
    return (UITableView *)view;
}

- (CGFloat)contentHeightForCell:(UITableViewCell *)cell {
    return [cell.contentView systemLayoutSizeFittingSize:CGSizeMake(CGRectGetWidth(cell.contentView.bounds), 0)
                        withHorizontalFittingPriority:UILayoutPriorityRequired
                              verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
}
#pragma mark - Private

- (NSString *)displayNameOf:(RCGroupMemberInfo *)info {
    NSString *name = info.nickname;
    if (name.length == 0) {
        name = info.name;
    }
    return name;
}

- (NSString *)nameOfOperator:(RCGroupApplicationInfo *)application {
    NSString *name = @"";
    switch (application.direction) {
            // 收到的邀请
        case RCGroupApplicationDirectionInvitationReceived:
            name = [self displayNameOf:application.inviterInfo];
            break;
            //收到的申请
        case RCGroupApplicationDirectionApplicationReceived:
            if (application.inviterInfo) {
                name = [self displayNameOf:application.inviterInfo];
            } else {
                name = [self displayNameOf:application.joinMemberInfo];
            }
            
            break;
        case RCGroupApplicationDirectionInvitationSent:
            name = [self displayNameOf:application.joinMemberInfo];
            break;
        case RCGroupApplicationDirectionApplicationSent:
            name = [self displayNameOf:application.joinMemberInfo];
            break;
        default:
            break;
    }
    return name;
}

- (NSString *)tipsOfOperator:(RCGroupApplicationInfo *)application {
    NSString *name =  [self nameOfOperator:application];
    NSString *tips = @"";
    switch (application.direction) {
            // 收到的邀请
        case RCGroupApplicationDirectionInvitationReceived:
            tips = [NSString stringWithFormat:RCLocalizedString(@"GroupNotificationInviteMe"), name];
            break;
            //收到的申请
        case RCGroupApplicationDirectionApplicationReceived:
            if (application.inviterInfo) {
                tips = [NSString stringWithFormat:RCLocalizedString(@"GroupNotificationInviteUserJoinGroup"),name, application.joinMemberInfo.name];
            } else {
                tips = [NSString stringWithFormat:RCLocalizedString(@"GroupNotificationApplyJoinGroup"), name];
            }
            break;
        case RCGroupApplicationDirectionApplicationSent:
            tips = RCLocalizedString(@"GroupNotificationApplyJoinOtherGroup");
            break;
        case RCGroupApplicationDirectionInvitationSent:
            tips = [NSString stringWithFormat:RCLocalizedString(@"GroupNotificationInviteOther"), name];
            break;
        default:
            break;
    }
    return tips;
}


- (CGFloat)cellHeight {
    if (_cellHeight == 0) {
 // 高度自动适配, 该方法废弃
        _cellHeight = 115;
    }
    return _cellHeight;
}

@end
