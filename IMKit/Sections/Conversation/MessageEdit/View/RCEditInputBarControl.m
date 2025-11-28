//
//  RCEditInputBarControl.m
//  RongIMKit
//
//  Created by RongCloud Code on 2025/7/16.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCEditInputBarControl.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#import "RCExtensionService.h"
#import "RCInputStateManager.h"
#import "RCInputKeyboardManager.h"

const CGFloat Height_EmojiBoardView = 223.5f; // 表情面板高度

// 键盘通知常量
extern NSString *const RCKitKeyboardWillShowNotification;

@interface RCEditInputBarControl () <RCInputStateManagerDelegate, RCInputKeyboardManagerDelegate>

/// 编辑输入容器
@property (nonatomic, strong) RCEditInputContainerView *editInputContainer;

/// 表情面板
@property (nonatomic, strong, nullable) RCEmojiBoardView *emojiBoardView;

/// 键盘管理器
@property (nonatomic, strong) RCInputKeyboardManager *keyboardManager;

/// 当前底部栏状态
@property (nonatomic, assign) KBottomBarStatus currentBottomBarStatus;

@property (nonatomic, assign) CGRect savedFrame; // 保存隐藏前的frame

@property (nonatomic, assign) BOOL isFullScreen;

/// 编辑状态管理
@property (nonatomic, assign) BOOL canEdit;

/// 输入状态管理器 -（包含@功能和引用消息管理)
@property (nonatomic, strong) RCInputStateManager *inputStateManager;

@end

@implementation RCEditInputBarControl

#pragma mark - 重写方法

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (self.isVisible && !self.hidden && [self.delegate respondsToSelector:@selector(editInputBarControl:shouldChangeFrame:)]) {
        [self.delegate editInputBarControl:self shouldChangeFrame:frame];
    }
}

#pragma mark - 初始化

- (instancetype)initWithIsFullScreen:(BOOL)isFullScreen {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _isFullScreen = isFullScreen;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self setupUI];
    _canEdit = YES;
}

- (void)dealloc {
    // 停止键盘监听（键盘管理器会自动处理通知移除）
    [_keyboardManager stopMonitoring];
    
    // 清理表情面板
    [_emojiBoardView removeFromSuperview];
    _emojiBoardView = nil;
}

#pragma mark - UI 设置

- (void)setupUI {
    self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xF5F6F9", @"0x1c1c1c");
    self.hidden = YES;
    self.isVisible = NO;
    self.currentBottomBarStatus = KBottomBarDefaultStatus;
    [self addSubview:self.editInputContainer];
    // 设置约束
    [self setupConstraints];
}

- (void)setupConstraints {
    // 编辑容器填充整个控件
    self.editInputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.editInputContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.editInputContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.editInputContainer.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.editInputContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
}

#pragma mark - 公共方法

- (void)showWithConfig:(RCEditInputBarConfig *)config {
    self.inputBarConfig = config;
    if (!self.isVisible) {
        // 显示控件
        self.isVisible = YES;
        self.hidden = NO;
    }
    // 每次显示重置文本
    [self.editInputContainer setInputText:@""];
    
    // 设置编辑内容
    [self.editInputContainer setInputText:config.textContent ?: @""];
    
    // 设置引用消息
    if (config.referencedSenderName.length > 0 || config.referencedContent.length > 0) {
        [self setReferenceInfo:config.referencedSenderName content:config.referencedContent];
    } else {
        [self.editInputContainer clearReferencedMessage];
    }
    
    if (config.mentionedRangeInfo) {
        [self.inputStateManager setupMentionedRangeInfo:config.mentionedRangeInfo];
    }
    if (self.canEdit) {
        BOOL enable = self.editInputContainer.getInputText.length > 0;
        [self.editInputContainer setEditEnabled:enable withStatusMessage:nil];
    }
}

