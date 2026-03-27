//
//  RCTipLabel.m
//  iOS-IMKit
//
//  Created by Gang Li on 10/27/14.
//  Copyright (c) 2014 RongCloud. All rights reserved.
//

#import "RCTipLabel.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@implementation RCTipLabel

+ (instancetype)greyTipLabel {
    RCTipLabel *tip = [[RCTipLabel alloc] init];
    if (tip) {
        tip.marginInsets = UIEdgeInsetsMake(5.f, 5.f, 5.f, 5.f);
        tip.textColor = [UIColor whiteColor];
        tip.numberOfLines = 0;
        tip.lineBreakMode = NSLineBreakByTruncatingTail;
        tip.textAlignment = NSTextAlignmentCenter;
        tip.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        tip.layer.masksToBounds = YES;
        tip.layer.cornerRadius = 4.f;
        tip.backgroundColor = HEXCOLOR(0xc9c9c9);
        
    }
    return tip;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.marginInsets)];
}

- (void)setMarginInsets:(UIEdgeInsets)marginInsets {
    _marginInsets = marginInsets;
    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width += self.marginInsets.left + self.marginInsets.right;
    size.height += self.marginInsets.top + self.marginInsets.bottom;
    return size;
}

@end
