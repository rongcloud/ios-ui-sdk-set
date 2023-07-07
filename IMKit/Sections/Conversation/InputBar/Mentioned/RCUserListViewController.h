//
//  RCUserListViewController.h
//  RongExtensionKit
//
//  Created by 杜立召 on 16/7/14.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>
#import "RCBaseViewController.h"

@protocol RCSelectingUserDataSource;

@interface RCUserListViewController : RCBaseViewController

@property (nonatomic, copy) void (^selectedBlock)(RCUserInfo *selectedUserInfo);
@property (nonatomic, copy) void (^cancelBlock)(void);

@property (nonatomic, strong) NSString *navigationTitle;

@property (nonatomic, weak) id<RCSelectingUserDataSource> dataSource;
@property (nonatomic, assign) int maxSelectedUserNumber;

@end

@protocol RCSelectingUserDataSource <NSObject>

- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion;

- (RCUserInfo *)getSelectingUserInfo:(NSString *)userId;

@end
