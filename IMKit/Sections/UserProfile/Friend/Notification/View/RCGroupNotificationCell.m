//
//  RCGroupNotificationCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/14.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNotificationCell.h"
#import "RCloudImageView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
NSString  * const RCGroupNotificationCellIdentifier = @"RCGroupNotificationCellIdentifier";
NSInteger const RCGroupNotificationCellHorizontalMargin = 20;
NSInteger const RCGroupNotificationCellPortraitWidth = 40;
NSInteger const RCGroupNotificationCellVerticalMargin = 8;
NSInteger const RCGroupNotificationOperationCellBtnMinWidth = 45;

@implementation RCGroupNotificationCell


- (void)setupView {
    [super setupView];
    self.contentView.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                                darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.portraitImageView];
    [self.contentView addSubview:self.labName];
    [self.contentView addSubview:self.labTips];
    [self.contentView addSubview:self.labStatus];
    [self.contentView addSubview:self.buttonsContainer];
    [self.buttonsContainer addSubview:self.btnReject];
    [self.buttonsContainer addSubview:self.btnApprove];
    [self updateCGColorUI];
    
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateCGColorUI];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat portraitWidth = 40;
    CGFloat marginWidth = RCGroupNotificationCellHorizontalMargin /2;
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    self.portraitImageView.frame = CGRectMake(RCGroupNotificationCellHorizontalMargin, RCGroupNotificationCellVerticalMargin, portraitWidth, portraitWidth);
    
    CGFloat x_offset = CGRectGetMaxX(self.portraitImageView.frame) +RCGroupNotificationCellHorizontalMargin/2;
    CGFloat labWidth = width - x_offset - RCGroupNotificationCellHorizontalMargin;
    self.labTips.frame = CGRectMake(x_offset,
                                    CGRectGetMinY(self.portraitImageView.frame),
                                    labWidth,
                                    0);
    [self.labTips sizeToFit];
    
    CGFloat yOffset =CGRectGetMaxY(self.labTips.frame) + marginWidth;
    self.labName.frame = CGRectMake(x_offset, yOffset, labWidth, 20);
    [self configStatus];
    [self configButtonContainer];
   
}
- (void)configStatus {
    [self.labStatus sizeToFit];
    CGFloat statusXOffset = CGRectGetMaxX(self.labName.frame) - CGRectGetWidth(self.labStatus.frame);
    CGFloat statusYOffset = CGRectGetHeight(self.contentView.frame) - RCGroupNotificationCellVerticalMargin - CGRectGetHeight(self.labStatus.frame);
    
    self.labStatus.frame = CGRectMake(statusXOffset,
                                      statusYOffset,
                                      CGRectGetWidth(self.labStatus.frame),
                                      CGRectGetHeight(self.labStatus.frame));
}
- (void)configButtonContainer {
    CGFloat width = self.contentView.frame.size.width;
    [self updateCGColorUI];
   
    
    [self.btnApprove sizeToFit];
    [self.btnReject sizeToFit];
    
    CGFloat rejectWidth = MAX(self.btnReject.frame.size.width + RCGroupNotificationCellHorizontalMargin/2, RCGroupNotificationOperationCellBtnMinWidth);
    CGFloat approveWidth = MAX(self.btnApprove.frame.size.width + RCGroupNotificationCellHorizontalMargin/2, RCGroupNotificationOperationCellBtnMinWidth);
    CGFloat containerWidth = approveWidth + rejectWidth + RCGroupNotificationCellHorizontalMargin/2;

    CGFloat xOffsetContainer = width-containerWidth-RCGroupNotificationCellHorizontalMargin;
    CGFloat yOffsetContainer = CGRectGetHeight(self.contentView.frame)- RCGroupNotificationCellVerticalMargin - 25;

    self.buttonsContainer.frame = CGRectMake(xOffsetContainer, yOffsetContainer, containerWidth, 25);

    self.btnReject.frame = CGRectMake(0, 0, rejectWidth, CGRectGetHeight(self.buttonsContainer.frame));
    self.btnApprove.frame = CGRectMake(CGRectGetWidth(self.buttonsContainer.frame)-approveWidth, 0, approveWidth, CGRectGetHeight(self.buttonsContainer.frame));
}

- (void)showPortrait:(NSString *)url {
    if (url.length) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:url]];
    } else {
        [self.portraitImageView setImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    }
}

