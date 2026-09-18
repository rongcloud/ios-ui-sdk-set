//
//  RCGroupMemberCellViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupMemberCellViewModel.h"
#import "RCGroupMemberCell.h"
#import "RCGroupManager.h"
#import "RCKitCommonDefine.h"

#define RCGroupMemberCellHeight 56

@interface RCGroupMemberCellViewModel ()

@property (nonatomic, strong) RCGroupMemberInfo *memberInfo;

@end

@implementation RCGroupMemberCellViewModel

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:RCGroupMemberCell.class forCellReuseIdentifier:RCGroupMemberCellIdentifier];
}

- (instancetype)initWithMember:(RCGroupMemberInfo *)memberInfo {
    self = [super init];
    if (self) {
        self.memberInfo = memberInfo;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:RCGroupMemberCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.portraitImageView.imageURL = [NSURL URLWithString:self.memberInfo.portraitUri];
    if (self.remark.length > 0) {
        cell.nameLabel.text = self.remark;
    } else if (self.memberInfo.nickname.length > 0) {
        cell.nameLabel.text = self.memberInfo.nickname;
    } else {
        cell.nameLabel.text = self.memberInfo.name;
    }
    cell.roleLabel.text = [self getRoleString:self.memberInfo.role];
    [cell hiddenArrow:self.hiddenArrow];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCGroupMemberCellHeight;
}

#pragma mark -- private

- (NSString *)getRoleString:(RCGroupMemberRole)role {
    NSString *string;
    switch (role) {
        case RCGroupMemberRoleOwner:
            string = RCLocalizedString(@"GroupOwner");
            break;
        case RCGroupMemberRoleManager:
            string = RCLocalizedString(@"GroupManager");
            break;
        default:
            break;
    }
    return string;
}
@end
