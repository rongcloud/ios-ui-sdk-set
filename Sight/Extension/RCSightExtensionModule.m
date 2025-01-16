//
//  RCSightExtensionModule.m
//  RongSight
//
//  Created by RongCloud on 16/7/2.
//  Copyright © 2016年 Rong Cloud. All rights reserved.
//

#import "RCSightExtensionModule.h"


@implementation RCSightExtensionModule

+ (instancetype)sharedInstance {
    static RCSightExtensionModule *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [[RCSightExtensionModule alloc] init];
        }
    });
    return instance;
}

+ (instancetype)loadRongExtensionModule {
    return [RCSightExtensionModule sharedInstance];
}

- (void)destroyModule {
}


- (BOOL)isAudioHolding {
    return self.isSightPlayerHolding;
}

- (BOOL)isCameraHolding {
    return self.isSightCameraHolding;
}

@end
