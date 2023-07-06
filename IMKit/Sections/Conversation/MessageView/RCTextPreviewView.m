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

@interface RCTextPreviewView()<RCAttributedLabelDelegate>
@property (nonatomic, strong) RCAttributedLabel *label;
@property (nonatomic, weak) id<RCTextPreviewViewDelegate> textPreviewDelegate;
@property (nonatomic, assign) long messageId;
@end
@implementation RCTextPreviewView
+ (void)showText:(NSString *)text messageId:(long)messageId delegate:(nonnull id<RCTextPreviewViewDelegate>)delegate{
    RCTextPreviewView *textPreviewView = [[RCTextPreviewView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) text:text messageId:messageId];
    textPreviewView.textPreviewDelegate = delegate;
    [textPreviewView showTextPreviewView];
}

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text  messageId:(long)messageId {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = RCDYCOLOR(0xffffff, 0x111111);
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

- (UILabel *)label{
    if (!_label) {
        CGFloat textY = self.contentSize.height < SCREEN_HEIGHT ? (SCREEN_HEIGHT - self.contentSize.height )/2 : 0;
        _label = [[RCAttributedLabel alloc] initWithFrame:CGRectMake(10, textY, SCREEN_WIDTH-20, self.contentSize.height)];
        _label.numberOfLines = 0;
        _label.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:RCMASKCOLOR(0xffffff, 0.8)];
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
