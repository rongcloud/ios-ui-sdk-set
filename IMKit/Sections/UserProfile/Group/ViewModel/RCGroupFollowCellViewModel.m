//
//  RCGroupFollowCellViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/11/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupFollowCellViewModel.h"
#import "RCGroupFollowCell.h"
#import "RCAlertView.h"
#import "RCKitCommonDefine.h"

@interface RCGroupFollowCellViewModel ()
@property (nonatomic, strong) RCGroupMemberInfo *memberInfo;
@end

@implementation RCGroupFollowCellViewModel
+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:RCGroupFollowCell.class forCellReuseIdentifier:RCGroupFollowCellIdentifier];
}

- (instancetype)initWithMember:(RCGroupMemberInfo *)memberInfo {
    self = [super init];
    if (self) {
        self.memberInfo = memberInfo;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupFollowCell *cell = [tableView dequeueReusableCellWithIdentifier:RCGroupFollowCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.portraitImageView.imageURL = [NSURL URLWithString:self.memberInfo.portraitUri];
    if (self.remark.length > 0) {
        cell.nameLabel.text = self.remark;
    } else if (self.memberInfo.nickname.length > 0) {
        cell.nameLabel.text = self.memberInfo.nickname;
    } else {
        cell.nameLabel.text = self.memberInfo.name;
    }
    [cell setActionBlock:^{
        if ([self.delegate respondsToSelector:@selector(actionButtonDidClick:)]) {
            [self.delegate actionButtonDidClick:self];
        }
    }];
    cell.actionButton.hidden = self.hiddenButton;
    cell.actionButton.userInteractionEnabled = !self.hiddenButton;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

@end
