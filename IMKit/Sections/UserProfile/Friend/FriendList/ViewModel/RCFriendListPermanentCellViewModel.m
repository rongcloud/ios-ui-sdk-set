//
//  RCFriendListPermanentCellViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCFriendListPermanentCellViewModel.h"
#import "RCFriendListPermanentCell.h"
#import "RCKitCommonDefine.h"

@interface RCFriendListPermanentCellViewModel()
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *portrait;
@property (nonatomic, copy) RCPermanentCellViewModelBlock touchBlock;
@end

@implementation RCFriendListPermanentCellViewModel

- (instancetype)initWithTitle:(NSString *)title 
                     portrait:(UIImage *)portrait
                   touchBlock:(RCPermanentCellViewModelBlock)touchBlock
{
    self = [super init];
    if (self) {
        self.title = title;
        self.portrait = portrait;
        self.touchBlock = touchBlock;
    }
    return self;
}
+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCFriendListPermanentCell class] forCellReuseIdentifier:RCFriendListPermanentCellIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCFriendListPermanentCell *cell = [tableView dequeueReusableCellWithIdentifier:RCFriendListPermanentCellIdentifier
                                                                      forIndexPath:indexPath];
    cell.labName.text = self.title;
    [cell showPortraitByImage:self.portrait];
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
    if (self.touchBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.touchBlock(vc);
        });
    }
}
@end
