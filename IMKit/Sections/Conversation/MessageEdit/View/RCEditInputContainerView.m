//
//  RCEditInputContainerView.m
//  RongIMKit
//
//  Created by RongCloud on 2025/07/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCEditInputContainerView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#import <RongIMLibCore/RongIMLibCore.h>

#define TextViewLineHeight 20.f              // 输入框每行文字高度
#define TextViewSpaceHeight_LessThanMax 17.f // 输入框小于最大行时除文字外上下空隙高度
#define TextViewSpaceHeight 13.f             // 输入框大于等于最大行时除文字外上下空隙高度
#define TextViewMaxInputLines 6              // 输入框最大行数设置
#define TextViewMinInputLines 1              // 输入框最小行数设置

@interface RCEditInputContainerView () <UITextViewDelegate, RCTextViewDelegate>

// 私有UI组件
@property (nonatomic, strong) UIView *topBorderView;                    // 上边框
@property (nonatomic, strong) UIView *inputContainerBackgroundView;      // 输入框容器背景view
@property (nonatomic, strong) UILabel *referencedLabel;                  // 引用消息标签
@property (nonatomic, strong) UIView *editStatusView;                   // 编辑状态容器
@property (nonatomic, strong) UIImageView *editStatusImageView;         // 编辑状态图片
@property (nonatomic, strong) UILabel *editStatusLabel;                  // 编辑状态标签
@property (nonatomic, strong) RCTextView *inputTextView;                 // 文本输入框
@property (nonatomic, strong) UIButton *editExpandButton;               // 展开/收起按钮
@property (nonatomic, strong) UIButton *editConfirmButton;              // 确认按钮
@property (nonatomic, strong) UIButton *editCancelButton;               // 取消按钮
@property (nonatomic, strong) UIButton *editEmojiButton;                // 编辑模式表情按钮

@property (nonatomic, assign) RCEditHeightMode heightMode;

// 约束管理
@property (nonatomic, strong) NSMutableArray *editConstraints;          // 编辑模式约束数组
@property (nonatomic, strong) NSLayoutConstraint *inputTextViewHeightConstraint; // 输入框高度约束

// 键盘状态管理
@property (nonatomic, assign) BOOL textViewBeginEditing;                 // 输入框编辑状态

@end

@implementation RCEditInputContainerView {
    BOOL _didSetupConstraints;
}

#pragma mark - 初始化

- (instancetype)initWithHeightMode:(RCEditHeightMode)heightMode {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _heightMode = heightMode;
        [self setupEditContainer];
    }
    return self;
}

- (void)updateConstraints {
    if (!_didSetupConstraints) {
        [self setupConstraints];
        _didSetupConstraints = YES;
    }
    [super updateConstraints];
}

- (void)setupEditContainer {
    // 默认值设置
    self.maxInputLines = 4;
    self.hasReferenceMessage = NO;
    
    // 创建约束数组
    self.editConstraints = [NSMutableArray array];
    
    // 设置背景色
    self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xF5F6F9", @"0x1c1c1c");
    
    // 创建并添加子视图
    [self setupSubviews];
}

- (void)setupSubviews {
    [self addSubview:self.topBorderView];
    
    // 添加输入容器背景view
    [self addSubview:self.inputContainerBackgroundView];
    
    // 将inputTextView和expandButton添加到容器背景view中
    [self.inputContainerBackgroundView addSubview:self.inputTextView];
    
    if (self.heightMode == RCEditHeightModeNormal) {
        [self.inputContainerBackgroundView addSubview:self.editExpandButton];
    } else {
        [self addSubview:self.editExpandButton];
    }
    
    [self addSubview:self.referencedLabel];
    
    // 添加底部按钮行
    [self addSubview:self.editEmojiButton];
    [self addSubview:self.editCancelButton];
    [self addSubview:self.editConfirmButton];

    [self addSubview:self.editStatusView];
    [self.editStatusView addSubview:self.editStatusImageView];
    [self.editStatusView addSubview:self.editStatusLabel];
}

