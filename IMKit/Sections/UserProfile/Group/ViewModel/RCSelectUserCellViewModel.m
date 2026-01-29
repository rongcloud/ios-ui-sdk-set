//
//  RCSelectUserCellViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSelectUserCellViewModel.h"
#import "RCSelectUserCell.h"

#define RCSelectUserCellHeight 56

@interface RCSelectUserCellViewModel ()
@property (nonatomic, strong) RCFriendInfo *friendInfo;
@property (nonatomic, assign) BOOL select;
@property (nonatomic, assign) BOOL fixedState;
@property (nonatomic, copy) NSString *groupId;
@end

@implementation RCSelectUserCellViewModel

- (instancetype)initWithFriend:(RCFriendInfo *)friendInfo groupId:(nonnull NSString *)groupId{
    self = [super init];
    if (self) {
        self.friendInfo = friendInfo;
        self.groupId = groupId;
    }
    return self;
}

- (void)updateCell:(UITableViewCell *)cell state:(RCSelectState)state {
    self.selectState = state;
    if ([cell isKindOfClass:RCSelectUserCell.class]) {
        RCSelectUserCell *memberCell = (RCSelectUserCell *)cell;
        [memberCell updateSelectState:self.selectState];
    }
}

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:RCSelectUserCell.class forCellReuseIdentifier:RCSelectUserCellIdentifier];
}

#pragma mark -- RCCellViewModelProtocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCSelectUserCell *cell = [tableView dequeueReusableCellWithIdentifier:RCSelectUserCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.portraitImageView.imageURL = [NSURL URLWithString:self.friendInfo.portraitUri];
    if (self.friendInfo.remark.length > 0) {
        cell.nameLabel.text = self.friendInfo.remark;
    } else {
        cell.nameLabel.text = self.friendInfo.name;
    }
    [cell updateSelectState:self.selectState];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCSelectUserCellHeight;
}
@end
