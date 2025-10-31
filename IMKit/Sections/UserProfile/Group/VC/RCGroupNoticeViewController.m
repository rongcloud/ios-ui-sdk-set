//
//  RCGroupNoticeViewController.m
//  RongIMKit
//
//  Created by zgh on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNoticeViewController.h"
#import "RCGroupNoticeView.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
#import "RCBaseButton.h"
@interface RCGroupNoticeViewController ()<UITextViewDelegate>

@property (nonatomic, strong) RCGroupNoticeViewModel *viewModel;

@property (nonatomic, strong) RCGroupNoticeView *noticeView;

@property (nonatomic, strong) RCBaseButton *confirmButton;

@end

@implementation RCGroupNoticeViewController

- (instancetype)initWithViewModel:(RCGroupNoticeViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
    }
    return self;
}

- (void)loadView {
    self.view = self.noticeView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setNavigationBarItems];
    [self setupView];
}

#pragma mark -- UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (newText.length > self.viewModel.limit) {
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (!self.viewModel.canEdit) {
        return;
    }
    if ([textView.text isEqualToString:self.viewModel.group.notice]) {
        self.confirmButton.enabled = NO;
    } else {
        self.confirmButton.enabled = YES;
    }
}

#pragma mark -- private

- (void)setupView {
    self.noticeView.textView.text = self.viewModel.group.notice;
    self.noticeView.tipLabel.text = [self.viewModel tip];
    [self.noticeView updateTextViewHeight:self.viewModel.canEdit];
    BOOL isEmtpy = (self.viewModel.group.notice.length == 0 && !self.viewModel.canEdit);
    [self.noticeView showEmptylabel:isEmtpy];
}

- (void)setNavigationBarItems {
    if (self.viewModel.canEdit) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
        self.confirmButton.enabled = NO;
    }
    
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmButtonDidClick {
    [self.noticeView.textView resignFirstResponder];
    [self.viewModel updateNotice:self.noticeView.textView.text inViewController:self];
}

#pragma mark -- getter

- (RCGroupNoticeView *)noticeView {
    if (!_noticeView) {
        _noticeView = [RCGroupNoticeView new];
        _noticeView.textView.delegate = self;
    }
    return _noticeView;
}

- (RCBaseButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
        [_confirmButton setTitle:RCLocalizedString(@"Confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:RCDYCOLOR(0x0099ff, 0x007acc) forState:(UIControlStateNormal)];
        [_confirmButton setTitleColor:HEXCOLOR(0xa0a5ab) forState:(UIControlStateDisabled)];
        [_confirmButton addTarget:self action:@selector(confirmButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        _confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _confirmButton.enabled = NO;
    }
    return _confirmButton;
}

@end
