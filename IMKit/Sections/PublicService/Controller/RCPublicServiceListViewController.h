//
//  RCPublicServiceListViewController.h
//  RongIMKit
//
//  Created by litao on 15/4/20.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseTableViewController.h"
/*!
 * \~chinese
 已关注公众服务账号列表的展示ViewController
 
 * \~english
 ViewController of Followed public service account list 
 */
@interface RCPublicServiceListViewController : RCBaseTableViewController

@property (nonatomic, strong) NSMutableDictionary *allFriends;

@property (nonatomic, strong) NSArray *allKeys;

@end
