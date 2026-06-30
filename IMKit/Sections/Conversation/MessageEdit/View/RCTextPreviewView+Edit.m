//
//  RCTextPreviewView+Edit.m
//  RongIMKit
//
//  Created by Lang on 2025/8/11.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCTextPreviewView+Edit.h"
#import "RCAttributedLabel+Edit.h"
#import "RCKitCommonDefine.h"

@interface RCTextPreviewView ()

@property (nonatomic, strong) RCAttributedLabel *label;
@property (nonatomic, weak) id<RCTextPreviewViewDelegate> textPreviewDelegate;
@property (nonatomic, copy) NSString *originalText;

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text messageId:(long)messageId;
- (void)showTextPreviewView;

@end

@implementation RCTextPreviewView (Edit)

+ (void)edit_showText:(NSString *)text messageId:(long)messageId edited:(BOOL)edited delegate:(id<RCTextPreviewViewDelegate>)delegate {
    NSString *originalText = text;
    NSString *displayText = [RCMessageEditUtil displayTextForOriginalText:originalText isEdited:edited];
    RCTextPreviewView *textPreviewView = [[RCTextPreviewView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
                                                                             text:displayText
                                                                        messageId:messageId];
    textPreviewView.originalText = originalText;
    // 在字符串最后添加已编辑，并设置颜色
    [textPreviewView.label edit_setTextWithEditedState:originalText isEdited:edited];
    textPreviewView.textPreviewDelegate = delegate;
    [textPreviewView showTextPreviewView];
}

- (NSString *)edit_copyText {
    return self.originalText;
}

@end
