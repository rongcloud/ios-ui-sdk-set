//
//  RCSelectGroupMemberCell.m
//  RongIMKit
//
//  Created by zgh on 2024/8/27.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCRemoveGroupMemberCell.h"
#import "RCKitCommonDefine.h"
NSString  * const RCRemoveGroupMemberCellIdentifier = @"RCSelectGroupMemberCellIdentifier";

#define RCSelectUserCellRoleTrailingSpace 16

@implementation RCRemoveGroupMemberCell

- (void)setupView {
    [super setupView];
    [self.contentView addSubview:self.roleLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.roleLabel sizeToFit];
    self.roleLabel.center = CGPointMake(self.contentView.frame.size.width - RCSelectUserCellRoleTrailingSpace - self.roleLabel.frame.size.width / 2, self.contentView.center.y);
    CGRect frame = self.nameLabel.frame;
    frame.origin.y = 0;
    frame.size.width = self.roleLabel.frame.origin.x - frame.origin.x - RCSelectUserCellRoleTrailingSpace;
    frame.size.height = self.contentView.frame.size.height;
    self.nameLabel.frame = frame;
}

- (UILabel *)roleLabel {
    if (!_roleLabel) {
        _roleLabel = [[UILabel alloc] init];
        _roleLabel.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        _roleLabel.font = self.nameLabel.font;
        _roleLabel.textAlignment = NSTextAlignmentRight;
    }
    return _roleLabel;
}
@end
