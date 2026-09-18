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
@property (nonatomic, weak) RCGroupNotificationCell *cell;
@property (nonatomic, strong) RCIMThreadLock *lock;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong)  NSIndexPath *indexPath;
@property (nonatomic, weak) UIViewController <RCListViewModelResponder> *responder;
@property (nonatomic, assign) CGFloat cellHeight;
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
    [self.lock performReadLockBlock:^{
        groupName = self.groupName;
        cell = self.cell;
    }];

    if (groupName) {
        cell.labName.text = groupName;
        return;
    }
    
    if (self.application.groupId) {
        [[RCCoreClient sharedCoreClient] getGroupsInfo:@[self.application.groupId]
                                               success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
            NSString *name = nil;
            if (groupInfos.count) {
                RCGroupInfo *info = [groupInfos firstObject];
                name = info.groupName;
            }
            [self.lock performWriteLockBlock:^{
                self.groupName = name;
            }];
        
            __block RCGroupNotificationCell *cell2 = nil;

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.lock performReadLockBlock:^{
                    cell2 = self.cell;
                }];
                if (cell2 != cell) {// cell 已复用, 更新逻辑取消
                    return;
                }
                cell.labName.text = name;
            });
        }
                                                 error:^(RCErrorCode errorCode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.labName.text = nil;
            });
        }];
    } else {
        cell.labName.text = nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.tableView = tableView;
    self.indexPath = indexPath;
    RCGroupNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:RCGroupNotificationCellIdentifier
                                                                          forIndexPath:indexPath];
    self.cell = cell;
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
            [self showTips:RCLocalizedString(@"GroupInvitationAcceptFailed")];
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
                [self showTips:RCLocalizedString(@"GroupOtherInvitationAcceptFailed")];
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
    if (self.indexPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadRowsAtIndexPaths:@[self.indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView setNeedsLayout];
            [self.tableView layoutIfNeeded];
        });
    }
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
        UILabel *lab = [self createLabSlave];
        CGFloat labHeight = lab.frame.size.height;
        CGFloat diff = 90 - labHeight;
        lab.text = [self tipsOfOperator:self.application];
        [lab sizeToFit];
        _cellHeight = diff + lab.frame.size.height;
    }
    return _cellHeight;
}


- (UILabel *)createLabSlave {
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    
    CGFloat labWidth = width - 40 - 2*RCGroupNotificationCellHorizontalMargin+RCGroupNotificationCellHorizontalMargin/2;
    
    UILabel *lab = [UILabel new];
    lab.frame = CGRectMake(0, 0, labWidth, 20);
    lab.font = [UIFont systemFontOfSize:15];
    lab.lineBreakMode = NSLineBreakByTruncatingTail;
    lab.numberOfLines = 0;
    return lab;
}
@end
