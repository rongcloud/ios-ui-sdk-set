//
//  RongSight.h
//  RongSight
//
//  Created by zhaobingdong on 2017/12/5.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for RongSight.
FOUNDATION_EXPORT double RongSightVersionNumber;

//! Project version string for RongSight.
FOUNDATION_EXPORT const unsigned char RongSightVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import
// <RongSight/PublicHeader.h>

#if __has_include(<RongSight/RCSightViewController.h>)

#import <RongSight/RCSightViewController.h>
#import <RongSight/RCSightPlayerController.h>
#import <RongSight/RCSightPlayerOverlay.h>
#import <RongSight/RongSightAdaptiveHeader.h>

#else

#import "RCSightViewController.h"
#import "RCSightPlayerController.h"
#import "RCSightPlayerOverlay.h"
#import "RongSightAdaptiveHeader.h"

#endif
