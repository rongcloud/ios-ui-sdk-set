//
//  UIColor+RCIMHexColor.m
//  RongIMKit
//
//  Created by RobinCui on 2025/9/17.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "UIColor+RCIMHexColor.h"
@interface NSString (RCIMHexColorPrivate)
- (NSUInteger)rcimp_hexValue;
@end

@implementation NSString (RCIMHexColorPrivate)
- (NSUInteger)rcimp_hexValue {
    NSUInteger result = 0;
    sscanf([self UTF8String], "%lx", &result);
    return result;
}
@end

@implementation UIColor (RCIMHexColor)
+ (UIColor *)rcim_colorWithHex:(NSString *)hex {
    if ([hex isEqualToString:@""]) {
        return [UIColor clearColor];
    }

    // Remove `#` and `0x`
    if ([hex hasPrefix:@"#"]) {
        hex = [hex substringFromIndex:1];
    } else if ([hex hasPrefix:@"0x"]) {
        hex = [hex substringFromIndex:2];
    }

    // Invalid if not 3, 6, or 8 characters
    NSUInteger length = [hex length];
    if (length != 3 && length != 6 && length != 8) {
        return nil;
    }

    // Make the string 8 characters long for easier parsing
    if (length == 3) {
        NSString *r = [hex substringWithRange:NSMakeRange(0, 1)];
        NSString *g = [hex substringWithRange:NSMakeRange(1, 1)];
        NSString *b = [hex substringWithRange:NSMakeRange(2, 1)];
        hex = [NSString stringWithFormat:@"%@%@%@%@%@%@ff", r, r, g, g, b, b];
    } else if (length == 6) {
        hex = [hex stringByAppendingString:@"ff"];
    }

    CGFloat red = [[hex substringWithRange:NSMakeRange(0, 2)] rcimp_hexValue] / 255.0f;
    CGFloat green = [[hex substringWithRange:NSMakeRange(2, 2)] rcimp_hexValue] / 255.0f;
    CGFloat blue = [[hex substringWithRange:NSMakeRange(4, 2)] rcimp_hexValue] / 255.0f;
    CGFloat alpha = [[hex substringWithRange:NSMakeRange(6, 2)] rcimp_hexValue] / 255.0f;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)rcim_colorWithHex:(NSString *)hex alpha:(CGFloat)alpha {
    if ([hex isEqualToString:@""]) {
        return [UIColor clearColor];
    }

    // Remove `#` and `0x`
    if ([hex hasPrefix:@"#"]) {
        hex = [hex substringFromIndex:1];
    } else if ([hex hasPrefix:@"0x"]) {
        hex = [hex substringFromIndex:2];
    }

    // Invalid if not 3, 6, or 8 characters
    NSUInteger length = [hex length];
    if (length != 3 && length != 6 && length != 8) {
        return nil;
    }

    // Make the string 8 characters long for easier parsing
    if (length == 3) {
        NSString *r = [hex substringWithRange:NSMakeRange(0, 1)];
        NSString *g = [hex substringWithRange:NSMakeRange(1, 1)];
        NSString *b = [hex substringWithRange:NSMakeRange(2, 1)];
        hex = [NSString stringWithFormat:@"%@%@%@%@%@%@ff", r, r, g, g, b, b];
    }

    CGFloat red = [[hex substringWithRange:NSMakeRange(0, 2)] rcimp_hexValue] / 255.0f;
    CGFloat green = [[hex substringWithRange:NSMakeRange(2, 2)] rcimp_hexValue] / 255.0f;
    CGFloat blue = [[hex substringWithRange:NSMakeRange(4, 2)] rcimp_hexValue] / 255.0f;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
