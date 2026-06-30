//
//  RCNameEditViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCNameEditViewModel.h"
#import "RCGroupManager.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
#import "RCInfoManagement.h"
#import "RCGroup+RCExtented.h"
#import "RCGroupInfo+Private.h"
#import "RCUserInfo+RCGroupMember.h"
#import "RCIM.h"
#define RCNameOverSize 64
#define RCRemarkNameOverSize 32

@interface RCNameEditViewModel ()

@property (nonatomic, assign) RCNameEditType type;

@property (nonatomic, assign) NSString *userId;

@property (nonatomic, assign) NSString *groupId;

@property (nonatomic, assign) NSInteger limit;

@end

@implementation RCNameEditViewModel
@dynamic delegate;

+ (instancetype)viewModelWithUserId:(NSString *)userId groupId:(NSString *)groupId type:(RCNameEditType)type {
    RCNameEditViewModel *viewModel = [[self.class alloc] init];
    viewModel.type = type;
    viewModel.userId = userId ? : @"";
    viewModel.groupId = groupId;
    if(type == RCNameEditTypeRemark) {
        viewModel.limit = RCRemarkNameOverSize;
    } else {
        viewModel.limit = RCNameOverSize;
    }
    return viewModel;
}

- (void)getCurrentName:(void(^)(NSString *))block {
    if (!block) {
        return;
    }
    switch (self.type) {
        case RCNameEditTypeName:{
            [[RCCoreClient sharedCoreClient] getMyUserProfile:^(RCUserProfile * _Nonnull userProfile) {
                block(userProfile.name);
            } error:^(RCErrorCode errorCode) {
                block(@"");
            }];
        }
            break;
        case RCNameEditTypeRemark:
            if (self.userId) {
                [[RCCoreClient sharedCoreClient] getFriendsInfo:@[self.userId] success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
                    NSString *name = @"";
                    if (friendInfos.count) {
                        RCFriendInfo *info = [friendInfos firstObject];
                        name = info.remark;
                    }
                    block(name);
                } error:^(RCErrorCode errorCode) {
                    block(@"");
                }];
            }
            break;
        case RCNameEditTypeGroupMemberNickname: {
            if (self.userId && self.groupId) {
                [[RCCoreClient sharedCoreClient] getGroupMembers:self.groupId userIds:@[self.userId] success:^(NSArray<RCGroupMemberInfo *> * _Nonnull groupMembers) {
                    NSString *name = @"";
                    if (groupMembers.count) {
                        RCGroupMemberInfo *info = [groupMembers firstObject];
                        name = info.nickname;
                    }
                    block(name);
                } error:^(RCErrorCode errorCode) {
                    block(@"");
                }];
            }
        }
            break;
        case RCNameEditTypeGroupName: {
            if (self.groupId) {
                [[RCCoreClient sharedCoreClient] getGroupsInfo:@[self.groupId] success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
                    NSString *name = @"";
                    if (groupInfos.count) {
                        RCGroupInfo *info = [groupInfos firstObject];
                        name = info.groupName;
                    }
                    block(name);
                } error:^(RCErrorCode errorCode) {
                    block(@"");
                }];
            }
        }
            break;
        case RCNameEditTypeGroupRemark: {
            if (self.groupId) {
                [[RCCoreClient sharedCoreClient] getGroupsInfo:@[self.groupId] success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
                    NSString *name = @"";
                    if (groupInfos.count) {
                        RCGroupInfo *info = [groupInfos firstObject];
                        name = info.remark;
                    }
                    block(name);
                } error:^(RCErrorCode errorCode) {
                    block(@"");
                }];
            }
        }
            break;
        default:
            break;
    }
}
- (void)updateName:(NSString *)name {
    switch (self.type) {
        case RCNameEditTypeName:
            [self updateMyName:name];
            break;
        case RCNameEditTypeRemark:
            [self updateRemark:name];
            break;
        case RCNameEditTypeGroupMemberNickname:
            [self updateGroupMemberNickname:name];
            break;
        case RCNameEditTypeGroupName:
            [self updateGroupName:name];
            break;
        case RCNameEditTypeGroupRemark:
            [self updateGroupRemark:name];
            break;
        default:
            break;
    }
}

- (NSString *)title {
    if (!_title) {
        switch (self.type) {
            case RCNameEditTypeName:
                _title = RCLocalizedString(@"NameEditTitle");
                break;
            case RCNameEditTypeRemark:
                _title = RCLocalizedString(@"RemarkEditTitle");
                break;
            case RCNameEditTypeGroupMemberNickname:
                _title = RCLocalizedString(@"MemberNameEditTitle");
                break;
            case RCNameEditTypeGroupName:
                _title = RCLocalizedString(@"GroupNameEditTitle");
                break;
            case RCNameEditTypeGroupRemark:
                _title = RCLocalizedString(@"GroupRemarkEditTitle");
                break;
            default:
                break;
        }
    }
    return _title;
}

- (NSString *)tip {
    if (!_tip) {
        switch (self.type) {
            case RCNameEditTypeGroupMemberNickname:
                _tip = RCLocalizedString(@"MemberNameEditTip");
                break;
            default:
                break;
        }
    }
    return _tip;
}

- (NSString *)content {
    if (!_content) {
        switch (self.type) {
            case RCNameEditTypeName:
            case RCNameEditTypeGroupMemberNickname:
                _content = RCLocalizedString(@"Nickname");
                break;
            case RCNameEditTypeRemark:
                _content = RCLocalizedString(@"Remark");
                break;
            case RCNameEditTypeGroupName:
                _content = RCLocalizedString(@"GroupName");
                break;
            case RCNameEditTypeGroupRemark:
                _content = RCLocalizedString(@"GroupRemarkEditContent");
                break;
            default:
                break;
        }
    }
    return _content;
}

