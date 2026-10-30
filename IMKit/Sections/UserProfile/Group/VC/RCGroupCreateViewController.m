//
//  RCGroupCreateViewController.m
//  RongIMKit
//
//  Created by zgh on 2024/8/22.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupCreateViewController.h"
#import "RCGroupCreateView.h"
#import "RCKitCommonDefine.h"
@interface RCGroupCreateViewController ()<RCGroupCreateViewDelegate, RCGroupCreateViewModelResponder, UITextFieldDelegate>

@property (nonatomic, strong) RCGroupCreateView *createView;

@property (nonatomic, strong) RCGroupCreateViewModel *viewModel;

@end

@implementation RCGroupCreateViewController

- (instancetype)initWithViewModel:(RCGroupCreateViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.viewModel.responder = self;
    }
    return self;
}

- (void)loadView {
    self.view = self.createView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = RCLocalizedString(@"GroupCreate");
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setNavigationBarItems];
}

#pragma mark -- UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (newText.length > self.viewModel.groupNameLimit) {
        return NO;
    }
    return YES;
}

#pragma mark -- RCGroupCreateViewModelResponder

- (void)groupPortraitDidUpdate:(NSString *)portraitUri {
    self.createView.portraitImageView.imageURL = [NSURL URLWithString:portraitUri];
}

#pragma mark -- RCGroupCreateViewDelegate

- (void)portaitImageViewDidClick {
    [self.viewModel portraitImageViewDidClick:self];
}

#pragma mark -- action

- (void)createButtonDidClick {
    [self.viewModel createGroup:self.createView.nameEditView.textField.text inViewController:self];
}

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- private

- (void)setNavigationBarItems {
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

#pragma mark -- getter

- (RCGroupCreateView *)createView {
    if (!_createView) {
        _createView = [RCGroupCreateView new];
        [_createView.createButton addTarget:self action:@selector(createButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
        _createView.delegate = self;
        _createView.nameEditView.textField.delegate = self;
    }
    return _createView;
}

@end
