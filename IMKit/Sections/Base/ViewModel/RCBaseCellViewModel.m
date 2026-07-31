//
//  RCBaseCellViewModel.m
//  Pods-RCUserProfile_Example
//
//  Created by RobinCui on 2024/8/15.
//

#import "RCBaseCellViewModel.h"
NSInteger const RCUserManagementCellHeight = 54;

@implementation RCBaseCellViewModel
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCUserManagementCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
    
}
@end