- (BOOL)shouldShowOperationView:(RCGroupApplicationInfo *)application {
    if (application.status == RCGroupApplicationStatusManagerRefused ||
        application.status == RCGroupApplicationStatusInviteeRefused ||
        application.status == RCGroupApplicationStatusJoined ||
        application.status == RCGroupApplicationStatusExpired) {
        return NO;
    }
    // 被邀请
    BOOL invited = application.status == RCGroupApplicationStatusInviteeUnHandled && application.direction == RCGroupApplicationDirectionInvitationReceived;
    if (invited) {
        return YES;
    }
    // 主动申请
    BOOL isApply = application.direction == RCGroupApplicationDirectionApplicationSent;
    if (isApply) {
        return NO;
    }
    // 主动邀请
    BOOL isInvite = application.direction == RCGroupApplicationDirectionInvitationSent;
    if(isInvite) {
        return NO;
    }
    
    if (application.status == RCGroupApplicationStatusManagerUnHandled) {
        return YES;
    }
    return NO;
}

- (void)updateWithViewModel:(RCGroupNotificationCellViewModel *)viewModel {
    self.viewModel = viewModel;
    BOOL isOperationView = [self shouldShowOperationView:viewModel.application];
    self.buttonsContainer.hidden = !isOperationView;
    self.labStatus.hidden = isOperationView;
    // 被邀请
    if (viewModel.application.direction == RCGroupApplicationDirectionInvitationReceived) {
        [self showPortrait:viewModel.application.inviterInfo.portraitUri];
    } else if (viewModel.application.direction == RCGroupApplicationDirectionApplicationReceived) {
        // 申请
        if (viewModel.application.inviterInfo) {//有邀请者
            [self showPortrait:viewModel.application.inviterInfo.portraitUri];
        } else {// 显示申请者
            [self showPortrait:viewModel.application.joinMemberInfo.portraitUri];
        }
      
    } else if (viewModel.application.direction == RCGroupApplicationDirectionApplicationSent) {
            // 显示申请者
        [self showPortrait:viewModel.application.joinMemberInfo.portraitUri];
    } else if (viewModel.application.direction == RCGroupApplicationDirectionInvitationSent) {
        // 显示邀请者
        [self showPortrait:viewModel.application.inviterInfo.portraitUri];
}
    self.labStatus.text = [self statusString:viewModel.application];
}

- (NSString *)statusString:(RCGroupApplicationInfo *)application {
    NSString *status= @"";
    switch (application.status) {
        case RCGroupApplicationStatusManagerUnHandled:
            status = RCLocalizedString(@"RCGroupApplicationStatusManagerUnHandled");
            break;
        case RCGroupApplicationStatusManagerRefused:
            status = RCLocalizedString(@"RCGroupApplicationStatusManagerRefused");
            break;
        case RCGroupApplicationStatusInviteeUnHandled:
            status = RCLocalizedString(@"RCGroupApplicationStatusInviteeUnHandled");
            break;
        case RCGroupApplicationStatusInviteeRefused:
            status = RCLocalizedString(@"RCGroupApplicationStatusInviteeRefused");
            break;
        case RCGroupApplicationStatusJoined:
            status = RCLocalizedString(@"RCGroupApplicationStatusJoined");
            break;
        case RCGroupApplicationStatusExpired:
            status = RCLocalizedString(@"RCGroupApplicationStatusExpired");
            break;
        default:
            self.labStatus.text = @"";
            break;
    }
    return status;
}

- (void)approveApplication {
    [self.viewModel approveApplication];
}

- (void)rejectApplication {
    [self.viewModel rejectApplication];
}
- (void)updateCGColorUI {
    self.btnReject.layer.borderColor = RCDYCOLOR(0xCFCFCF, 0x3C3C3C).CGColor;
}

#pragma mark - GETTER

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



- (UIView *)buttonsContainer {
    if (!_buttonsContainer) {
        _buttonsContainer = [UIView new];
        _buttonsContainer.bounds = CGRectMake(0, 0, 105, 24);
    }
    return _buttonsContainer;
}
- (RCloudImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [RCloudImageView new];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = 20.f;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.bounds = CGRectMake(0, 0, RCGroupNotificationCellPortraitWidth, RCGroupNotificationCellPortraitWidth);
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];

    }
    return _portraitImageView;
}

- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        lab.font = [UIFont systemFontOfSize:12];
        lab.textColor = HEXCOLOR(0x929292);
        _labName = lab;
    }
    return _labName;
}

- (UILabel *)labTips {
    if (!_labTips) {
        UILabel *lab = [UILabel new];
        lab.font = [UIFont systemFontOfSize:15];
        lab.lineBreakMode = NSLineBreakByTruncatingTail;
        lab.numberOfLines = 0;
        _labTips = lab;
    }
    return _labTips;
}

- (UILabel *)labStatus {
    if (!_labStatus) {
        UILabel *lab = [UILabel new];
        lab.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        lab.font = [UIFont systemFontOfSize:13];
        _labStatus = lab;
    }
    return _labStatus;
}
@end