- (void)exitWithAnimation:(BOOL)animated completion:(void (^)(void))completion {
    [self hideBottomPanelsWithAnimation:animated completion:^{
        [self.editInputContainer setEditEnabled:YES withStatusMessage:@""];
        self.hidden = YES;
        self.isVisible = NO;
        if (completion) {
            completion();
        }
    }];
}

- (void)hideEditInputBar:(BOOL)hidden {
    if (self.hidden == hidden) {
        return;
    }
    if (hidden) {
        [self hideBottomPanelsWithAnimation:YES completion:nil];
        self.savedFrame = self.frame;
    }
    // 计算目标状态
    CGRect targetFrame = [self calculateTargetFrame:hidden];
    self.hidden = hidden;
    // 通知外部frame变化
    [self notifyFrameChange:targetFrame];
}
    
- (void)resetEditInputBar {
    self.editInputContainer.inputTextView.text = @"";
    [self.editInputContainer clearReferencedMessage];
    [self restoreEditStatus];
    [self.inputStateManager clearAllStates];
}

/// 计算目标frame
/// @param hidden 是否隐藏
/// @return 目标frame
- (CGRect)calculateTargetFrame:(BOOL)hidden {
    if (hidden) {
        // 隐藏时：设置到屏幕底部，不占用空间
        CGRect frame = self.savedFrame;
        frame.origin.y = [RCInputKeyboardManager screenBottomY];
        return frame;
    } else {
        // 显示时：恢复到保存的frame
        return self.savedFrame;
    }
}

/// 通知代理frame变化
/// @param frame 新的frame
- (void)notifyFrameChange:(CGRect)frame {
    if ([self.delegate respondsToSelector:@selector(editInputBarControl:shouldChangeFrame:)]) {
        [self.delegate editInputBarControl:self shouldChangeFrame:frame];
    }
}

#pragma mark - 辅助方法

- (NSString *)currentEditText {
    return [self.editInputContainer getInputText];
}

- (void)setEditText:(NSString *)text {
    [self.editInputContainer setInputText:text];
}

#pragma mark - 底部栏动画管理

- (float)getBoardViewBottomOriginY {
    return [RCInputKeyboardManager screenBottomY];
}

- (float)getSafeAreaExtraBottomHeight {
    return [RCKitUtility getWindowSafeAreaInsets].bottom;
}

- (void)layoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus
                         animated:(BOOL)animated
                       completion:(void (^ _Nullable)())completion {
    [self layoutBottomBarWithStatus:bottomBarStatus
                                    animated:animated
                                 forceUpdate:NO
                                  completion:completion];
}

- (void)layoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus
                         animated:(BOOL)animated
                      forceUpdate:(BOOL)forceUpdate
                       completion:(void (^ _Nullable)())completion {
    if (self.currentBottomBarStatus == bottomBarStatus && !forceUpdate) {
        if (completion) {
            completion();
        }
        return;
    }
    if (animated) {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self layoutBottomBarWithStatus:bottomBarStatus];
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    } else {
        [self layoutBottomBarWithStatus:bottomBarStatus];
        if (completion) {
            completion();
        }
    }
}



- (void)layoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus {
    self.currentBottomBarStatus = bottomBarStatus;
    
    // 计算输入栏应该在的位置
    CGRect editBarRect = self.frame;
    float bottomY = [self getBoardViewBottomOriginY];
    CGFloat changedHeight = 0;
    switch (bottomBarStatus) {
        case KBottomBarDefaultStatus: {
            [self hiddenEmojiBoardView];
            [self.editInputContainer resignInputViewFirstResponder];
            changedHeight = 0;
            break;
        }
        case KBottomBarEmojiStatus: {
            [self showEmojiBoardView];
            [self.editInputContainer resignInputViewFirstResponder];
            changedHeight = self.emojiBoardView.bounds.size.height;
            break;
        }
        case KBottomBarKeyboardStatus: {
            [self hiddenEmojiBoardView];
            [self.editInputContainer becomeInputViewFirstResponder];
            changedHeight = self.keyboardManager.currentKeyboardHeight - [RCKitUtility getWindowSafeAreaInsets].bottom;
            break;
        }
        default:
            break;
    }
    editBarRect.origin.y = bottomY - self.bounds.size.height - changedHeight;
    if (self.isFullScreen) {
        if ([self.delegate respondsToSelector:@selector(editInputBarControl:shouldChangeFrame:)]) {
            [self.delegate editInputBarControl:self shouldChangeFrame:CGRectMake(0, 0, 0, changedHeight)];
        }
    } else {
        // 更新输入栏位置
        self.frame = editBarRect;
        
        if ([self.delegate respondsToSelector:@selector(editInputBarControl:shouldChangeFrame:)]) {
            [self.delegate editInputBarControl:self shouldChangeFrame:editBarRect];
        }
    }
}

