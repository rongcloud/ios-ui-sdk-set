//
//  RCProfileGenderCellViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileGenderCellViewModel.h"
#import "RCProfileGenderCell.h"
#import "RCKitCommonDefine.h"

#define RCProfileGenderCellHeight 44

@interface RCProfileGenderCellViewModel ()
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *indexPath;
@end

@implementation RCProfileGenderCellViewModel
+ (instancetype)cellViewModel:(RCUserGender)gender {
    RCProfileGenderCellViewModel *viewModel = [RCProfileGenderCellViewModel new];
    viewModel.gender = gender;
    return viewModel;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.tableView = tableView;
    self.indexPath = indexPath;
    RCProfileGenderCell *cell = [tableView dequeueReusableCellWithIdentifier:RCProfileGenderCellIdentifier forIndexPath:indexPath];
    cell.titleLabel.text = [self getGenderString:self.gender];
    cell.selectView.hidden = !self.isSelect;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCProfileGenderCellHeight;
}

- (void)reloadData {
    RCProfileGenderCell *cell = [self.tableView cellForRowAtIndexPath:self.indexPath];
    if ([cell isKindOfClass:[RCProfileGenderCell class]]) {
        cell.selectView.hidden = !self.isSelect;
    }
}

#pragma mark -- getter

- (NSString *)getGenderString:(RCUserGender)gender {
    switch (gender) {
        case RCUserGenderMale:
            return RCLocalizedString(@"Male");
        case RCUserGenderFemale:
            return RCLocalizedString(@"Female");
        default:
            break;
    }
    return RCLocalizedString(@"Unknown");
}

@end
