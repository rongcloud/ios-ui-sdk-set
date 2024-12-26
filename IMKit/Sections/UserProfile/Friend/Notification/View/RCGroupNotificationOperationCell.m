//
//  RCGroupNotificationOperationCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNotificationOperationCell.h"
#import "RCKitCommonDefine.h"
#import "RCloudImageView.h"

NSString  * const RCGroupNotificationOperationCellIdentifier = @"RCGroupNotificationOperationCellIdentifier";
NSInteger const RCGroupNotificationOperationCellBtnMinWidth = 45;
NSInteger const RCGroupNotificationOperationCellBtnSpace = 10;

@interface RCGroupNotificationOperationCell()

/// 拒绝按钮
@property (nonatomic, strong) UIButton *btnReject;

/// 接受按钮
@property (nonatomic, strong) UIButton *btnApprove;

@property (nonatomic, strong) UIView *buttonsContainer;
@end

@implementation RCGroupNotificationOperationCell

- (void)setupView {
    [super setupView];
    [self.contentView addSubview:self.buttonsContainer];
    [self.buttonsContainer addSubview:self.btnReject];
    [self.buttonsContainer addSubview:self.btnApprove];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateCGColorUI];
}

- (void)updateWithViewModel:(RCGroupNotificationCellViewModel *)viewModel {
    [super updateWithViewModel:viewModel];
    self.viewModel = viewModel;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.frame.size.width;
    [self updateCGColorUI];
   
    
    [self.btnApprove sizeToFit];
    [self.btnReject sizeToFit];
    
    CGFloat rejectWidth = MAX(self.btnReject.frame.size.width + RCGroupNotificationOperationCellBtnSpace, RCGroupNotificationOperationCellBtnMinWidth);
    CGFloat approveWidth = MAX(self.btnApprove.frame.size.width + RCGroupNotificationOperationCellBtnSpace, RCGroupNotificationOperationCellBtnMinWidth);
    CGFloat containerWidth = approveWidth + rejectWidth + RCGroupNotificationCellHorizontalMargin/2;

    CGFloat xOffsetContainer = width-containerWidth-RCGroupNotificationCellHorizontalMargin;
    CGFloat yOffsetContainer = CGRectGetHeight(self.contentView.frame)- RCGroupNotificationCellVerticalMargin - 25;

    self.buttonsContainer.frame = CGRectMake(xOffsetContainer, yOffsetContainer, containerWidth, 25);

    self.btnReject.frame = CGRectMake(0, 0, rejectWidth, CGRectGetHeight(self.buttonsContainer.frame));
    self.btnApprove.frame = CGRectMake(CGRectGetWidth(self.buttonsContainer.frame)-approveWidth, 0, approveWidth, CGRectGetHeight(self.buttonsContainer.frame));
}

#pragma mark -- private

- (void)updateCGColorUI {
    self.btnReject.layer.borderColor = RCDYCOLOR(0xCFCFCF, 0x3C3C3C).CGColor;
}

#pragma mark -- getter

- (UIButton *)btnReject {
    if (!_btnReject) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:RCLocalizedString(@"FriendApplicationRefuse") forState:UIControlStateNormal];
        btn.backgroundColor = RCDYCOLOR(0xFFFFFF, 0x3C3C3C);
        [btn setTitleColor:RCDYCOLOR(0x000000, 0xD3E1EE) forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13];
        btn.layer.borderWidth = 1;
        btn.layer.cornerRadius = 4;
        [btn addTarget:self
                action:@selector(rejectApplication)
      forControlEvents:UIControlEventTouchUpInside];
        _btnReject = btn;
    }
    return _btnReject;
}

- (UIButton *)btnApprove {
    if (!_btnApprove) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:RCLocalizedString(@"FriendApplicationAccept") forState:UIControlStateNormal];
        [btn setBackgroundColor:RCDYCOLOR(0x0099FF, 0x1AA3FF)];
        [btn setTitleColor:RCDYCOLOR(0xFFFFFF, 0x0D0D0D) forState:UIControlStateNormal];
        btn.layer.cornerRadius = 4;
        btn.titleLabel.font = [UIFont systemFontOfSize:13];
        [btn addTarget:self
                action:@selector(approveApplication)
      forControlEvents:UIControlEventTouchUpInside];
        _btnApprove = btn;
    }
    return _btnApprove;
}

- (void)approveApplication {
    [self.viewModel approveApplication];
}

- (void)rejectApplication {
    [self.viewModel rejectApplication];
}

- (UIView *)buttonsContainer {
    if (!_buttonsContainer) {
        _buttonsContainer = [UIView new];
        _buttonsContainer.bounds = CGRectMake(0, 0, 105, 24);
    }
    return _buttonsContainer;
}
@end
