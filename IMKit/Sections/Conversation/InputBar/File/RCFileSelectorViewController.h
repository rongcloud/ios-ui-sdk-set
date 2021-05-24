//
//  RCFileSelectorViewController.h
//  RongExtensionKit
//
//  Created by Jue on 16/4/25.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseTableViewController.h"

@protocol RCFileSelectorViewControllerDelegate <NSObject>
- (void)fileDidSelect:(NSArray *)filePathList;
@optional
- (BOOL)canBeSelectedAtPath:(NSString *)path;
@end

@interface RCFileSelectorViewController : RCBaseTableViewController
@property (nonatomic, weak) id<RCFileSelectorViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isSubDirectory;

- (instancetype)initWithRootPath:(NSString *)rootPath;
@end
