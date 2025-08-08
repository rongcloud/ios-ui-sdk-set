//
//  RCFullScreenEditView.h
//  RongIMKit
//
//  Created by RongCloud Code on 2025/7/17.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCEditInputBarControl.h"

NS_ASSUME_NONNULL_BEGIN

@class RCFullScreenEditView;

@protocol RCFullScreenEditViewDelegate <NSObject>

/// 全屏编辑点击折叠
- (void)fullScreenEditViewCollapse:(RCFullScreenEditView *)fullScreenEditView;

/// 编辑输入控件
- (void)fullScreenEditView:(RCFullScreenEditView *)fullScreenEditView didConfirmWithText:(NSString *)text;

/// 编辑点击取消
- (void)fullScreenEditViewCancel:(RCFullScreenEditView *)fullScreenEditView;

/// 编辑输入控件显示用户选择器
- (void)fullScreenEditView:(RCFullScreenEditView *)fullScreenEditView
          showUserSelector:(void (^)(RCUserInfo *selectedUser))selectedBlock
                    cancel:(void (^)(void))cancelBlock;

@end

@interface RCFullScreenEditView : UIView

/// 会话类型
@property (nonatomic, assign) RCConversationType conversationType;

/// 目标ID
@property (nonatomic, copy) NSString *targetId;

/// 代理
@property (nonatomic, weak) id<RCFullScreenEditViewDelegate> delegate;

/// 编辑输入容器
@property (nonatomic, strong) RCEditInputBarControl *editInputBarControl;

/// isMentionedEnabled
@property (nonatomic, assign) BOOL isMentionedEnabled;

- (void)showWithConfig:(RCEditInputBarConfig *)config animation:(BOOL)animated;

/// 隐藏全屏编辑视图
- (void)hideWithAnimation:(BOOL)animated completion:(void(^_Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
