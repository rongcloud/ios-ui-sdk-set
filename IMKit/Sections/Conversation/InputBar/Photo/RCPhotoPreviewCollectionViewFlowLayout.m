//
//  RCPhotoPreviewCollectionViewFlowLayout.m
//  RongIMKit
//
//  Created by 孙浩 on 2020/9/4.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCPhotoPreviewCollectionViewFlowLayout.h"
#import "RCKitUtility.h"

@implementation RCPhotoPreviewCollectionViewFlowLayout

- (BOOL)flipsHorizontallyInOppositeLayoutDirection {
    return YES;
}

- (UIUserInterfaceLayoutDirection)effectiveUserInterfaceLayoutDirection {

    if ([RCKitUtility isRTL]) {
        return UIUserInterfaceLayoutDirectionRightToLeft;
    }
    return UIUserInterfaceLayoutDirectionLeftToRight;
}

@end