- (void)showEmojiBoardView {
    // 重新设置表情面板的正确位置
    if (self.bottomPanelsContainerView && self.emojiBoardView.superview != self.bottomPanelsContainerView) {
        self.emojiBoardView.hidden = NO;
        self.emojiBoardView.frame = CGRectMake(0, 0, self.bottomPanelsContainerView.bounds.size.width, Height_EmojiBoardView);
        
        [self.bottomPanelsContainerView addSubview:self.emojiBoardView];
    } else if (self.emojiBoardView.superview != self.superview) {
        CGFloat bottomY = [self getBoardViewBottomOriginY];
        CGFloat topY = bottomY - Height_EmojiBoardView;
        self.emojiBoardView.hidden = NO;
        self.emojiBoardView.frame = CGRectMake(0, topY, self.superview.bounds.size.width, Height_EmojiBoardView);
        
        [self.superview addSubview:self.emojiBoardView];
    }
}

- (void)hiddenEmojiBoardView {
    if (self.emojiBoardView.hidden) {
        return;
    }
    if (self.emojiBoardView) {
        self.emojiBoardView.hidden = YES;
        [self.emojiBoardView removeFromSuperview];
    }
}

#pragma mark - RCInputKeyboardManagerDelegate

- (BOOL)keyboardManagerShouldHandleKeyboardEvent:(RCInputKeyboardManager *)manager {
    BOOL shouldHandle = self.isVisible && !self.isHidden;
    return shouldHandle;
}

- (void)keyboardManager:(RCInputKeyboardManager *)manager
     willShowWithHeight:(CGFloat)height
                  frame:(CGRect)frame
      animationDuration:(NSTimeInterval)duration
         animationCurve:(UIViewAnimationCurve)curve {
    // 使用键盘动画参数进行布局调整。
    // 键盘弹出后，切换布局也会触发 willShow
    NSInteger animationCurveOption = (curve << 16);
    [UIView animateWithDuration:duration delay:0.0 options:animationCurveOption animations:^{
        [self layoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:NO forceUpdate:YES completion:nil];
    } completion:^(BOOL finished) {
        // 处理键盘显示完成后的逻辑
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.editInputContainer.textViewBeginEditing) {
                // 发送键盘通知（保持与原有代码的兼容性）
                [[NSNotificationCenter defaultCenter] postNotificationName:RCKitKeyboardWillShowNotification
                                                                    object:self
                                                                  userInfo:@{@"endFrame": [NSValue valueWithCGRect:frame]}];
            }
        });

    }];
}

- (void)keyboardManagerWillHide:(RCInputKeyboardManager *)manager {
    if (self.currentBottomBarStatus == KBottomBarKeyboardStatus) {
        [self layoutBottomBarWithStatus:KBottomBarDefaultStatus animated:NO completion:nil];
    }
}

#pragma mark - RCEditInputContainerViewDelegate

- (void)editInputContainerViewRequestFullScreenEdit:(RCEditInputContainerView *)editContainerView {
    if ([self.delegate respondsToSelector:@selector(editInputBarControlRequestFullScreenEdit:)]) {
        [self.delegate editInputBarControlRequestFullScreenEdit:self];
    }
}

