//
//  RCTextPreviewView.m
//  RongIMKit
//
//  Created by 张改红 on 2020/7/15.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCTextPreviewView.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCMessageCellTool.h"
#import "RCAlertView.h"
#import "RCTextPreviewView+Edit.h"
#import "RCMenuItem.h"

@interface RCTextPreviewView()<RCAttributedLabelDelegate>
@property (nonatomic, strong) RCAttributedLabel *label;
@property (nonatomic, weak) id<RCTextPreviewViewDelegate> textPreviewDelegate;
@property (nonatomic, assign) long messageId;
@property (nonatomic, copy) NSString *originalText;
@end
@implementation RCTextPreviewView
+ (instancetype)previewForDelegate:(id<RCTextPreviewViewDelegate>)delegate inView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:self]) {
            RCTextPreviewView *preview = (RCTextPreviewView *)subview;
            if (preview.textPreviewDelegate == delegate) {
                return preview;
            }
        }
    }
    return nil;
}

+ (void)showText:(NSString *)text messageId:(long)messageId delegate:(nonnull id<RCTextPreviewViewDelegate>)delegate{
    RCTextPreviewView *textPreviewView = [[RCTextPreviewView alloc] initWithFrame:CGRectZero text:text messageId:messageId];
    textPreviewView.textPreviewDelegate = delegate;
    [textPreviewView showTextPreviewView];
}

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text  messageId:(long)messageId {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x111111");
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        self.label.text = text;
        [self addSubview:self.label];
        
        self.messageId = messageId;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCurrentView)];
        [self addGestureRecognizer:tap];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.label addGestureRecognizer:longPressGesture];
        
        [self registerNotificationCenter];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveRecallMessageNotification:)
                                                 name:RCKitDispatchRecallMessageNotification
                                               object:nil];
}

- (void)didReceiveRecallMessageNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        long recalledMsgId = [notification.object longValue];
        //产品需求：当前正在查看的引用文本被撤回，dismiss 预览页面
        if (recalledMsgId == self.messageId) {
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"MessageRecallAlert") actionTitles:nil cancelTitle:RCLocalizedString(@"Confirm") confirmTitle:nil preferredStyle:UIAlertControllerStyleAlert actionsBlock:nil cancelBlock:^{
                [self didTapCurrentView];
            } confirmBlock:nil inViewController:nil];
        }
    });
}

#pragma mark - RCAttributedLabelDelegate
- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [self didTapCurrentView];
    if ([self.textPreviewDelegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.textPreviewDelegate didTapUrlInMessageCell:url.absoluteString model:nil];
    }
}

- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    [self didTapCurrentView];
    NSString *number = [@"tel://" stringByAppendingString:phoneNumber];
    if ([self.textPreviewDelegate respondsToSelector:@selector(didTapPhoneNumberInMessageCell:model:)]) {
        [self.textPreviewDelegate didTapPhoneNumberInMessageCell:number model:nil];
    }
}

- (void)attributedLabel:(RCAttributedLabel *)label didTapLabel:(NSString *)content {
    [self didTapCurrentView];
}

#pragma mark - Privite

- (UIView *)previewContentContainerView {
    if ([self.textPreviewDelegate isKindOfClass:UIViewController.class]) {
        UIViewController *viewController = (UIViewController *)self.textPreviewDelegate;
        UINavigationController *navigationController = viewController.navigationController;
        // 折叠后的详情导航栈可能嵌在列表导航栈中，可见导航栏属于外层。
        while ([navigationController.parentViewController isKindOfClass:UINavigationController.class]) {
            navigationController = (UINavigationController *)navigationController.parentViewController;
        }
        return navigationController.view ?: viewController.view;
    }
    return nil;
}

