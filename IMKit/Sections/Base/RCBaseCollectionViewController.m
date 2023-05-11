//
//  RCBaseCollectionViewController.m
//  RongIMKit
//
//  Created by Sin on 2020/6/2.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCBaseCollectionViewController.h"
#import "RCKitUtility.h"
@interface RCBaseCollectionViewController ()

@end

@implementation RCBaseCollectionViewController

static NSString *const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateRTLUI];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
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

- (void)updateRTLUI{
    if ([RCKitUtility isRTL]) {
        self.collectionView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    }else{
        self.collectionView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
}
@end
