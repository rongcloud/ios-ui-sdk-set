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
#define RCGroupCreateViewPortaritBackgroudHeight 125
#define RCGroupCreateViewPortraitSize 70
#define RCGroupCreateViewPortraitTop 55
#define RCGroupCreateViewNameTopSpace 17
#define RCGroupCreateViewNameHeight 44
#define RCGroupCreateViewCreateLeading 25
#define RCGroupCreateViewCreateBottom 34
#define RCGroupCreateViewCreateHeight 40

@interface RCGroupCreateView ()

@property (nonatomic, strong) UIView *portaritBackgroudView;

@end

@implementation RCGroupCreateView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.portaritBackgroudView.frame = CGRectMake(0, 0, self.frame.size.width, RCGroupCreateViewPortaritBackgroudHeight);
    self.portraitImageView.frame = CGRectMake(0, 0, RCGroupCreateViewPortraitSize, RCGroupCreateViewPortraitSize);
    self.portraitImageView.center = self.portaritBackgroudView.center;
    self.nameEditView.frame = CGRectMake(0, CGRectGetMaxY(self.portaritBackgroudView.frame) + RCGroupCreateViewNameTopSpace, self.frame.size.width, RCGroupCreateViewNameHeight);
    self.createButton.frame = CGRectMake(RCGroupCreateViewCreateLeading, self.frame.size.height - RCGroupCreateViewCreateBottom - RCGroupCreateViewCreateHeight, self.frame.size.width - RCGroupCreateViewCreateLeading * 2, RCGroupCreateViewCreateHeight);
}

#pragma mark -- private

- (void)setupView {
    [super setupView];
    self.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x111111);
    [self addSubview:self.portaritBackgroudView];
    [self.portaritBackgroudView addSubview:self.portraitImageView];
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

- (UIView *)portaritBackgroudView {
    if (!_portaritBackgroudView) {
        _portaritBackgroudView = [UIView new];
        _portaritBackgroudView.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                                          darkColor:HEXCOLOR(0x1c1c1e)];
    }
    return _portaritBackgroudView;
}

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
    }
    return _portraitImageView;
}

- (RCNameEditView *)nameEditView {
    if (!_nameEditView) {
        _nameEditView = [[RCNameEditView alloc] init];
        _nameEditView.contentLabel.text = RCLocalizedString(@"GroupName");
        _nameEditView.textField.placeholder = RCLocalizedString(@"GroupNameEditPlaceholder");
    }
    return _nameEditView;
}

- (RCBaseButton *)createButton {
    if (!_createButton) {
        _createButton = [[RCBaseButton alloc] init];
        [_createButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        _createButton.enabled = YES;
        [_createButton setTitle:RCLocalizedString(@"GroupCreate") forState:(UIControlStateNormal)];
        _createButton.backgroundColor = RCDYCOLOR(0x0099ff, 0x007acc);
        _createButton.layer.cornerRadius = 5;
        _createButton.layer.masksToBounds = YES;
    }
    return _createButton;
}

@end
