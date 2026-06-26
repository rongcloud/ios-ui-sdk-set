//
//  RCiFlyKit.m
//  RongiFlyKit
//
//  Created by Sin on 16/11/22.
//  Copyright © 2016年 Sin. All rights reserved.
//

#import "RCiFlyKit.h"
#import "RCiFlyKitExtensionModule.h"

@interface RCiFlyKit ()
@property (nonatomic, copy) NSString *iflyAppKey;
@end

@implementation RCiFlyKit

+ (void)setiFlyAppkey:(NSString *)key {
    [[RCiFlyKitExtensionModule sharedRCiFlyKitExtensionModule] setiFlyAppkey:key];
}

@end
