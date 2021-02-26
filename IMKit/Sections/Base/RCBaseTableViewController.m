//
//  RCBaseTableViewController.m
//  RongIMKit
//
//  Created by Sin on 2020/6/2.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCBaseTableViewController.h"

@interface RCBaseTableViewController ()

@end

@implementation RCBaseTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self saveCurrentUserInterfaceStyle];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self saveCurrentUserInterfaceStyle];
}

- (void)saveCurrentUserInterfaceStyle {
    if (@available(iOS 13.0, *)) {
        [[NSUserDefaults standardUserDefaults] setObject:@(UITraitCollection.currentTraitCollection.userInterfaceStyle)
                                                  forKey:@"RCCurrentUserInterfaceStyle"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