- (void)editInputContainerViewCollapseFromFullScreenEdit:(RCEditInputContainerView *)editContainerView {
    if ([self.delegate respondsToSelector:@selector(editInputBarControlCollapseFromFullScreenEdit:)]) {
        [self.delegate editInputBarControlCollapseFromFullScreenEdit:self];
    }
}

- (void)editInputContainerViewEditConfirm:(RCEditInputContainerView *)editContainerView withText:(NSString *)text {
    if ([self.delegate respondsToSelector:@selector(editInputBarControl:didConfirmWithText:)]) {
        [self.delegate editInputBarControl:self didConfirmWithText:text];
    }
}

- (void)editInputContainerViewEditCancel:(RCEditInputContainerView *)editContainerView {
    if ([self.delegate respondsToSelector:@selector(editInputBarControlDidCancel:)]) {
        [self.delegate editInputBarControlDidCancel:self];
    }
}

- (void)editInputContainerViewEditEmojiButtonClicked:(RCEditInputContainerView *)editContainerView {
    // 处理编辑模式下的表情按钮点击
    // 表情面板展示时，再次点击不收回表情键盘
    if (self.currentBottomBarStatus != KBottomBarEmojiStatus) {
        [self layoutBottomBarWithStatus:KBottomBarEmojiStatus animated:YES completion:nil];
    }
}

- (void)editInputContainerView:(RCEditInputContainerView *)editContainerView didChangeFrame:(CGRect)frame {
    // 编辑容器高度发生变化时调整整个输入栏的frame
    CGRect vRect = self.frame;
    vRect.size.height = frame.size.height;
    vRect.origin.y += self.frame.size.height - vRect.size.height;
    self.frame = vRect;
    
    // 通知代理frame发生变化
    if ([self.delegate respondsToSelector:@selector(editInputBarControl:shouldChangeFrame:)]) {
        [self.delegate editInputBarControl:self shouldChangeFrame:vRect];
    }
}

- (void)editInputContainerView:(RCEditInputContainerView *)editContainerView inputTextViewDidChange:(UITextView *)textView {
    // 如果当前为不可编辑状态，那么文字变化不重置状态
    if (!self.canEdit) {
        return;
    }
    // 检测输入框是否为空
    NSString *trimmedText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    [self.editInputContainer setEditEnabled:trimmedText.length > 0 withStatusMessage:nil];
}

- (BOOL)editInputContainerView:(RCEditInputContainerView *)editContainerView
                 inputTextView:(UITextView *)textView
       shouldChangeTextInRange:(NSRange)range
               replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if ([self.delegate respondsToSelector:@selector(editInputBarControl:didConfirmWithText:)]) {
            [self.delegate editInputBarControl:self didConfirmWithText:textView.text];
        }
        return NO;
    }
    
    // 处理@逻辑
    BOOL shouldChange = [self.inputStateManager handleTextChange:text inRange:range];
    
    return shouldChange;
}

#pragma mark - RCEmojiViewDelegate

