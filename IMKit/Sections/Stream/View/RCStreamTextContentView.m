//
//  RCStreamTextContentView.m
//  RongIMKit
//
//  Created by zgh on 2025/3/5.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStreamTextContentView.h"
#import "RCKitConfig.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCMessageCellTool.h"
#import "RCStreamTextContentViewModel.h"
@interface RCStreamTextContentView ()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation RCStreamTextContentView
- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.textView];
    }
    return self;
}

- (void)configViewModel:(RCStreamContentViewModel *)contentViewModel {
    [super configViewModel:contentViewModel];
    if (![contentViewModel isKindOfClass:RCStreamTextContentViewModel.class]) {
        return;
    }
    RCStreamTextContentViewModel *viewModel = (RCStreamTextContentViewModel *)contentViewModel;
    self.textView.attributedText = viewModel.attributedContent;
    self.textView.frame = CGRectMake(0, 0, viewModel.contentSize.width, viewModel.contentSize.height);
}

- (void)cleanView {
    [super cleanView];
    self.textView.frame = CGRectZero;
    self.textView.attributedText = nil;
}

#pragma mark -- getter

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.editable = NO;
        _textView.scrollEnabled = NO;
        _textView.textContainerInset = UIEdgeInsetsZero;
        _textView.textContainer.lineFragmentPadding = 0;
        [_textView setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        _textView.userInteractionEnabled = NO;
    }
    return _textView;
}
@end