#pragma mark - 约束设置

- (void)setupConstraints {
    // 清除所有视图的自动调整掩码
    self.topBorderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.referencedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.editStatusView.translatesAutoresizingMaskIntoConstraints = NO;
    self.editStatusImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.editStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputContainerBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.editExpandButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editConfirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editCancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editEmojiButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self updateEditConstraints];
}

- (void)updateEditConstraints {
    // 清除旧约束
    [self removeConstraints:self.editConstraints];
    [self.editConstraints removeAllObjects];
    
    NSMutableArray *constraints = [NSMutableArray array];
    
    if (self.heightMode == RCEditHeightModeExpanded) {
        // 全屏模式布局
        [self setupFullScreenConstraints:constraints];
    } else {
        // 普通模式布局
        [self setupNormalModeConstraints:constraints];
    }
    
    // 底部按钮行约束
    [self setupBottomButtonRowConstraints:constraints];
    
    // 添加约束到数组
    [self.editConstraints addObjectsFromArray:constraints];
    [self addConstraints:self.editConstraints];
    
    [self updateExpandButtonIcon];
    
    // 更新容器总高度
    if (self.heightMode == RCEditHeightModeNormal) {
        [self updateContainerHeight];
    }
    
//    // 立即更新布局
//    [self setNeedsUpdateConstraints];
//    [self updateConstraintsIfNeeded];
//    [self setNeedsLayout];
//    [self layoutIfNeeded];
}

#pragma mark - 布局约束方法

