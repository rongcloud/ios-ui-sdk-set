//
//  RCCustomerServiceGroupListController.h
//  RongIMKit
//
//  Created by 张改红 on 16/7/19.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseTableViewController.h"
@class RCCustomerServiceGroupItem;
@interface RCCustomerServiceGroupListController : RCBaseTableViewController
@property (nonatomic, strong) NSArray<RCCustomerServiceGroupItem *> *groupList;
@property (nonatomic, copy) void (^selectGroupBlock)(NSString *groupid);
@end