- (NSString *)placeHolder {
    if (!_placeHolder) {
        switch (self.type) {
            case RCNameEditTypeRemark:
                _placeHolder = RCLocalizedString(@"RemarkEditPlaceholder");
                break;
            case RCNameEditTypeGroupName:
                _placeHolder = RCLocalizedString(@"GroupNameEditPlaceholder");
                break;
            case RCNameEditTypeName:
            case RCNameEditTypeGroupMemberNickname:
                _placeHolder = RCLocalizedString(@"InputNickNamePlaceholder");
                break;
            case RCNameEditTypeGroupRemark:
                _placeHolder = RCLocalizedString(@"InputGroupRemarkPlaceholder");
                break;
            default:
                break;
        }
    }
    return _placeHolder;
}

#pragma mark -- private

- (void)updateMyName:(NSString *)name {
    RCUserProfile *profile = [RCUserProfile new];
    profile.userId = self.userId;
    profile.name = name;
    UIViewController *viewController = nil;
    if ([self.delegate respondsToSelector:@selector(currentViewController)]) {
        viewController = [self.delegate currentViewController];
    }
    [self loadingWithTip:RCLocalizedString(@"Saving")];
    [[RCIM sharedRCIM] updateMyUserProfile:profile successBlock:^{
        [self stopLoading];
        [self updateDidComplete:name];
    } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
        [self stopLoading];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(nameUpdateDidError:)]) {
                NSString *tips = RCLocalizedString(@"SetFailed");
                if (errorCode == RC_SERVICE_INFORMATION_AUDIT_FAILED) {
                    tips = RCLocalizedString(@"Content_Contains_Sensitive");
                }
                [self.delegate nameUpdateDidError:tips];
            }
        });
    }];
}

- (void)updateRemark:(NSString *)name {
    UIViewController *viewController = nil;
    if ([self.delegate respondsToSelector:@selector(currentViewController)]) {
        viewController = [self.delegate currentViewController];
    }
    [self loadingWithTip:RCLocalizedString(@"Saving")];
    [[RCIM sharedRCIM] setFriendInfo:self.userId remark:name extProfile:nil successBlock:^{
        [self stopLoading];
        [self updateDidComplete:name];
    } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
        [self stopLoading];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(nameUpdateDidError:)]) {
                NSString *tips = RCLocalizedString(@"SetFailed");
                if (errorCode == RC_SERVICE_INFORMATION_AUDIT_FAILED) {
                    tips = RCLocalizedString(@"Content_Contains_Sensitive");
                }
                [self.delegate nameUpdateDidError:tips];
            }
        });
    }];
}

- (void)updateGroupMemberNickname:(NSString *)name {
    UIViewController *viewController = nil;
    if ([self.delegate respondsToSelector:@selector(currentViewController)]) {
        viewController = [self.delegate currentViewController];
    }
    [self loadingWithTip:RCLocalizedString(@"Saving")];
    [[RCIM sharedRCIM] setGroupMemberInfo:self.groupId userId:self.userId nickname:name extra:nil
                             successBlock:^{
        [self stopLoading];
        [self updateDidComplete:name];
    } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopLoading];
            if ([self.delegate respondsToSelector:@selector(nameUpdateDidError:)]) {
                NSString *tips = RCLocalizedString(@"SetFailed");
                    if (errorCode == RC_SERVICE_INFORMATION_AUDIT_FAILED) {
                        tips = RCLocalizedString(@"Content_Contains_Sensitive");
                    }
                [self.delegate nameUpdateDidError:tips];
            }
        });
    }];
}

- (void)updateGroupName:(NSString *)name {
    if (name.length == 0) {
        [RCAlertView showAlertController:nil message: RCLocalizedString(@"RCGroupNameEmptyTip") hiddenAfterDelay:2];
        return;
    }

    RCGroupInfo *info = [RCGroupInfo new];
    info.groupId = self.groupId;
    info.groupName = name;
 
    UIViewController *viewController = nil;
    if ([self.delegate respondsToSelector:@selector(currentViewController)]) {
        viewController = [self.delegate currentViewController];
    }
   [self loadingWithTip:RCLocalizedString(@"Saving")];
    [[RCIM sharedRCIM] updateGroupInfo:info
                          successBlock:^{
        [self stopLoading];
        [self updateDidComplete:name];
    } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
        [self stopLoading];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(nameUpdateDidError:)]) {
                NSString *tips = RCLocalizedString(@"SetFailed");
                if (errorCode == RC_SERVICE_INFORMATION_AUDIT_FAILED) {
                    tips = RCLocalizedString(@"Content_Contains_Sensitive");
                }
                [self.delegate nameUpdateDidError:tips];
            }
        });
    }];
}

- (void)updateGroupRemark:(NSString *)name {
    [[RCIM sharedRCIM] setGroupRemark:self.groupId remark:name success:^{
        [self updateDidComplete:name];
    } error:^(RCErrorCode errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(nameUpdateDidError:)]) {
                [self.delegate nameUpdateDidError:RCLocalizedString(@"SetFailed")];
            }
        });
    }];
}

- (void)updateDidComplete:(NSString *)name {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(nameUpdateDidSuccess)]) {
            [self.delegate nameUpdateDidSuccess];
        }
    });
}
@end
