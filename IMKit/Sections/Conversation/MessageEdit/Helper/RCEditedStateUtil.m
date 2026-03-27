//
//  RCEditedStateUtil.m
//  RongIMKit
//
//  Created by Lang on 2025/8/10.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCEditedStateUtil.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@implementation RCEditedStateUtil

+ (NSString *)displayTextForOriginalText:(NSString *)originalText isEdited:(BOOL)isEdited {
    if (!originalText) {
        originalText = @"";
    }
    
    if (isEdited) {
        return [NSString stringWithFormat:@"%@%@", originalText, [self editedSuffix]];
    }
    return originalText;
}

+ (UIColor *)editedTextColor {
    return RCKitConfigCenter.message.editedTextColor;
}

+ (NSString *)editedSuffix {
    return [NSString stringWithFormat:@"（%@）",RCLocalizedString(@"MessageEdited")];
}

+ (CGSize)sizeForText:(NSString *)originalText
             isEdited:(BOOL)isEdited
                 font:(UIFont *)font
      constrainedSize:(CGSize)constrainedSize {
    
    NSString *displayText = [self displayTextForOriginalText:originalText isEdited:isEdited];
    
    CGSize textSize = [RCKitUtility getTextDrawingSize:displayText
                                                  font:font
                                       constrainedSize:constrainedSize];
    
    return CGSizeMake(ceilf(textSize.width), ceilf(textSize.height));
}

@end
