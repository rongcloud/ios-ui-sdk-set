//
//  RCMessageModel+Txt.m
//  RongIMKit
//
//  Created by RobinCui on 2022/5/20.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCMessageModel+Txt.h"
#import <objc/runtime.h>
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import <CoreText/CoreText.h>

NSInteger const RCComplexTextSpaceLeft = 12;
NSInteger const RCComplexTextSpaceRight = 12;

@implementation RCMessageModel (Txt)
- (void)setTxt_textSize:(CGSize)txt_textSize {
    NSValue *value = [NSValue valueWithCGSize:txt_textSize];
    objc_setAssociatedObject(self, @selector(txt_textSize), value, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, @selector(txt_textSizeWithMaxWidth:), nil, OBJC_ASSOCIATION_RETAIN);
}

- (CGSize)txt_textSize {
    CGFloat textMaxWidth = [RCMessageCellTool getMessageContentViewMaxWidth] - RCComplexTextSpaceLeft - RCComplexTextSpaceRight;
    return [self txt_textSizeWithMaxWidth:textMaxWidth];
}

- (CGSize)txt_textSizeWithMaxWidth:(CGFloat)maxWidth {
    if (![self.content isKindOfClass:[RCTextMessage class]]) {
        return CGSizeZero;
    }
    if (maxWidth <= 0) {
        return CGSizeZero;
    }
    RCTextMessage *msg = (RCTextMessage *)self.content;
    NSValue *value = objc_getAssociatedObject(self, @selector(txt_textSize));
    NSNumber *cachedWidth = objc_getAssociatedObject(self, @selector(txt_textSizeWithMaxWidth:));
    if (value && cachedWidth && cachedWidth.doubleValue == maxWidth) {
        return [value CGSizeValue];
    } else {
        UIFont *font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
        CGSize size = [self coreText:msg.content
                                font:font
                     constrainedSize:CGSizeMake(maxWidth, 80000)];
        [self setTxt_textSize:size];
        objc_setAssociatedObject(self, @selector(txt_textSizeWithMaxWidth:), @(maxWidth), OBJC_ASSOCIATION_RETAIN);
        return size;
    }
}


- (CGSize)coreText:(NSString *)calcedString font:(UIFont *)font constrainedSize:(CGSize)limitSize {
    NSMutableAttributedString *attibuteStr = [[NSMutableAttributedString alloc] initWithString:calcedString];
    [attibuteStr addAttribute:NSFontAttributeName
                        value:font
                        range:NSMakeRange(0, calcedString.length)];
    CFAttributedStringRef attributedStringRef = (__bridge CFAttributedStringRef)attibuteStr;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attributedStringRef);
    CFRange range = CFRangeMake(0, calcedString.length);
    CFRange fitCFRange = CFRangeMake(0, 0);
    CGSize newSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, range, NULL, limitSize, &fitCFRange);
    if (nil != framesetter) {
        CFRelease(framesetter);
        framesetter = nil;
    }
    return CGSizeMake(ceilf(newSize.width), ceilf(newSize.height));
}
@end
