//
//  RCProfileFooterViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/22.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileFooterViewModel.h"
#import "RCProfileFooterView.h"
#import "RCApplyFriendAlertView.h"
#import "RCKitCommonDefine.h"
#import "RCConversationViewController.h"
#import "RCAlertView.h"
@interface RCProfileFooterViewModel ()

@property (nonatomic, weak) UIViewController *responder;

@property (nonatomic, assign) RCProfileFooterViewType type;

@property (nonatomic, copy) NSString *targetId;

@end

@implementation RCProfileFooterViewModel
@dynamic delegate;

- (instancetype)initWithResponder:(UIViewController *)responder type:(RCProfileFooterViewType)type targetId:(NSString *)targetId {
    self = [super init];
    if (self) {
        self.responder = responder;
        self.targetId = targetId;
        self.type = type;
    }
    return self;
}

- (UIView *)loadView {
    RCProfileFooterView *footerView = [[RCProfileFooterView alloc] initWithTopSpace:[self topSpace] buttonSpace:[self buttonSpace] items:[self items]];
    return footerView;
}

- (CGFloat)topSpace {
    CGFloat space = 0;
    switch (self.type) {
        case RCProfileFooterViewTypeAddFriend:
            space = 0;
            break;
        case RCProfileFooterViewTypeChat:
            space = 85;
            break;
        case RCProfileFooterViewTypeGroupOwner:
        case RCProfileFooterViewTypeGroupMember:
            space = 25;
            break;
        default:
            break;
    }
    return space;
}

- (CGFloat)buttonSpace {
    return 24;
}

- (NSArray *)items {
    NSArray *array = [NSArray array];
    switch (self.type) {
        case RCProfileFooterViewTypeAddFriend:
            array = [self addFriendItems];
            break;
        case RCProfileFooterViewTypeChat:
            array = [self userItems];
            break;
        case RCProfileFooterViewTypeGroupOwner:
            array = [self groupOwnerItems];
            break;
        case RCProfileFooterViewTypeGroupMember:
            array = [self groupMemberItems];
            break;
        default:
            break;
    }
    if ([self.delegate respondsToSelector:@selector(profileFooterViewModel:willLoadButtonItemsViewModels:)]) {
        array = [self.delegate profileFooterViewModel:self willLoadButtonItemsViewModels:array];
    }
    return array;
}

- (NSArray *)addFriendItems {
    RCButtonItem *item = [RCButtonItem itemWithTitle:RCLocalizedString(@"AddFriend") titleColor:RCDYCOLOR(0xffffff, 0x0D0D0D) backgroundColor:RCDYCOLOR(0x0099ff, 0x1AA3FF)];
    __weak typeof(self) weakSelf = self;
    [item setClickBlock:^{
        [RCApplyFriendAlertView showAlert:RCLocalizedString(@"AddFriend")
                              placeholder:RCLocalizedString(@"AddFriendExtraPlaceholder")
                              lengthLimit:64
                               completion:^(NSString * text) {
            [weakSelf addFriend:text];
        }];
    }];
    return @[item];
}

- (NSArray *)userItems {
    RCButtonItem *chatItem = [RCButtonItem itemWithTitle:RCLocalizedString(@"StartChat") titleColor:RCDYCOLOR(0xffffff, 0x0D0D0D) backgroundColor:RCDYCOLOR(0x0099ff, 0x1AA3FF)];
    __weak typeof(self) weakSelf = self;
    [chatItem setClickBlock:^{
        RCConversationViewController *conversationVC = [[RCConversationViewController alloc] initWithConversationType:ConversationType_PRIVATE targetId:self.targetId];
        [weakSelf.responder.navigationController pushViewController:conversationVC animated:YES];
    }];
    
    if (self.verifyFriend) {
        RCButtonItem *deleteItem = [RCButtonItem itemWithTitle:RCLocalizedString(@"DeleteFriend") titleColor:RCDYCOLOR(0xff0000, 0xFF1A1A) backgroundColor:RCDYCOLOR(0xffffff, 0x3C3C3C)];
        deleteItem.borderColor = RCDYCOLOR(0xCFCFCF, 0x3C3C3C);
        [deleteItem setClickBlock:^{
            [[RCCoreClient sharedCoreClient] getUserProfiles:@[weakSelf.targetId] success:^(NSArray<RCUserProfile *> * _Nonnull userProfiles) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [RCAlertView showAlertController:nil message:[NSString stringWithFormat:RCLocalizedString(@"DeleteFriendAlert"),userProfiles.firstObject.name] actionTitles:nil cancelTitle:RCLocalizedString(@"Cancel") confirmTitle:RCLocalizedString(@"Confirm") preferredStyle:UIAlertControllerStyleAlert actionsBlock:nil cancelBlock:^{
                    } confirmBlock:^{
                        [weakSelf deleteFriend];
                    } inViewController:self.responder];
                });
            } error:^(RCErrorCode errorCode) {
                
            }];
        }];
        return @[chatItem, deleteItem];
    }
    return @[chatItem];
}