- (void)setupNormalModeConstraints:(NSMutableArray *)constraints {
    // 普通模式布局（原有布局逻辑）
    [constraints addObjectsFromArray:@[
        [self.topBorderView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.topBorderView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.topBorderView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.topBorderView.heightAnchor constraintEqualToConstant:0.5]
    ]];
    
    if (self.hasReferenceMessage) {
        self.referencedLabel.hidden = NO;
        
        [constraints addObjectsFromArray:@[
            [self.referencedLabel.topAnchor constraintEqualToAnchor:self.topBorderView.bottomAnchor constant:10],
            [self.referencedLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [self.referencedLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
            [self.referencedLabel.heightAnchor constraintEqualToConstant:20],
            
            [self.inputContainerBackgroundView.topAnchor constraintEqualToAnchor:self.referencedLabel.bottomAnchor constant:10],
        ]];
    } else {
        self.referencedLabel.hidden = YES;
        
        [constraints addObjectsFromArray:@[
            [self.inputContainerBackgroundView.topAnchor constraintEqualToAnchor:self.topBorderView.bottomAnchor constant:9],
        ]];
    }
    
    [constraints addObjectsFromArray:@[
        [self.inputContainerBackgroundView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.inputContainerBackgroundView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12]
    ]];
    
    // 输入容器背景view的高度约束
    CGFloat inputHeight = [self calculateInputTextViewHeight];
    self.inputTextViewHeightConstraint = [self.inputContainerBackgroundView.heightAnchor constraintEqualToConstant:inputHeight];
    [constraints addObject:self.inputTextViewHeightConstraint];
    
    // inputTextView在容器背景view内的约束
    [constraints addObjectsFromArray:@[
        [self.inputTextView.topAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.topAnchor],
        [self.inputTextView.leadingAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.leadingAnchor],
        [self.inputTextView.bottomAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.bottomAnchor],
        [self.inputTextView.trailingAnchor constraintEqualToAnchor:self.editExpandButton.leadingAnchor constant:-5]
    ]];
    
    // expandButton在容器背景view内的约束
    [constraints addObjectsFromArray:@[
        [self.editExpandButton.topAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.topAnchor constant:5],
        [self.editExpandButton.trailingAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.trailingAnchor constant:-8],
        [self.editExpandButton.widthAnchor constraintEqualToConstant:28],
        [self.editExpandButton.heightAnchor constraintEqualToConstant:28]
    ]];
}

- (void)setupFullScreenConstraints:(NSMutableArray *)constraints {
    // 获取安全区域insets
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    }
    
    // 隐藏顶部边框（全屏模式下不需要）
    self.topBorderView.hidden = YES;
    
    // 移除输入框高度约束（全屏模式下不需要）
    self.inputTextViewHeightConstraint = nil;
    
    // 引用消息行始终显示（全屏模式下）
    [constraints addObjectsFromArray:@[
        // 展开按钮在引用消息行的右侧（全屏模式下显示收起图标）
        [self.editExpandButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],
        [self.editExpandButton.widthAnchor constraintEqualToConstant:28],
        [self.editExpandButton.heightAnchor constraintEqualToConstant:28],
        [self.editExpandButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        
        // 输入容器背景视图位于引用消息下方
        [self.inputContainerBackgroundView.topAnchor constraintEqualToAnchor:self.editExpandButton.bottomAnchor constant:6],
        [self.inputContainerBackgroundView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.inputContainerBackgroundView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [self.inputContainerBackgroundView.bottomAnchor constraintEqualToAnchor:self.editEmojiButton.topAnchor constant:-16],
    ]];

    [constraints addObjectsFromArray:@[
        [self.referencedLabel.centerYAnchor constraintEqualToAnchor:self.editExpandButton.centerYAnchor],
        [self.referencedLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.referencedLabel.heightAnchor constraintGreaterThanOrEqualToConstant:20], // 设置最小高度
        [self.referencedLabel.trailingAnchor constraintEqualToAnchor:self.editExpandButton.leadingAnchor constant:-10]
    ]];
    
    // 输入框在全屏模式下占据整个容器背景视图
    [constraints addObjectsFromArray:@[
        [self.inputTextView.topAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.topAnchor constant:12],
        [self.inputTextView.leadingAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.leadingAnchor constant:12],
        [self.inputTextView.trailingAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.trailingAnchor constant:-12],
        [self.inputTextView.bottomAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.bottomAnchor constant:-12]
    ]];
}

- (void)setupBottomButtonRowConstraints:(NSMutableArray *)constraints {
    [constraints addObjectsFromArray:@[
        // 左侧表情按钮的基本约束（位置约束由调用方设置）
        [self.editEmojiButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.editEmojiButton.topAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.bottomAnchor constant:10],
        [self.editEmojiButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
        [self.editEmojiButton.widthAnchor constraintEqualToConstant:26],
        [self.editEmojiButton.heightAnchor constraintEqualToConstant:26],
        
        // 编辑状态视图约束
        [self.editStatusView.trailingAnchor constraintEqualToAnchor:self.editCancelButton.leadingAnchor constant:-12],
        [self.editStatusView.centerYAnchor constraintEqualToAnchor:self.editCancelButton.centerYAnchor],
        [self.editStatusView.heightAnchor constraintEqualToConstant:20],
        
        // 编辑状态标签约束
        [self.editStatusLabel.trailingAnchor constraintEqualToAnchor:self.editStatusView.trailingAnchor constant:-12], 
        [self.editStatusLabel.centerYAnchor constraintEqualToAnchor:self.editStatusView.centerYAnchor],

        // 编辑状态图片约束
        [self.editStatusImageView.trailingAnchor constraintEqualToAnchor:self.editStatusLabel.leadingAnchor constant:-2],
        [self.editStatusImageView.centerYAnchor constraintEqualToAnchor:self.editStatusView.centerYAnchor],
        [self.editStatusImageView.widthAnchor constraintEqualToConstant:16],
        [self.editStatusImageView.heightAnchor constraintEqualToConstant:16],
        
        // 右侧取消按钮
        [self.editCancelButton.trailingAnchor constraintEqualToAnchor:self.editConfirmButton.leadingAnchor constant:-12],
        [self.editCancelButton.centerYAnchor constraintEqualToAnchor:self.editEmojiButton.centerYAnchor],
        [self.editCancelButton.widthAnchor constraintEqualToConstant:50],
        [self.editCancelButton.heightAnchor constraintEqualToConstant:28],
        
        // 最右侧确认按钮
        [self.editConfirmButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
        [self.editConfirmButton.centerYAnchor constraintEqualToAnchor:self.editEmojiButton.centerYAnchor],
        [self.editConfirmButton.widthAnchor constraintEqualToConstant:50],
        [self.editConfirmButton.heightAnchor constraintEqualToConstant:28]
    ]];
}

#pragma mark - 高度计算

- (CGFloat)calculateInputTextViewHeight {
    CGFloat minHeight = [self getTextViewHeightWithLines:1];
    
    if (!self.inputTextView.text || self.inputTextView.text.length == 0) {
        return minHeight;
    }
    
    CGSize targetSize = CGSizeMake(self.inputTextView.frame.size.width, CGFLOAT_MAX);
    CGSize fittingSize = [self.inputTextView sizeThatFits:targetSize];
    CGFloat calculatedHeight = fittingSize.height;
    
    // 限制在最小和最大高度之间
    CGFloat maxHeight = [self getTextViewHeightWithLines:self.maxInputLines];
    CGFloat finalHeight = MAX(minHeight, MIN(calculatedHeight, maxHeight));
    
    return finalHeight;
}

- (CGFloat)getTextViewHeightWithLines:(NSInteger)lines {
    CGFloat totalHeight = lines * TextViewLineHeight + TextViewSpaceHeight_LessThanMax;
    if (lines >= self.maxInputLines) {
        totalHeight = lines * TextViewLineHeight + TextViewSpaceHeight;
    }
    return totalHeight;
}

- (void)updateContainerHeight {
    // 计算容器总高度
    CGFloat padding = 8;
    CGFloat buttonRowHeight = 28;
    CGFloat rowSpacing = 8;
    CGFloat referenceHeight = self.hasReferenceMessage ? 27 : 0;
    CGFloat bottomPadding = self.hasReferenceMessage ? 4 : 12;
    
    CGFloat totalHeight = padding; // 顶部padding
    
    if (self.hasReferenceMessage) {
        totalHeight += referenceHeight + rowSpacing; // 引用消息 + 间距
    }
    
    totalHeight += [self calculateInputTextViewHeight]; // 输入框高度
    totalHeight += rowSpacing; // 输入框与按钮行间距
    totalHeight += buttonRowHeight; // 按钮高度
    totalHeight += bottomPadding; // 底部padding
    
    // 更新容器frame
    CGRect newFrame = self.frame;
    newFrame.size.height = totalHeight;
    self.frame = newFrame;
    
    // 通知代理高度变化
    if ([self.delegate respondsToSelector:@selector(editInputContainerView:didChangeFrame:)]) {
        [self.delegate editInputContainerView:self didChangeFrame:self.frame];
    }
}

- (void)updateTextViewScrollBehavior {
    if (self.heightMode == RCEditHeightModeExpanded) {
        // 全屏模式下始终启用滚动
        self.inputTextView.scrollEnabled = YES;
    } else {
        // 普通模式下检查当前内容是否超过最大行数
        CGFloat maxHeight = [self getTextViewHeightWithLines:self.maxInputLines];
        CGFloat currentHeight = [self calculateInputTextViewHeight];
        BOOL shouldEnableScroll = currentHeight >= maxHeight;
        
        self.inputTextView.scrollEnabled = shouldEnableScroll;
    }
}

#pragma mark - 文本变化处理

- (void)handleTextChange {
    // 更新文本视图滚动行为
    [self updateTextViewScrollBehavior];
    
    if (self.heightMode == RCEditHeightModeNormal) {
        // 更新输入框高度约束
        CGFloat newHeight = [self calculateInputTextViewHeight];
        if (self.inputTextViewHeightConstraint) {
            self.inputTextViewHeightConstraint.constant = newHeight;
        }
        
        // 更新容器总高度
        [self updateContainerHeight];
        
        // 动画更新布局
        [UIView animateWithDuration:0.2 animations:^{
            [self layoutIfNeeded];
        }];
    }
    // 全屏模式下不需要动态调整高度
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // 代理处理
    if ([self.delegate respondsToSelector:@selector(editInputContainerView:inputTextView:shouldChangeTextInRange:replacementText:)]) {
        return [self.delegate editInputContainerView:self inputTextView:textView shouldChangeTextInRange:range replacementText:text];
    }
    
    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.textViewBeginEditing = YES;
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.textViewBeginEditing = NO;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self handleTextChange];
    
    // 代理处理
    if ([self.delegate respondsToSelector:@selector(editInputContainerView:inputTextViewDidChange:)]) {
        [self.delegate editInputContainerView:self inputTextViewDidChange:textView];
    }
}

#pragma mark - RCTextViewDelegate

- (void)rctextView:(RCTextView *)textView textDidChange:(NSString *)text {
    [self handleTextChange];
}

#pragma mark - 按钮事件处理

- (void)editExpandButtonTapped:(UIButton *)sender {
    if (self.heightMode == RCEditHeightModeNormal) {
        // 展开到全屏模式
        if ([self.delegate respondsToSelector:@selector(editInputContainerViewRequestFullScreenEdit:)]) {
            [self.delegate editInputContainerViewRequestFullScreenEdit:self];
        }
    } else {
        // 收起到普通模式
        if ([self.delegate respondsToSelector:@selector(editInputContainerViewCollapseFromFullScreenEdit:)]) {
            [self.delegate editInputContainerViewCollapseFromFullScreenEdit:self];
        }
    }
}

- (void)editConfirmButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(editInputContainerViewEditConfirm:withText:)]) {
        [self.delegate editInputContainerViewEditConfirm:self withText:self.inputTextView.text];
    }
}

- (void)editCancelButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(editInputContainerViewEditCancel:)]) {
        [self.delegate editInputContainerViewEditCancel:self];
    }
}

