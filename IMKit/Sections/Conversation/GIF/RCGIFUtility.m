//
//  RCGIFUtility.m
//  RongIMKit
//
//  Created by liyan on 2019/7/22.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCGIFUtility.h"
#import "RCIM.h"

#define MAXHEIGHT 120.f
#define MINHEIGHT 79.f

@implementation RCGIFUtility
#pragma mark - Public Methods
+ (CGSize)calculatecollectionViewHeight:(RCMessageModel *)model {
    RCGIFMessage *gifMessage = (RCGIFMessage *)model.content;
    CGFloat gifHeight = gifMessage.height / 2;
    CGFloat gifWidth = gifMessage.width / 2;
    if (gifHeight <= 1) {
        gifHeight = 1;
    }
    if (gifWidth <= 1) {
        gifWidth = 1;
    }
    if (gifHeight <= MAXHEIGHT && gifWidth <= MAXHEIGHT) {
        float scale = gifWidth / gifHeight;
        gifHeight = [self caculateHeight:gifHeight];
        gifWidth = gifHeight * scale;
        return CGSizeMake(gifWidth, gifHeight);
    }
    if (gifHeight > MAXHEIGHT && gifWidth <= MAXHEIGHT) {
        CGFloat height = MAXHEIGHT;
        CGFloat width = MAXHEIGHT * gifWidth / gifHeight;
        height = [self caculateHeight:height];
        return CGSizeMake(width, height);
    }
    if (gifHeight <= MAXHEIGHT && gifWidth > MAXHEIGHT) {
        CGFloat width = MAXHEIGHT;
        CGFloat height = MAXHEIGHT * gifHeight / gifWidth;
        height = [self caculateHeight:height];
        return CGSizeMake(width, height);
    }
    if (gifHeight > MAXHEIGHT && gifWidth > MAXHEIGHT) {
        if (gifHeight > gifWidth) {
            CGFloat height = MAXHEIGHT;
            CGFloat width = MAXHEIGHT * gifWidth / gifHeight;
            height = [self caculateHeight:height];
            return CGSizeMake(width, height);
        } else {
            CGFloat width = MAXHEIGHT;
            CGFloat height = MAXHEIGHT * gifHeight / gifWidth;
            height = [self caculateHeight:height];
            return CGSizeMake(width, height);
        }
    }
    return CGSizeMake(MINHEIGHT, [self caculateHeight:0]);
}

#pragma mark - Private Methods

+ (CGFloat)caculateHeight:(CGFloat)height {
    CGFloat currentHeight = height;
    if (height < MINHEIGHT) {
        currentHeight = MINHEIGHT;
    }
    return currentHeight;
}

@end
