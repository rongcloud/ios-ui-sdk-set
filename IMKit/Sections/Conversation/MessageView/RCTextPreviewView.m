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
+ (void)showText:(NSString *)text messageId:(long)messageId delegate:(nonnull id<RCTextPreviewViewDelegate>)delegate{
    RCTextPreviewView *textPreviewView = [[RCTextPreviewView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) text:text messageId:messageId];
    textPreviewView.textPreviewDelegate = delegate;
    [textPreviewView showTextPreviewView];
}

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text  messageId:(long)messageId {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x111111");
        CGFloat textHeight = [RCKitUtility getTextDrawingSize:text font:[UIFont systemFontOfSize:20] constrainedSize:CGSizeMake(SCREEN_WIDTH-20, MAXFLOAT)].height;
        textHeight = ceilf(textHeight)+20;
        self.contentSize = CGSizeMake(SCREEN_WIDTH, textHeight);
        if (textHeight <= SCREEN_HEIGHT) {
            self.scrollEnabled = NO;
        }else{
            self.scrollEnabled = YES;
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

- (void)showTextPreviewView {
    [[UIApplication sharedApplication].keyWindow addSubview:self];
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
        CGFloat textY = self.contentSize.height < SCREEN_HEIGHT ? (SCREEN_HEIGHT - self.contentSize.height )/2 : 0;
        _label = [[RCAttributedLabel alloc] initWithFrame:CGRectMake(10, textY, SCREEN_WIDTH-20, self.contentSize.height)];
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