- (void)editEmojiButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(editInputContainerViewEditEmojiButtonClicked:)]) {
        [self.delegate editInputContainerViewEditEmojiButtonClicked:self];
    }
}

#pragma mark - 公共方法

- (void)setReferencedContentWithSenderName:(NSString *)senderName content:(NSString *)content {
    self.referencedSenderName = senderName;
    self.referencedContent = content;
    self.hasReferenceMessage = (senderName.length > 0 || content.length > 0);
    
    if (self.hasReferenceMessage) {
        
        [self updateReferencedContent];
    }
    self.referencedLabel.hidden = !self.hasReferenceMessage;
    
    // 只有在正常模式下才重新设置约束吗，因为全屏时引用消息的位置一直存在
    if (self.heightMode == RCEditHeightModeNormal) {
        [self updateEditConstraints];
    }
}

- (void)clearReferencedMessage {
    [self setReferencedContentWithSenderName:nil content:nil];
}

- (void)setInputText:(NSString *)text {
    self.inputTextView.text = text;
    [self handleTextChange];
}

- (NSString *)getInputText {
    return self.inputTextView.text ?: @"";
}

- (void)becomeInputViewFirstResponder {
    // 添加状态检查，避免不必要的重复调用，保护输入内容
    if (![self.inputTextView isFirstResponder]) {
        [self.inputTextView becomeFirstResponder];
    }
}

