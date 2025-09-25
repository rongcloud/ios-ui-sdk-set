//
//  RCMessageCell+Edit.m
//  RongIMKit
//
//  Created by Lang on 2025/07/18.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCMessageCell+Edit.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#import "RCMessageModel+Edit.h"

@interface RCMessageCell ()

@property (nonatomic, assign) RCMessageModifyStatus editStatus;

@end

@implementation RCMessageCell (Edit)

#pragma mark - 编辑状态管理

- (void)edit_showEditStatusIfNeeded {
    if (!RCKitConfigCenter.message.enableEditMessage) {
        return;
    }
    RCMessageModifyInfo *modifyInfo = self.model.modifyInfo;
    if (modifyInfo && modifyInfo.status != RCMessageModifyStatusSuccess) {
        [self edit_updateEditStatus:modifyInfo.status];
    } else {
        [self edit_hideAllEditStatusViews];
    }
}

- (void)edit_updateEditStatus:(RCMessageModifyStatus)editStatus {
    [self edit_hideAllEditStatusViews];
    self.editStatus = editStatus;
    self.editStatusContentView.hidden = editStatus == RCMessageModifyStatusSuccess;
    
    if (self.editStatusContentView.hidden) {
        return;
    }
    switch (editStatus) {
        case RCMessageModifyStatusSuccess:
            [self edit_showEditStatusSuccess];
            break;
        case RCMessageModifyStatusUpdating:
            [self edit_showEditStatusUpdating];
            break;
        case RCMessageModifyStatusFailed:
            [self edit_showEditStatusFailed];
            break;
    }
    
    // 布局更新
    [self edit_layoutEditStatusViews];
}

- (void)edit_hideEditStatus {
    [self edit_updateEditStatus:RCMessageModifyStatusSuccess];
}

+ (CGFloat)edit_editStatusBarHeightWithModel:(RCMessageModel *)model {
    if (RCKitConfigCenter.message.enableEditMessage
        && model.modifyInfo
        && model.modifyInfo.status != RCMessageModifyStatusSuccess) {
        return 30.0;// 默认高度，可以根据需要调整
    }
    return 0.0;
}

#pragma mark - 私有状态显示方法

/// 显示更新中状态
- (void)edit_showEditStatusUpdating {
    self.editStatusLabel.text = RCLocalizedString(@"MessageEditUpdating");
    self.editStatusLabel.hidden = NO;
    self.editCircularLoadingView.hidden = NO;
    [self.editCircularLoadingView startAnimating];
}

/// 显示编辑成功状态
- (void)edit_showEditStatusSuccess {
    [self edit_hideAllEditStatusViews];
}

/// 显示编辑失败状态  
- (void)edit_showEditStatusFailed {
    self.editRetryButton.hidden = NO;
}

/// 隐藏所有编辑状态视图
- (void)edit_hideAllEditStatusViews {
    self.editStatusContentView.hidden = YES;
    self.editStatusLabel.hidden = YES;
    self.editRetryButton.hidden = YES;
    self.editCircularLoadingView.hidden = YES;
    [self.editCircularLoadingView stopAnimating];
}

#pragma mark - 布局管理

- (void)edit_layoutEditStatusViews {
    // 只对发送消息进行编辑状态布局
    if (self.model.messageDirection != MessageDirection_SEND) {
        [self edit_hideAllEditStatusViews];
        return;
    }
    CGRect statusFrame = self.baseContentView.bounds;
    statusFrame.size.width = CGRectGetMaxX(self.messageContentView.frame);
    statusFrame.size.height = [[self class] edit_editStatusBarHeightWithModel:self.model];
    statusFrame.origin.y = self.baseContentView.bounds.size.height - statusFrame.size.height;
    self.editStatusContentView.frame = statusFrame;

    self.editStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.editRetryButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editCircularLoadingView.translatesAutoresizingMaskIntoConstraints = NO;

    // 设置内容优先级
    [self.editStatusLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self.editStatusLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObjectsFromArray:@[
        [self.editStatusLabel.centerYAnchor constraintEqualToAnchor:self.editStatusContentView.centerYAnchor],
        [self.editStatusLabel.trailingAnchor constraintEqualToAnchor:self.editStatusContentView.trailingAnchor],
        
        [self.editCircularLoadingView.centerYAnchor constraintEqualToAnchor:self.editStatusLabel.centerYAnchor],
        [self.editCircularLoadingView.trailingAnchor constraintEqualToAnchor:self.editStatusLabel.leadingAnchor constant:-5],
        [self.editCircularLoadingView.widthAnchor constraintEqualToConstant:12],
        [self.editCircularLoadingView.heightAnchor constraintEqualToConstant:12],
        
        [self.editRetryButton.trailingAnchor constraintEqualToAnchor:self.editStatusContentView.trailingAnchor constant:0],
        [self.editRetryButton.centerYAnchor constraintEqualToAnchor:self.editStatusContentView.centerYAnchor],
    ]];
    
    [self.editStatusContentView addConstraints:constraints];

    // 立即更新布局
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - 事件处理

/// 编辑重试按钮点击事件
/// @param button 重试按钮
- (void)edit_didTapEditRetryButton:(UIButton *)sender {
    // 显示为更新中
    [self edit_updateEditStatus:RCMessageModifyStatusUpdating];
    // 通过委托通知外部
    if ([self.delegate respondsToSelector:@selector(edit_didTapEditRetryButton:)]) {
        [self.delegate didTapEditRetryButton:self.model];
    }
}

@end 
