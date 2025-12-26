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
    [self.paddingContainerView addSubview:self.roleLabel];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self appendViewAtEnd:self.roleLabel];
}

- (UILabel *)roleLabel {
    if (!_roleLabel) {
        _roleLabel = [[UILabel alloc] init];
        _roleLabel.font = [UIFont systemFontOfSize:14];
        _roleLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xA0A5Ab", @"0x878787");
        _roleLabel.textAlignment = NSTextAlignmentRight;
        _roleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_roleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    }
    return _roleLabel;
}
@end