- (void)resignInputViewFirstResponder {
    // 添加状态检查，避免不必要的重复调用
    if ([self.inputTextView isFirstResponder]) {
        [self.inputTextView resignFirstResponder];
    }
}

- (void)setEditStatus:(NSString *)statusText {
    self.editStatusLabel.text = statusText ?: @"";
    self.editStatusView.hidden = (statusText.length == 0);
}

- (void)setEditEnabled:(BOOL)enabled withStatusMessage:(nullable NSString *)statusMessage {
    // 设置状态提示
    [self setEditStatus:statusMessage];
    
    // 设置确认按钮状态
    self.editConfirmButton.enabled = enabled;
    if (enabled) {
        self.editConfirmButton.backgroundColor = RCDynamicColor(@"primary_color", @"0x007AFF", @"0x007AFF");
    } else {
        self.editConfirmButton.backgroundColor = RCDynamicColor(@"disabled_color", @"0xCCCCCC", @"0xCCCCCC");
    }
}

#pragma mark - 私有方法

- (void)updateReferencedContent {
    if (self.hasReferenceMessage) {
        // 有引用消息时显示实际内容
        NSString *senderName = self.referencedSenderName ?: @"";
        NSString *messageContent = self.referencedContent ?: @"";
        self.referencedLabel.text = [NSString stringWithFormat:@"%@: %@", senderName, messageContent];
    }
}

