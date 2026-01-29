//
//  RCProfileCommonSwitchCell.m
//  RongIMKit
//
//  Created by zgh on 2024/9/2.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileCommonSwitchCell.h"
#import "RCKitCommonDefine.h"


NSString  * const RCProfileCommonSwitchCellIdentifier = @"RCProfileCommonSwitchCellIdentifier";

@implementation RCProfileCommonSwitchCell

- (void)setupView {
    [super setupView];
    [self.contentStackView addArrangedSubview:self.titleLabel];
    [self.contentStackView addArrangedSubview:self.switchView];
    [self.contentStackView addArrangedSubview:self.arrowView];
}

- (void)switchValueChanged:(UISwitch *)sender {
    [self.delegate switchValueChanged:self.switchView];
}

#pragma mark - getter

- (UISwitch *)switchView {
    if (!_switchView) {
        _switchView = [[UISwitch alloc] init];
        _switchView.onTintColor = RCDynamicColor(@"success_color", @"0x0099ff", @"0x0099ff");
        [_switchView addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        _switchView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _switchView;
}
@end
