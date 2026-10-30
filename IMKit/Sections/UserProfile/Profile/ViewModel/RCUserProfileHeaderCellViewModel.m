//
//  RCUUserProfileHeaderCellViewModel.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCUserProfileHeaderCellViewModel.h"
#import "RCUserProfileHeaderCell.h"
#import "RCKitCommonDefine.h"
#import "RCUserOnlineStatusUtil.h"

#define RCUUserProfileHeaderCellHeight 82

@implementation RCUserProfileHeaderCellViewModel
- (instancetype)initWithPortrait:(NSString *)portrait name:(NSString *)name remark:(NSString *)remark {
    self = [super init];
    if (self) {
        self.portrait = portrait;
        self.name = name;
        self.remark = remark;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCUserProfileHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:RCUUserProfileHeaderCellIdentifier forIndexPath:indexPath];
    if (self.remark.length > 0) {
        cell.remarkLabel.text = self.remark;
        cell.nameLabel.text = [NSString stringWithFormat:@"%@: %@",RCLocalizedString(@"Nickname"), self.name];
    } else {
        cell.remarkLabel.text = self.name;
    }
    [cell hiddenNameLabel:!self.remark.length];
    [cell.portraitImageView setImageURL:[NSURL URLWithString:self.portrait]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    [cell hiddenOnlineStatusView:!self.displayOnlineStatus];
    [cell updateOnlineStatus:self.isOnline];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCUUserProfileHeaderCellHeight;
}

@end
