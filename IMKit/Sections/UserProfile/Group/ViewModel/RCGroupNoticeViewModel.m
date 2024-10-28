//
//  RCGroupNoticeViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNoticeViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
@interface RCGroupNoticeViewModel ()

@property (nonatomic, strong) RCGroupInfo *group;

@property (nonatomic, assign) BOOL canEdit;

@property (nonatomic, assign) NSInteger limit;

@end

@implementation RCGroupNoticeViewModel
@dynamic delegate;

- (instancetype)initWithGroup:(RCGroupInfo *)group canEdit:(BOOL)canEdit {
    self = [super init];
    if (self) {
        self.group = group;
        self.canEdit = canEdit;
        self.limit = 1024;
    }
    return self;
}

- (void)updateNotice:(NSString *)notice inViewController:(nonnull UIViewController *)viewController{
    RCGroupInfo *group = [[RCGroupInfo alloc] init];
    group.groupId = self.group.groupId;
    group.notice = notice;
    [[RCCoreClient sharedCoreClient] updateGroupInfo:group success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [viewController.navigationController popViewControllerAnimated:YES];
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupNoticeSuccess") hiddenAfterDelay:2];
        });
    } error:^(RCErrorCode errorCode, NSString * _Nonnull errorKey) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"SetFailed") hiddenAfterDelay:2];
        });
    }];
}

- (NSString *)tip {
    if (self.canEdit) {
        return nil;
    }
    if (self.group.groupInfoEditPermission == RCGroupOperationPermissionOwner) {
        return RCLocalizedString(@"GroupOperationOnlyOwner");
    }
    if (self.group.groupInfoEditPermission == RCGroupOperationPermissionOwnerOrManager) {
        return RCLocalizedString(@"GroupOperationOwnerAndManager");
    }
    return nil;
}

@end