- (void)didTouchEmojiView:(RCEmojiBoardView *)emojiView touchedEmoji:(NSString *)string {
    UITextView *textView = self.editInputContainer.inputTextView;
    
    if (nil == string) {
        // 删除操作
        NSRange range = NSMakeRange(textView.selectedRange.location-1, 1);
        if ([textView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            BOOL shouldChange = [textView.delegate textView:textView shouldChangeTextInRange:range replacementText:@""];
            if (shouldChange) {
                [textView deleteBackward];
            }
        }
    } else {
        // 插入表情
        NSString *replaceString = string;
        if (replaceString.length < 5000) {
            NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:replaceString];
            [attStr addAttribute:NSFontAttributeName
                           value:textView.font
                           range:NSMakeRange(0, replaceString.length)];
            UIColor *foreColor = RCDynamicColor(@"text_primary_color", @"0x000000", @"0xffffffcc");
            if (foreColor) {
                [attStr addAttribute:NSForegroundColorAttributeName
                               value:foreColor
                               range:NSMakeRange(0, replaceString.length)];
            }
            
            NSInteger cursorPosition;
            if (textView.selectedTextRange) {
                cursorPosition = textView.selectedRange.location;
            } else {
                cursorPosition = 0;
            }
            
            // 获取光标位置
            if (cursorPosition > textView.textStorage.length)
                cursorPosition = textView.textStorage.length;
            
            [textView.textStorage insertAttributedString:attStr atIndex:cursorPosition];
            
            // 输入表情触发文本框变化，通知代理
            if ([textView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                BOOL shouldChange = [textView.delegate textView:textView shouldChangeTextInRange:textView.selectedRange replacementText:string];
                if (shouldChange) {
                    if ([textView.delegate respondsToSelector:@selector(textViewDidChange:)]) {
                        [textView.delegate textViewDidChange:textView];
                    }
                }
            }
            
            // 调整光标位置
            NSRange range;
            range.location = textView.selectedRange.location + string.length;
            range.length = 0;
            textView.selectedRange = range;
        }
    }
    
    // 确保光标在可见区域内
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height - (textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top);
    if (overflow > 0) {
        // 滚动到可见区域
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // 留 7 像素边距
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
}

- (void)didSendButtonEvent:(RCEmojiBoardView *)emojiView sendButton:(UIButton *)sendButton {
    NSString *sendText = [self.editInputContainer getInputText];
    NSString *formatString = [sendText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (0 == [formatString length]) {
        // 空文本不能发送
        return;
    }
    
    // 通过代理确认编辑
    if ([self.delegate respondsToSelector:@selector(editInputBarControl:didConfirmWithText:)]) {
        [self.delegate editInputBarControl:self didConfirmWithText:sendText];
    }
}

#pragma mark - 编辑状态管理

- (void)setEditStatus:(BOOL)canEdit reason:(nullable NSString *)reason {
    self.canEdit = canEdit;
    
    // 更新UI状态
    [self.editInputContainer setEditEnabled:canEdit withStatusMessage:reason];
}

- (void)markEditAsExpired {
    [self setEditStatus:NO reason:RCLocalizedString(@"MessageEditExpired")];
}

- (void)restoreEditStatus {
    [self setEditStatus:YES reason:nil];
}

- (void)restoreFocus {
    // 检查编辑控件状态，确保逻辑正确性
    if ((!self.isVisible && !self.isFullScreen) || self.hidden) {
        return;
    }
    if (!self.editInputContainer.superview) {
        return;
    }
    // 延迟一小段时间，避免第一响应者冲突
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.editInputContainer becomeInputViewFirstResponder];
    });
}

- (void)hideBottomPanelsWithAnimation:(BOOL)animated completion:(void (^ _Nullable)(void))completion {
    if (self.currentBottomBarStatus == KBottomBarDefaultStatus) {
        if (completion) {
            completion();
        };
        return;
    }
    [self layoutBottomBarWithStatus:KBottomBarDefaultStatus animated:animated completion:completion];
}

- (void)setIsMentionedEnabled:(BOOL)isMentionedEnabled {
    _isMentionedEnabled = isMentionedEnabled;
    if (self.inputStateManager) {
        self.inputStateManager.isMentionedEnabled = isMentionedEnabled;
    }
}

- (RCMentionedInfo *)mentionedInfo {
    return self.inputStateManager.mentionedInfo;
}

- (void)addMentionedUser:(RCUserInfo *)userInfo symbolRequest:(BOOL)symbolRequest {
    [self.inputStateManager insertMentionedUser:userInfo symbolRequest:symbolRequest];
}

#pragma mark - RCInputStateManagerDelegate

- (void)inputStateManager:(RCInputStateManager *)manager
         showUserSelector:(void (^)(RCUserInfo *))completion
                   cancel:(void (^)(void))cancelBlock {
    // 代理给外部处理用户选择
    if ([self.delegate respondsToSelector:@selector(editInputBarControl:showUserSelector:cancel:)]) {
        [self.delegate editInputBarControl:self showUserSelector:completion cancel:cancelBlock];
    }
}

