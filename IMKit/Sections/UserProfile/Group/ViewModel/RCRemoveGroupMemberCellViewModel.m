//
//  RCSelectGroupMemberCellViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/27.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCRemoveGroupMemberCellViewModel.h"
#import "RCRemoveGroupMemberCell.h"
#import "RCGroupManager.h"
#import "RCKitCommonDefine.h"

#define RCSelectUserCellHeight 56

@interface RCRemoveGroupMemberCellViewModel()

@property (nonatomic, strong) RCGroupMemberInfo *member;

@property (nonatomic, strong) RCRemoveGroupMemberCell *cell;

@property (nonatomic, assign) RCSelectState selectState;

@end

@implementation RCRemoveGroupMemberCellViewModel

- (instancetype)initWithMember:(RCGroupMemberInfo *)member {
    self = [super init];
    if (self) {
        self.member = member;
    }
    return self;
}

- (void)updateCell:(UITableViewCell *)cell state:(RCSelectState)state {
    self.selectState = state;
    if ([cell isKindOfClass:RCRemoveGroupMemberCell.class]) {
        RCRemoveGroupMemberCell *memberCell = (RCRemoveGroupMemberCell *)cell;
        [memberCell updateSelectState:self.selectState];
    }
}

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:RCRemoveGroupMemberCell.class forCellReuseIdentifier:RCRemoveGroupMemberCellIdentifier];
}

#pragma mark -- RCCellViewModelProtocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCRemoveGroupMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:RCRemoveGroupMemberCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.portraitImageView.imageURL = [NSURL URLWithString:self.member.portraitUri];
    cell.roleLabel.hidden = self.hiddenRole;
    cell.roleLabel.text = [self getRoleString:self.member.role];
    if (self.remark.length > 0) {
        cell.nameLabel.text = self.remark;
    } else if (self.member.nickname.length > 0) {
        cell.nameLabel.text = self.member.nickname;
    } else {
        cell.nameLabel.text = self.member.name;
    }
    [cell updateSelectState:self.selectState];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCSelectUserCellHeight;
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
