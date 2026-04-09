//
//  RCGroupMemberAdditionalCellViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2025/11/11.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCGroupMemberAdditionalCellViewModel.h"
#import "RCGroupMemberAdditionalCell.h"

@interface RCGroupMemberAdditionalCellViewModel()

@end

@implementation RCGroupMemberAdditionalCellViewModel

- (instancetype)initWithTitle:(NSString *)title
                     portrait:(UIImage *)portrait
{
    self = [super init];
    if (self) {
        self.title = title;
        self.portrait = portrait;
    }
    return self;
}

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCGroupMemberAdditionalCell class] forCellReuseIdentifier:RCGroupMemberAdditionalCellIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupMemberAdditionalCell *cell = [tableView dequeueReusableCellWithIdentifier:RCGroupMemberAdditionalCellIdentifier
                                                                      forIndexPath:indexPath];
    cell.labName.text = self.title;
    cell.portraitImageView.image = self.portrait;
    cell.hideSeparatorLine = self.hideSeparatorLine;
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {

}

@end
