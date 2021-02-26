//
//  RCTextPreviewView.m
//  RongIMKit
//
//  Created by 张改红 on 2020/7/15.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCTextPreviewView.h"
#import "RCKitCommonDefine.h"
#import "RCMessageCellTool.h"
@interface RCTextPreviewView()<RCAttributedLabelDelegate>
@property (nonatomic, strong) RCAttributedLabel *label;
@property (nonatomic, weak) id<RCTextPreviewViewDelegate> textPreviewDelegate;
@end
@implementation RCTextPreviewView
+ (void)showText:(NSString *)text delegate:(nonnull id<RCTextPreviewViewDelegate>)delegate{
    RCTextPreviewView *textPreviewView = [[RCTextPreviewView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) text:text];
    textPreviewView.textPreviewDelegate = delegate;
    [textPreviewView showTextPreviewView];
}

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = RCDYCOLOR(0xffffff, 0x111111);
        CGFloat textHeight = [RCKitUtility getTextDrawingSize:text font:[UIFont systemFontOfSize:20] constrainedSize:CGSizeMake(SCREEN_WIDTH, MAXFLOAT)].height;
        textHeight = ceilf(textHeight)+20;
        self.contentSize = CGSizeMake(SCREEN_WIDTH, textHeight);
        if (textHeight <= SCREEN_HEIGHT) {
            self.scrollEnabled = NO;
        }else{
            self.scrollEnabled = YES;
        }
        
        self.label.text = text;
        [self addSubview:self.label];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCurrentView)];
        [self addGestureRecognizer:tap];
    }
    return self;
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
