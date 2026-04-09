//
//  RCGroupCreateView.m
//  RongIMKit
//
//  Created by zgh on 2024/8/22.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupCreateView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#define RCGroupCreateViewPortraitSize 70
#define RCGroupCreateViewNameTopSpace 20
#define RCGroupCreateViewCreateLeading 16
#define RCGroupCreateViewCreateBottom 40
#define RCGroupCreateViewCreateHeight 42

@interface RCGroupCreateView ()

@end

@implementation RCGroupCreateView


- (void)setupConstraints {
    [super setupConstraints];
    [NSLayoutConstraint activateConstraints:@[
           [self.portraitImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:RCGroupCreateViewNameTopSpace],
           [self.portraitImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
           [self.portraitImageView.widthAnchor constraintEqualToConstant:RCGroupCreateViewPortraitSize],
           [self.portraitImageView.heightAnchor constraintEqualToConstant:RCGroupCreateViewPortraitSize],
           
           [self.nameEditView.topAnchor constraintEqualToAnchor:self.portraitImageView.bottomAnchor constant:RCGroupCreateViewNameTopSpace],
           [self.nameEditView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
           [self.nameEditView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
           [self.nameEditView.heightAnchor constraintEqualToConstant:RCGroupCreateViewPortraitSize*2],
           
           [self.createButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-RCGroupCreateViewCreateBottom],
           [self.createButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:RCGroupCreateViewCreateLeading],
           [self.createButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-RCGroupCreateViewCreateLeading],
           [self.createButton.heightAnchor constraintEqualToConstant:RCGroupCreateViewCreateHeight]
       ]];
}
#pragma mark -- private

- (void)setupView {
    [super setupView];
    self.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf5f6f9", @"0x111111");
    [self addSubview:self.portraitImageView];
    [self addSubview:self.nameEditView];
    [self addSubview:self.createButton];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    // 设置点击次数（默认为1）
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    self.userInteractionEnabled = YES;
}


- (void)handleTap {
    if ([self.nameEditView.textField isFirstResponder]) {
        [self.nameEditView.textField resignFirstResponder];
    }
}

- (void)portraitImageViewTapped {
    [self.delegate portaitImageViewDidClick];
}

#pragma mark - getter

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] init];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCGroupCreateViewPortraitSize/2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_group_portrait_img", @"default_group_portrait")];
        _portraitImageView.userInteractionEnabled = YES;
        
        // 添加 Tap 手势识别器
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(portraitImageViewTapped)];
        [_portraitImageView addGestureRecognizer:tapGesture];
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _portraitImageView;
}

- (RCNameEditView *)nameEditView {
    if (!_nameEditView) {
        _nameEditView = [[RCNameEditView alloc] init];
        _nameEditView.contentLabel.text = RCLocalizedString(@"GroupName");
        _nameEditView.textField.placeholder = RCLocalizedString(@"GroupNameEditPlaceholderWithLimit");
        _nameEditView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _nameEditView;
}

- (RCBaseButton *)createButton {
    if (!_createButton) {
        _createButton = [[RCBaseButton alloc] init];
        [_createButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        _createButton.enabled = YES;
        [_createButton setTitle:RCLocalizedString(@"GroupCreate") forState:(UIControlStateNormal)];
        _createButton.backgroundColor = RCDynamicColor(@"primary_color",@"0x0099ff", @"0x007acc");
        _createButton.layer.cornerRadius = 5;
        _createButton.layer.masksToBounds = YES;
        _createButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _createButton;
}

@end
