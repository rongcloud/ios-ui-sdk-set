//  代码地址: https://github.com/CoderMJLee/RCMJRefresh
//  代码地址:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  UIScrollView+Extension.m
//  RCMJRefreshExample
//
//  Created by MJ Lee on 14-5-28.
//  Copyright (c) 2014年 小码哥. All rights reserved.
//

#import "UIScrollView+RCMJExtension.h"
#import <objc/runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"

static BOOL respondsToAdjustedContentInset_;

@implementation UIScrollView (RCMJExtension)

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        respondsToAdjustedContentInset_ = [self instancesRespondToSelector:@selector(adjustedContentInset)];
    });
}

- (UIEdgeInsets)rcmj_inset {
#ifdef __IPHONE_11_0
    if (respondsToAdjustedContentInset_) {
        return self.adjustedContentInset;
    }
#endif
    return self.contentInset;
}

- (void)setRcmj_insetT:(CGFloat)mj_insetT {
    UIEdgeInsets inset = self.contentInset;
    inset.top = mj_insetT;
#ifdef __IPHONE_11_0
    if (respondsToAdjustedContentInset_) {
        inset.top -= (self.adjustedContentInset.top - self.contentInset.top);
    }
#endif
    self.contentInset = inset;
}

- (CGFloat)rcmj_insetT {
    return self.rcmj_inset.top;
}

- (void)setRcmj_insetB:(CGFloat)mj_insetB {
    UIEdgeInsets inset = self.contentInset;
    inset.bottom = mj_insetB;
#ifdef __IPHONE_11_0
    if (respondsToAdjustedContentInset_) {
        inset.bottom -= (self.adjustedContentInset.bottom - self.contentInset.bottom);
    }
#endif
    self.contentInset = inset;
}

- (CGFloat)rcmj_insetB {
    return self.rcmj_inset.bottom;
}

- (void)setRcmj_insetL:(CGFloat)mj_insetL {
    UIEdgeInsets inset = self.contentInset;
    inset.left = mj_insetL;
#ifdef __IPHONE_11_0
    if (respondsToAdjustedContentInset_) {
        inset.left -= (self.adjustedContentInset.left - self.contentInset.left);
    }
#endif
    self.contentInset = inset;
}

- (CGFloat)rcmj_insetL {
    return self.rcmj_inset.left;
}

- (void)setRcmj_insetR:(CGFloat)mj_insetR {
    UIEdgeInsets inset = self.contentInset;
    inset.right = mj_insetR;
#ifdef __IPHONE_11_0
    if (respondsToAdjustedContentInset_) {
        inset.right -= (self.adjustedContentInset.right - self.contentInset.right);
    }
#endif
    self.contentInset = inset;
}

- (CGFloat)rcmj_insetR {
    return self.rcmj_inset.right;
}

- (void)setRcmj_offsetX:(CGFloat)mj_offsetX {
    CGPoint offset = self.contentOffset;
    offset.x = mj_offsetX;
    self.contentOffset = offset;
}

- (CGFloat)rcmj_offsetX {
    return self.contentOffset.x;
}

- (void)setRcmj_offsetY:(CGFloat)mj_offsetY {
    CGPoint offset = self.contentOffset;
    offset.y = mj_offsetY;
    self.contentOffset = offset;
}

- (CGFloat)rcmj_offsetY {
    return self.contentOffset.y;
}

- (void)setRcmj_contentW:(CGFloat)mj_contentW {
    CGSize size = self.contentSize;
    size.width = mj_contentW;
    self.contentSize = size;
}

- (CGFloat)rcmj_contentW {
    return self.contentSize.width;
}

- (void)setRcmj_contentH:(CGFloat)mj_contentH {
    CGSize size = self.contentSize;
    size.height = mj_contentH;
    self.contentSize = size;
}

- (CGFloat)rcmj_contentH {
    return self.contentSize.height;
}
@end
#pragma clang diagnostic pop