- (nullable RCUserInfo *)inputStateManager:(RCInputStateManager *)manager
                        getUserInfoForUserId:(NSString *)userId {
    // 代理给外部获取用户信息
    if ([self.dataSource respondsToSelector:@selector(editInputBarControl:getUserInfo:)]) {
        return [self.dataSource editInputBarControl:self getUserInfo:userId];
    }
    return nil;
}

#pragma mark - 引用消息管理（新增功能）

/// 设置引用消息信息
/// @param senderName 引用消息发送者姓名
/// @param content 引用消息内容
- (void)setReferenceInfo:(NSString *)senderName content:(NSString *)content {
    
    // 同时设置到输入容器中用于UI显示
    if ([self.editInputContainer respondsToSelector:@selector(setReferencedContentWithSenderName:content:)]) {
        [self.editInputContainer setReferencedContentWithSenderName:senderName content:content];
    }
}

- (BOOL)hasContent {
    return self.inputStateManager.hasContent;
}

#pragma mark - 光标位置

- (NSRange)getCurrentCursorPosition {
    if (self.editInputContainer && self.editInputContainer.inputTextView) {
        return self.editInputContainer.inputTextView.selectedRange;
    }
    return NSMakeRange(NSNotFound, 0);
}

- (void)setCursorPosition:(NSRange)range {
    if (self.editInputContainer && self.editInputContainer.inputTextView) {
        UITextView *textView = self.editInputContainer.inputTextView;
        NSUInteger textLength = textView.text.length;
        
        // 确保光标位置在有效范围内
        if (range.location != NSNotFound && range.location <= textLength) {
            // if (range.location + range.length > textLength) {
            //     range.length = textLength - range.location;
            // }
            // 暂不支持文本选中的状态，所以将 length 改为 0
            range.length = 0;
            
            // 在主线程异步设置光标位置，确保文本已经完全加载
            dispatch_async(dispatch_get_main_queue(), ^{
                textView.selectedRange = range;
            });
        }
    }
}

- (void)setIsVisible:(BOOL)isVisible {
    _isVisible = isVisible;
    if (isVisible) {
        [self.keyboardManager startMonitoring];
    } else {
        [self.keyboardManager stopMonitoring];
    }
}

#pragma mark - Getter Methods

- (RCEditInputBarConfig *)inputBarConfig {
    if (!_inputBarConfig) {
        _inputBarConfig = [[RCEditInputBarConfig alloc] init];
    }
    _inputBarConfig.textContent = self.editInputContainer.getInputText;
    _inputBarConfig.mentionedRangeInfo = self.inputStateManager.mentionedRangeInfo;
    return _inputBarConfig;
}


- (RCEditInputContainerView *)editInputContainer {
    if (!_editInputContainer) {
        // 创建编辑输入容器
        RCEditHeightMode mode = self.isFullScreen ? RCEditHeightModeExpanded : RCEditHeightModeNormal;
        _editInputContainer = [[RCEditInputContainerView alloc] initWithHeightMode:mode];
        _editInputContainer.delegate = self;
        _editInputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _editInputContainer;
}

- (RCInputStateManager *)inputStateManager {
    if (!_inputStateManager) {
        _inputStateManager = [[RCInputStateManager alloc]
                              initWithTextView:self.editInputContainer.inputTextView
                              delegate:self];
        _inputStateManager.isMentionedEnabled = self.isMentionedEnabled;
    }
    return _inputStateManager;
}

- (RCInputKeyboardManager *)keyboardManager {
    if (!_keyboardManager) {
        _keyboardManager = [[RCInputKeyboardManager alloc] init];
        _keyboardManager.delegate = self;
    }
    return _keyboardManager;
}

- (RCEmojiBoardView *)emojiBoardView {
    if (!_emojiBoardView) {
        _emojiBoardView = [[RCEmojiBoardView alloc]
                           initWithFrame:CGRectMake(0, 0, self.frame.size.width, Height_EmojiBoardView)
                           delegate:self];
        _emojiBoardView.hidden = YES;
    }
    return _emojiBoardView;
}

@end
