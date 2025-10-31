//
//  RCNameEditViewController.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCNameEditViewController.h"
#import "RCNameEditView.h"
#import "RCBaseButton.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
#define RCNameEditViewTop 15

@interface RCNameEditViewController ()<
RCNameEditViewModelDelegate,
UITextFieldDelegate
>

@property (nonatomic, strong) RCBaseButton *confirmButton;

@property (nonatomic, strong) RCNameEditView *nameEditView;

@property (nonatomic, strong) RCNameEditViewModel *viewModel;

@end

@implementation RCNameEditViewController

- (instancetype)initWithViewModel:(RCNameEditViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.viewModel.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.viewModel.title;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupView];
    [self setNavigationBarItems];
    __weak typeof(self) weakSelf = self;
    [self.viewModel getCurrentName:^(NSString * name) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.nameEditView.textField.text = name;
        });
    }];
}

- (void)setupView {
    self.view.backgroundColor = self.nameEditView.backgroundColor;
    [self.view addSubview:self.nameEditView];
    self.nameEditView.frame = CGRectOffset(self.view.bounds, 0, RCNameEditViewTop);
}
#pragma mark -- RCNameEditViewModelDelegate

- (void)nameUpdateDidSuccess {
    [self.navigationController popViewControllerAnimated:YES];
    [RCAlertView showAlertController:nil
                             message:RCLocalizedString(@"SetSuccess")
                    hiddenAfterDelay:2];
}

- (void)nameUpdateDidError:(NSString *)errorInfo {
    if (errorInfo.length > 0) {
        [RCAlertView showAlertController:nil 
                                 message:errorInfo
                        hiddenAfterDelay:2];
    }
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark -- UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.confirmButton.enabled = YES;
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (newText.length > self.viewModel.limit) {
        return NO;
    }
    return YES;
}

#pragma mark -- private

- (void)setNavigationBarItems {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    self.confirmButton.enabled = NO;
    
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmButtonDidClick {
    [self.viewModel updateName:self.nameEditView.textField.text];
}

#pragma mark -- getter

- (RCNameEditView *)nameEditView {
    if (!_nameEditView) {
        _nameEditView = [[RCNameEditView alloc] init];
        _nameEditView.contentLabel.text = self.viewModel.content;
        _nameEditView.textField.placeholder = self.viewModel.placeHolder;
        _nameEditView.tipLabel.text = self.viewModel.tip;
        _nameEditView.textField.delegate = self;
    }
    return _nameEditView;
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
