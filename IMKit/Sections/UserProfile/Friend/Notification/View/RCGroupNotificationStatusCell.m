//
//  RCGroupNotificationStatusCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNotificationStatusCell.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#import "RCloudImageView.h"

NSString  * const RCGroupNotificationStatusCellIdentifier = @"RCGroupNotificationStatusCellIdentifier";

@implementation RCGroupNotificationStatusCell

- (void)setupView {
    [super setupView];
    [self.contentView addSubview:self.labStatus];
}

- (void)updateWithViewModel:(RCGroupNotificationCellViewModel *)viewModel {
    [super updateWithViewModel:viewModel];
    switch (viewModel.application.status) {
        case RCGroupApplicationStatusManagerUnHandled:
            self.labStatus.text = RCLocalizedString(@"RCGroupApplicationStatusManagerUnHandled");
            break;
        case RCGroupApplicationStatusManagerRefused:
            self.labStatus.text = RCLocalizedString(@"RCGroupApplicationStatusManagerRefused");
            break;
        case RCGroupApplicationStatusInviteeUnHandled:
            self.labStatus.text = RCLocalizedString(@"RCGroupApplicationStatusInviteeUnHandled");
            break;
        case RCGroupApplicationStatusInviteeRefused:
            self.labStatus.text = RCLocalizedString(@"RCGroupApplicationStatusInviteeRefused");
            break;
        case RCGroupApplicationStatusJoined:
            self.labStatus.text = RCLocalizedString(@"RCGroupApplicationStatusJoined");
            break;
        case RCGroupApplicationStatusExpired:
            self.labStatus.text = RCLocalizedString(@"RCGroupApplicationStatusExpired");
            break;
        default:
            self.labStatus.text = @"";
            break;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.labStatus sizeToFit];

    CGFloat xOffset = CGRectGetMaxX(self.labName.frame) - CGRectGetWidth(self.labStatus.frame);
    CGFloat yOffset = CGRectGetHeight(self.contentView.frame) - RCGroupNotificationCellVerticalMargin - CGRectGetHeight(self.labStatus.frame);
    
    self.labStatus.frame = CGRectMake(xOffset,
                                      yOffset,
                                      CGRectGetWidth(self.labStatus.frame),
                                      CGRectGetHeight(self.labStatus.frame));
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