- (void)deleteFriend {
    [[RCCoreClient sharedCoreClient] deleteFriends:@[self.targetId?:@""] directionType:(RCDirectionTypeBoth) success:^{
        [[RCCoreClient sharedCoreClient] removeConversation:ConversationType_PRIVATE targetId:self.targetId completion:^(BOOL ret) {
            RCLogE(@"删除联系人成功，清除会话失败");
        }];
        [[RCCoreClient sharedCoreClient] clearHistoryMessages:ConversationType_PRIVATE targetId:self.targetId recordTime:0 clearRemote:YES success:^{
            
        } error:^(RCErrorCode status) {
            RCLogE(@"删除联系人成功，清除消息失败");
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder.navigationController popToViewController:self.responder.navigationController.viewControllers.firstObject animated:YES];
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"DeleteFriendSuccess") hiddenAfterDelay:1];
        });
    } error:^(RCErrorCode errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"DeleteFriendFailed") hiddenAfterDelay:2];
        });
    }];
}

- (NSArray *)groupOwnerItems {
    RCButtonItem *item = [RCButtonItem itemWithTitle:RCLocalizedString(@"GroupActionDismiss") titleColor:RCDYCOLOR(0xFF0000, 0xFF1A1A) backgroundColor:RCDYCOLOR(0xffffff, 0x3C3C3C)];
    item.borderColor = RCDYCOLOR(0xCFCFCF, 0x3C3C3C);
    __weak typeof(self) weakSelf = self;
    [item setClickBlock:^{
        [weakSelf dismissGroup];
    }];
    return @[item];
}

- (NSArray *)groupMemberItems {
    RCButtonItem *item = [RCButtonItem itemWithTitle:RCLocalizedString(@"GroupActionQuit") titleColor:RCDYCOLOR(0xFF0000, 0xFF1A1A) backgroundColor:RCDYCOLOR(0xffffff, 0x3C3C3C)];
    item.borderColor = RCDYCOLOR(0xCFCFCF, 0x3C3C3C);
    __weak typeof(self) weakSelf = self;
    [item setClickBlock:^{
        [weakSelf quitGroup];
    }];
    return @[item];
}

- (void)dismissGroup {
    __weak typeof(self) weakSelf = self;
    [[RCCoreClient sharedCoreClient] dismissGroup:self.targetId success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.responder.navigationController popViewControllerAnimated:YES];
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupDismissSuccess") hiddenAfterDelay:1];
        });
    } error:^(RCErrorCode errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupDismissFailed") hiddenAfterDelay:2];
        });
    }];
}

- (void)quitGroup {
    __weak typeof(self) weakSelf = self;
    [[RCCoreClient sharedCoreClient] quitGroup:self.targetId config:nil success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.responder.navigationController popViewControllerAnimated:YES];
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupQuitSuccess") hiddenAfterDelay:2];
        });
    } error:^(RCErrorCode errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupQuitFailed") hiddenAfterDelay:2];
        });
    }];
}

- (void)addFriend:(NSString *)text{
    [[RCCoreClient sharedCoreClient] addFriend:self.targetId directionType:(RCDirectionTypeBoth) extra:text success:^(RCErrorCode processCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"FriendRequestHasSent") hiddenAfterDelay:2];
        });
    } error:^(RCErrorCode errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"AddFriendFailed") hiddenAfterDelay:2];
        });
    }];
}
@end
