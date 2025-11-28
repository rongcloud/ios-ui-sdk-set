//
//  RCConversationViewController+STT.m
//  RongIMKit
//
//  Created by RobinCui on 2025/5/30.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationViewController+STT.h"
#import "RCMessageModel+STT.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
#import "RCMenuItem.h"
#import "RCMenuController.h"

@interface RCConversationViewController()
@property (nonatomic, strong) RCMessageModel *currentSelectedModel;
@end

@implementation RCConversationViewController (STT)

- (void)stt_didLongTouchSTTInfo:(RCMessageModel *)model inView:(UIView *)view {
    self.chatSessionInputBarControl.inputTextView.disableActionMenu = YES;
    self.currentSelectedModel = model;
    if (![self.chatSessionInputBarControl.inputTextView isFirstResponder]) {
        //聊天界面不为第一响应者时，长按消息，UIMenuController不能正常显示菜单
        // inputTextView 是第一响应者时，不需要再设置 self 为第一响应者，否则会导致键盘收起
        [self becomeFirstResponder];
    }
    CGRect rect = [self.view convertRect:view.frame fromView:view.superview];
    NSArray *menuItems = [self getLongTouchSTTInfoMenuList:model];
    if ([RCKitUtility isTraditionInnerThemes]) {
        UIMenuController *menu = [UIMenuController sharedMenuController];
        [menu setMenuItems:menuItems];
        if (@available(iOS 13.0, *)) {
            [menu showMenuFromView:self.view rect:rect];
        } else {
            [menu setTargetRect:rect inView:self.view];
            [menu setMenuVisible:YES animated:YES];
        }
    } else {
        [[RCMenuController sharedMenuController] showMenuFromView:view
                                                            menuItems:menuItems
                                                        actionHandler:^(RCMenuItem * _Nonnull menuItem, NSInteger index) {
            if ([self respondsToSelector:menuItem.action]) {
                [self performSelector:menuItem.action
                           withObject:[menuItems objectAtIndex:index]];
            }
        }];
    }
}

- (NSArray<UIMenuItem *> *)stt_getLongTouchSTTInfoMenuList:(RCMessageModel *)model {
    NSMutableArray *items = [NSMutableArray array];

    UIMenuItem *copyItem = [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"Copy")
                                                       image:RCDynamicImage(@"conversation_menu_item_copy_img", @"")
                                                      action:@selector(stt_onCopyMessage:)];
    [items addObject:copyItem];
    UIMenuItem *sttItem =
    [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"STTMenuItemUndo")
                                image:RCDynamicImage(@"conversation_menu_item_sound_transform_img", @"")
                               action:@selector(stt_onHideSTTInfo:)];
    [items addObject:sttItem];
    return items;
}

-  (UIMenuItem *)stt_menuItemForModel:(RCMessageModel *)model
{
    if (model.sentStatus == SentStatus_SENDING || model.sentStatus == SentStatus_FAILED ||model.sentStatus == SentStatus_CANCELED) {
        return nil;
    }
    RCAppSettings *settings = [[RCCoreClient sharedCoreClient] getAppSettings];
    if (![settings isSpeechToTextEnable]) {
        return nil;
    }
    if ([model stt_isConverting]) {// 转换中的消息不可修改可见性
        return nil;
    }
    UIMenuItem *sttItem = nil;
    RCSTTContentViewModel *info = [model stt_sttViewModel];
    if (info) {
        if (![info isSTTVisible]) {
            sttItem =
            [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"STTMenuItemDo")
                                        image:RCDynamicImage(@"conversation_menu_item_sound_transform_img", @"")
                                       action:@selector(stt_onShowSTTInfo:)];
        } else {
            sttItem =
            [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"STTMenuItemUndo")
                                        image:RCDynamicImage(@"conversation_menu_item_sound_transform_img", @"")
                                       action:@selector(stt_onHideSTTInfo:)];
        }
    }
    return sttItem;
}

- (void)stt_onShowSTTInfo:(id)sender {
    self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
    RCMessageModel *model = self.currentSelectedModel;
    [model stt_convertSpeedToText:^(RCErrorCode code) {
        if (code != RC_SUCCESS) {
            NSString *tips = RCLocalizedString(@"STTConvertFailureTips");
            if (code == RC_SPEECH_TO_TEXT_MESSAGE_CONTENT_UNSUPPORTED) {
                tips = RCLocalizedString(@"STTConvertFailedByContentTips");
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [RCAlertView showAlertController:nil
                                         message:tips
                                hiddenAfterDelay:3];
            });
        }
    }];
}

- (void)stt_onHideSTTInfo:(id)sender {
    self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
    RCMessageModel *model = self.currentSelectedModel;
    [model stt_hideSpeedToText];
}

- (void)stt_onCopyMessage:(id)sender {
    self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
    RCMessageModel *model = self.currentSelectedModel;
    RCSpeechToTextInfo *info = [[model stt_sttViewModel] messageSTTInfo];
    if (info.status == RCSpeechToTextStatusSuccess) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:info.text];
    }
}
@end
