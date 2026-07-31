//
//  RCProfileSwitchCellViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/9/2.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileSwitchCellViewModel.h"
#import "RCProfileCommonSwitchCell.h"

@interface RCProfileSwitchCellViewModel ()<RCProfileCommonSwitchCellDelegate>

@end

@implementation RCProfileSwitchCellViewModel

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCProfileCommonSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:RCProfileCommonSwitchCellIdentifier forIndexPath:indexPath];
    cell.titleLabel.text = self.title;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.arrowView.hidden = YES;
    cell.switchView.on = self.switchOn;
    cell.delegate = self;
    cell.hideSeparatorLine = self.hideSeparatorLine;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCUserManagementCellHeight;
}

#pragma mark -- RCProfileCommonSwitchCellDelegate

- (void)switchValueChanged:(nonnull UISwitch *)switchView {
    if(self.switchValueChanged) {
        self.switchValueChanged(switchView.on);
    }
}

@end
