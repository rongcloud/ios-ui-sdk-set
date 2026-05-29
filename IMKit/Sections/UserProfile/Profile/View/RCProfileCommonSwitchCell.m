//
//  RCProfileCommonSwitchCell.m
//  RongIMKit
//
//  Created by zgh on 2024/9/2.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileCommonSwitchCell.h"
#import "RCKitCommonDefine.h"

#define RCProfileCommonSwitchTrailing 15
#define RCProfileCommonSwitchTopSpace 50

NSString  * const RCProfileCommonSwitchCellIdentifier = @"RCProfileCommonSwitchCellIdentifier";

@implementation RCProfileCommonSwitchCell

- (void)setupView {
    [super setupView];
    [self.contentView addSubview:self.switchView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.switchView.center = CGPointMake(self.contentView.frame.size.width - self.switchView.frame.size.width/2 - RCProfileCommonSwitchTrailing, self.contentView.center.y);
    CGRect frame = self.titleLabel.frame;
    frame.size.width = self.switchView.frame.origin.x - frame.origin.x - RCProfileCommonSwitchTopSpace;
    self.titleLabel.frame = frame;
}

- (void)switchValueChanged:(UISwitch *)sender {
    [self.delegate switchValueChanged:self.switchView];
}

#pragma mark - getter

- (UISwitch *)switchView {
    if (!_switchView) {
        _switchView = [[UISwitch alloc] init];
        _switchView.onTintColor = HEXCOLOR(0x0099ff);
        [_switchView addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _switchView;
}
@end
