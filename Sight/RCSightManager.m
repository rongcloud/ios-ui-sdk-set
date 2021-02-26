//
//  RCSightManager.m
//  RongSight
//
//  Created by Jue on 2018/11/15.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCSightManager.h"

@implementation RCSightManager

+ (id)createSightViewControllerWithCaptureMode:(NSUInteger)mode {
    RCSightViewController *sightViewController = [[RCSightViewController alloc] initWithCaptureMode:mode];
    return sightViewController;
}

+ (id)createSightPlayerControllerWithURL:(NSURL *)assetURL autoPlay:(BOOL)isaut {
    RCSightPlayerController *sightPlayerController =
        [[RCSightPlayerController alloc] initWithURL:assetURL autoPlay:isaut];
    return sightPlayerController;
}

@end
