//
//  RCSightCollectionView.m
//  RongIMKit
//
//  Created by zhaobingdong on 2017/5/17.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightCollectionView.h"

@implementation RCSightCollectionView

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGRect rect = CGRectMake(0, screenSize.height - 54, self.contentSize.width, 54);
    if (CGRectContainsPoint(rect, point)) {
        return NO;
    }
    return YES;
}

@end