- (CGRect)previewFrameInView:(UIView *)containerView {
    UIView *contentContainerView = [self previewContentContainerView];
    CGRect frame = contentContainerView ? [contentContainerView convertRect:contentContainerView.bounds toView:containerView] : containerView.bounds;
    if ([self.textPreviewDelegate isKindOfClass:UIViewController.class]) {
        UIViewController *viewController = (UIViewController *)self.textPreviewDelegate;
        UIView *conversationView = viewController.view;
        CGRect conversationBounds = conversationView.bounds;
        UISplitViewController *splitViewController = viewController.splitViewController;
        if (splitViewController && !splitViewController.isCollapsed) {
            // 分栏内容可通过安全区和祖先裁剪限定，控制器 bounds 不一定是可见列宽。
            if (@available(iOS 11.0, *)) {
                conversationBounds = conversationView.safeAreaLayoutGuide.layoutFrame;
            }
        }
        CGRect conversationFrame = [conversationView convertRect:conversationBounds toView:containerView];
        if (splitViewController && !splitViewController.isCollapsed) {
            for (UIView *ancestor = conversationView.superview; ancestor && ancestor != containerView;
                 ancestor = ancestor.superview) {
                if (ancestor.clipsToBounds) {
                    CGRect visibleFrame = [ancestor convertRect:ancestor.bounds toView:containerView];
                    CGFloat left = MAX(CGRectGetMinX(conversationFrame), CGRectGetMinX(visibleFrame));
                    CGFloat right = MIN(CGRectGetMaxX(conversationFrame), CGRectGetMaxX(visibleFrame));
                    conversationFrame.origin.x = left;
                    conversationFrame.size.width = MAX(0, right - left);
                }
            }
        }
        frame.origin.x = CGRectGetMinX(conversationFrame);
        frame.size.width = CGRectGetWidth(conversationFrame);
    }
    return frame;
}

- (void)showTextPreviewView {
    UIView *contentContainerView = [self previewContentContainerView];
    UIView *containerView = contentContainerView.window ?: contentContainerView;
    if (!containerView) {
        containerView = [UIApplication sharedApplication].keyWindow;
    }
    self.frame = [self previewFrameInView:containerView];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [containerView addSubview:self];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)layoutSubviews {
    UIView *contentContainerView = [self previewContentContainerView];
    if (contentContainerView && self.superview &&
        (contentContainerView.window == self.superview || contentContainerView == self.superview)) {
        CGRect frame = [self previewFrameInView:self.superview];
        if (!CGRectEqualToRect(self.frame, frame)) {
            self.frame = frame;
        }
    }
    [super layoutSubviews];

    CGSize size = self.bounds.size;
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        insets = self.safeAreaInsets;
    }
    CGFloat textWidth = MAX(0, size.width - insets.left - insets.right - 20);
    if (textWidth <= 0 || size.height <= 0) {
        return;
    }
    CGFloat textHeight = ceil([self.label sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height);
    CGFloat availableHeight = MAX(0, size.height - insets.top - insets.bottom);
    CGFloat textY = insets.top + 10 + MAX(0, (availableHeight - textHeight - 20) / 2);
    self.label.frame = CGRectMake(insets.left + 10, textY, textWidth, textHeight);
    CGFloat contentHeight = MAX(size.height, insets.top + textHeight + 20 + insets.bottom);
    self.contentSize = CGSizeMake(size.width, contentHeight);
    self.scrollEnabled = contentHeight > size.height;
}

- (void)safeAreaInsetsDidChange {
    if (@available(iOS 11.0, *)) {
        [super safeAreaInsetsDidChange];
    }
    [self setNeedsLayout];
}

- (void)didTapCurrentView{
    [self removeFromSuperview];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) { // 确保手势是在开始状态下触发的
        UILabel *label = (UILabel *)gestureRecognizer.view;
        if (label && [label isKindOfClass:[UILabel class]]) {
            // 让 label 成为第一响应者
            [label becomeFirstResponder];
            
            // 创建和显示 menu
            UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:RCLocalizedString(@"Copy")
                                                              action:@selector(copyAction)];
            [[UIMenuController sharedMenuController] setMenuItems:[NSArray arrayWithObject:copyItem]];
            // 设置frame和添加到的视图
            [[UIMenuController sharedMenuController] setTargetRect:label.frame inView:self];
            // 设置弹窗可见
            [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
        }
    }
}

// copy 按钮点击事件
- (void)copyAction {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *labelText = self.label.text;
    NSString *copyText = [self edit_copyText];
    if (copyText.length > 0 && ![copyText isEqualToString:labelText]) {
        pasteboard.string = copyText;
    } else {
        pasteboard.string = labelText;
    }
    [self.label resignFirstResponder];
}

- (UILabel *)label{
    if (!_label) {
        _label = [[RCAttributedLabel alloc] initWithFrame:CGRectZero];
        _label.numberOfLines = 0;
        _label.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc");
        _label.font = [UIFont systemFontOfSize:20];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.attributeDictionary = [RCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:MessageDirection_RECEIVE   ];
        _label.highlightedAttributeDictionary = [RCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:MessageDirection_RECEIVE];
        _label.delegate = self;
        _label.userInteractionEnabled = YES;
    }
    return _label;
}
@end
