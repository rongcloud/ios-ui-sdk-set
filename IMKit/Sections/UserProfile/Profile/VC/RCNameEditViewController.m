//
//  RCNameEditViewController.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCNameEditViewController.h"
#import "RCNameEditView.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
#define RCNameEditViewTop 15

@interface RCNameEditViewController ()<
RCNameEditViewModelDelegate,
UITextFieldDelegate
>

@property (nonatomic, strong) UIBarButtonItem *confirmButton;

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
#if defined(__IPHONE_27_0)
    if (@available(iOS 27.0, *)) {
        self.edgesForExtendedLayout = UIRectEdgeAll;
        self.navigationItem.navigationBarMinimization.minimizationBehavior = UIBarMinimizationBehaviorNever;
    }
#endif
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
    self.nameEditView.translatesAutoresizingMaskIntoConstraints = NO;
    UILayoutGuide *contentGuide = self.view.layoutMarginsGuide;
    if (@available(iOS 11.0, *)) {
        contentGuide = self.view.safeAreaLayoutGuide;
    }
    [NSLayoutConstraint activateConstraints:@[
        [self.nameEditView.topAnchor constraintEqualToAnchor:contentGuide.topAnchor constant:RCNameEditViewTop],
        [self.nameEditView.leadingAnchor constraintEqualToAnchor:contentGuide.leadingAnchor],
        [self.nameEditView.trailingAnchor constraintEqualToAnchor:contentGuide.trailingAnchor],
        [self.nameEditView.bottomAnchor constraintEqualToAnchor:contentGuide.bottomAnchor]
    ]];
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
    self.navigationItem.rightBarButtonItem = self.confirmButton;
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

- (UIBarButtonItem *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[UIBarButtonItem alloc] initWithTitle:RCLocalizedString(@"Confirm")
                                                       style:UIBarButtonItemStylePlain
                                                      target:self action:@selector(confirmButtonDidClick)];
        _confirmButton.tintColor = RCDynamicColor(@"primary_color", @"0x0099ff", @"0x007acc");
        [_confirmButton setTitleTextAttributes:@{
            NSForegroundColorAttributeName: _confirmButton.tintColor
        } forState:UIControlStateNormal];
        [_confirmButton setTitleTextAttributes:@{
            NSForegroundColorAttributeName: RCDynamicColor(@"text_secondary_color", @"0xA0A5Ab", @"0x9f9f9f")
        } forState:UIControlStateDisabled];
        _confirmButton.enabled = NO;
    }
    return _confirmButton;
}

@end
