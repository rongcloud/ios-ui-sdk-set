//
//  RCExtNavigationController.m
//  RongExtensionKit
//
//  Created by 杨雨东 on 2018/5/22.
//  Copyright © 2018 RongCloud. All rights reserved.
//

#import "RCExtNavigationController.h"
#import "RCSemanticContext.h"
@interface RCExtNavigationController ()

@end

@implementation RCExtNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        if ([RCSemanticContext isRTL]) {
            self.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
            self.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}
- (BOOL)shouldAutorotate {
    return NO;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