- (void)updateExpandButtonIcon {
    NSString *icon = (self.heightMode == RCEditHeightModeExpanded) ? @"edit_collapse" : @"edit_expand";
    NSString *iconKey = (self.heightMode == RCEditHeightModeExpanded) ? @"conversation_msg_edit_collapse_img" : @"conversation_msg_edit_expand_img";
    [self.editExpandButton setImage:RCDynamicImage(iconKey, icon) forState:UIControlStateNormal];
}

#pragma mark - Getter

- (UILabel *)referencedLabel {
    if (!_referencedLabel) {
        _referencedLabel = [[UILabel alloc] init];
        _referencedLabel.hidden = YES;
        _referencedLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _referencedLabel.font = [UIFont systemFontOfSize:14];
        _referencedLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0x7C838E", @"0x7C838E");
        _referencedLabel.numberOfLines = 1;
        _referencedLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        // 设置内容优先级，防止高度为0的问题
        [_referencedLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [_referencedLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        // 水平方向的优先级设置
        [_referencedLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_referencedLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _referencedLabel;
}

- (UIView *)inputContainerBackgroundView {
    if (!_inputContainerBackgroundView) {
        _inputContainerBackgroundView = [[UIView alloc] init];
        _inputContainerBackgroundView.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xffffff", @"0x2d2d2d");
        _inputContainerBackgroundView.layer.cornerRadius = 6;
        _inputContainerBackgroundView.layer.masksToBounds = YES;
    }
    return _inputContainerBackgroundView;
}

- (RCTextView *)inputTextView {
    if (!_inputTextView) {
        _inputTextView = [[RCTextView alloc] init];
        _inputTextView.delegate = self;
        _inputTextView.textChangeDelegate = self;
        
        // 设置文本边距
        UIEdgeInsets textEdge = _inputTextView.textContainerInset;
        textEdge.left = 5;
        textEdge.right = 5;
        _inputTextView.textContainerInset = textEdge;
        
        // 设置样式
        _inputTextView.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xFFFFFF00", @"0xFFFFFF00");
        _inputTextView.layer.borderWidth = 0;
        _inputTextView.layer.cornerRadius = 0;
        UIColor *textColor = RCDynamicColor(@"text_primary_color", @"0x000000", @"0xffffffcc");
        [_inputTextView setTextColor:textColor];
        [_inputTextView setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        [_inputTextView setReturnKeyType:UIReturnKeySend];
        _inputTextView.enablesReturnKeyAutomatically = YES;
        [_inputTextView setExclusiveTouch:YES];
        [_inputTextView setAccessibilityLabel:@"edit_input_textView"];
    }
    return _inputTextView;
}

- (UIButton *)editExpandButton {
    if (!_editExpandButton) {
        _editExpandButton = [[UIButton alloc] init];
        [_editExpandButton setImage:RCDynamicImage(@"conversation_msg_edit_expand_img", @"edit_expand") forState:UIControlStateNormal];
        _editExpandButton.layer.masksToBounds = YES;
        [_editExpandButton addTarget:self
                              action:@selector(editExpandButtonTapped:)
                    forControlEvents:UIControlEventTouchUpInside];
    }
    return _editExpandButton;
}

- (UIButton *)editConfirmButton {
    if (!_editConfirmButton) {
        _editConfirmButton = [[UIButton alloc] init];
        [_editConfirmButton setImage:RCDynamicImage(@"conversation_msg_edit_confirm_img",@"edit_confirm") forState:UIControlStateNormal];
        _editConfirmButton.backgroundColor = RCDynamicColor(@"primary_color", @"0x007AFF", @"0x007AFF");
        _editConfirmButton.layer.cornerRadius = 4;
        _editConfirmButton.layer.masksToBounds = YES;
        [_editConfirmButton addTarget:self
                               action:@selector(editConfirmButtonTapped:)
                     forControlEvents:UIControlEventTouchUpInside];
    }
    return _editConfirmButton;
}

- (UIButton *)editCancelButton {
    if (!_editCancelButton) {
        _editCancelButton = [[UIButton alloc] init];
        [_editCancelButton setImage:RCDynamicImage(@"conversation_msg_edit_cancel_img", @"edit_cancel") forState:UIControlStateNormal];
        _editCancelButton.backgroundColor = RCDynamicColor(@"common_background_color", @"0xFFFFFF", @"0x242424");
        _editCancelButton.layer.cornerRadius = 4;
        _editCancelButton.layer.borderWidth = 0.5;
        UIColor *borderColor = RCDynamicColor(@"line_background_color", @"0xE4E7ED", @"0xFFFFFF1A");
        _editCancelButton.layer.borderColor = borderColor.CGColor;
        _editCancelButton.layer.masksToBounds = YES;
        [_editCancelButton addTarget:self
                              action:@selector(editCancelButtonTapped:)
                    forControlEvents:UIControlEventTouchUpInside];
    }
    return _editCancelButton;
}

- (UIButton *)editEmojiButton {
    if (!_editEmojiButton) {
        _editEmojiButton = [[UIButton alloc] init];
        [_editEmojiButton setImage:RCDynamicImage(@"conversation_msg_edit_emoji_img",@"edit_emoji") forState:UIControlStateNormal];
        _editEmojiButton.layer.cornerRadius = 14;
        _editEmojiButton.layer.masksToBounds = YES;
        [_editEmojiButton addTarget:self
                             action:@selector(editEmojiButtonTapped:)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _editEmojiButton;
}

- (void)setMaxInputLines:(NSInteger)maxInputLines {
    if (maxInputLines > TextViewMaxInputLines) {
        maxInputLines = TextViewMaxInputLines;
    }
    if (maxInputLines < TextViewMinInputLines) {
        maxInputLines = TextViewMinInputLines;
    }
    _maxInputLines = maxInputLines;
    
    // 重新计算高度
    [self handleTextChange];
}

- (UIView *)topBorderView {
    if (!_topBorderView) {
        _topBorderView = [[UIView alloc] init];
        _topBorderView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xe3e5e6", @"0x2f2f2f");
    }
    return _topBorderView;
}

- (UIView *)editStatusView {
    if (!_editStatusView) {
        _editStatusView = [[UIView alloc] init];
        _editStatusView.hidden = YES;
    }
    return _editStatusView;
}

- (UIImageView *)editStatusImageView {
    if (!_editStatusImageView) {
        _editStatusImageView = [[UIImageView alloc] init];
        _editStatusImageView.image = RCDynamicImage(@"conversation_msg_edit_status_expired_img",@"edit_status_expired");
    }
    return _editStatusImageView;
}

- (UILabel *)editStatusLabel {
    if (!_editStatusLabel) {
        _editStatusLabel = [[UILabel alloc] init];
        _editStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _editStatusLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _editStatusLabel.textColor = RCDynamicColor(@"hint_color", @"0xFF5A50", @"0xFF5A50"); // 红色文字
        _editStatusLabel.textAlignment = NSTextAlignmentRight;
        _editStatusLabel.numberOfLines = 1;
        _editStatusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        // 设置内容优先级
        [_editStatusLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_editStatusLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _editStatusLabel;
}

@end
