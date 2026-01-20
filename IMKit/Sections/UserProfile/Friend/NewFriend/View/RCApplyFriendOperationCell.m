//
//  RCFriendApplyOperationCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCApplyFriendOperationCell.h"
#import "RCKitCommonDefine.h"
#import "RCloudImageView.h"

NSString  * const RCFriendApplyOperationCellIdentifier = @"RCFriendApplyOperationCellIdentifier";
NSInteger const RCApplyFriendOperationCellBtnMinWidth = 45;
NSInteger const RCApplyFriendOperationCellBtnSpace = 10;
@implementation RCApplyFriendOperationCell

- (void)setupView {
    [super setupView];
    self.labStatus.hidden = YES;
    [self.buttonsContainer addSubview:self.btnReject];
    [self.buttonsContainer addSubview:self.btnApprove];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateCGColorUI];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateCGColorUI];
    CGPoint point = self.labName.frame.origin;
    CGFloat labWidth = CGRectGetMinX(self.buttonsContainer.frame) - CGRectGetMinX(self.portraitImageView.frame) - point.x;
    self.labName.frame = CGRectMake(point.x,point.y, labWidth, 24);
    [self.btnApprove sizeToFit];
    [self.btnReject sizeToFit];
    
    CGFloat rejectWidth = MAX(self.btnReject.frame.size.width + RCApplyFriendOperationCellBtnSpace, RCApplyFriendOperationCellBtnMinWidth);
    CGFloat approveWidth = MAX(self.btnApprove.frame.size.width + RCApplyFriendOperationCellBtnSpace, RCApplyFriendOperationCellBtnMinWidth);
    CGRect frame = self.buttonsContainer.frame;
    frame.size.width = approveWidth + rejectWidth + RCFriendApplyCellMargin;
    CGFloat xCenter = self.contentView.frame.size.width - RCFriendApplyCellMargin - frame.size.width/2;
    self.buttonsContainer.frame = frame;
    self.buttonsContainer.center =  CGPointMake(xCenter, self.portraitImageView.center.y);
    
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
@end
