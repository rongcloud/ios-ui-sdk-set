//  代码地址: https://github.com/CoderMJLee/RCMJRefresh
//  代码地址:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  UIView+Extension.m
//  RCMJRefreshExample
//
//  Created by MJ Lee on 14-5-28.
//  Copyright (c) 2014年 小码哥. All rights reserved.
//

#import "UIView+RCMJExtension.h"

@implementation UIView (RCMJExtension)
- (void)setRcmj_x:(CGFloat)mj_x {
    CGRect frame = self.frame;
    frame.origin.x = mj_x;
    self.frame = frame;
}

- (CGFloat)rcmj_x {
    return self.frame.origin.x;
}

- (void)setRcmj_y:(CGFloat)mj_y {
    CGRect frame = self.frame;
    frame.origin.y = mj_y;
    self.frame = frame;
}

- (CGFloat)rcmj_y {
    return self.frame.origin.y;
}

- (void)setRcmj_w:(CGFloat)mj_w {
    CGRect frame = self.frame;
    frame.size.width = mj_w;
    self.frame = frame;
}

- (CGFloat)rcmj_w {
    return self.frame.size.width;
}

- (void)setRcmj_h:(CGFloat)mj_h {
    CGRect frame = self.frame;
    frame.size.height = mj_h;
    self.frame = frame;
}

- (CGFloat)rcmj_h {
    return self.frame.size.height;
}

- (void)setRcmj_size:(CGSize)mj_size {
    CGRect frame = self.frame;
    frame.size = mj_size;
    self.frame = frame;
}

- (CGSize)rcmj_size {
    return self.frame.size;
}

- (void)setRcmj_origin:(CGPoint)mj_origin {
    CGRect frame = self.frame;
    frame.origin = mj_origin;
    self.frame = frame;
}

- (CGPoint)rcmj_origin {
    return self.frame.origin;
}
@end
