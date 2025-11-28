//
//  RCFriendListCellViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCFriendListCellViewModel.h"
#import "RCFriendListCell.h"
#import "RCProfileViewController.h"
#import "RCUserProfileViewModel.h"
@interface RCFriendListCellViewModel()
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *indexPath;
@end

@implementation RCFriendListCellViewModel

- (instancetype)initWithFriend:(RCFriendInfo *)friendInfo
{
    self = [super init];
    if (self) {
        self.friendInfo = friendInfo;
    }
    return self;
}

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCFriendListCell class] forCellReuseIdentifier:RCFriendListCellIdentifier];
}

- (void)refreshWithFriend:(RCFriendInfo *)friendInfo {
    self.friendInfo = friendInfo;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.indexPath) {
            RCFriendListCell *cell = [self.tableView cellForRowAtIndexPath:self.indexPath];
            if (cell && [cell isKindOfClass:[RCFriendListCell class]]) {
                [cell showPortrait:self.friendInfo.portraitUri];
                cell.labName.text = self.friendInfo.name;
            }
        }
    });
}

- (void)refreshOnlineStatus:(RCSubscribeUserOnlineStatus *)onlineStatus {
    self.onlineStatus = onlineStatus;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.indexPath) {
            RCFriendListCell *cell = [self.tableView cellForRowAtIndexPath:self.indexPath];
            if (cell && [cell isKindOfClass:[RCFriendListCell class]]) {
                cell.onlineStatusView.online = onlineStatus.isOnline;
            }
        }
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.indexPath = indexPath;
    self.tableView = tableView;
    RCFriendListCell *cell = [tableView dequeueReusableCellWithIdentifier:RCFriendListCellIdentifier forIndexPath:indexPath];
    if (self.friendInfo) {
        [cell showPortrait:self.friendInfo.portraitUri];
        cell.labName.text = self.friendInfo.remark.length > 0 ? self.friendInfo.remark : self.friendInfo.name;
        cell.onlineStatusView.hidden = !self.displayOnlineStatus;
        if (self.displayOnlineStatus) {
            cell.onlineStatusView.online = self.onlineStatus.isOnline;
        }
    }
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
    RCProfileViewModel *viewModel = [RCUserProfileViewModel viewModelWithUserId:self.friendInfo.userId];
    RCProfileViewController *profile = [[RCProfileViewController alloc] initWithViewModel:viewModel];
    [vc.navigationController pushViewController:profile animated:YES];
}
@end
