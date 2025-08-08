//
//  RCAttributedLabel+EditedState.m
//  RongIMKit
//
//  Created by Assistant on 2024/01/XX.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCAttributedLabel+EditedState.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

@implementation RCAttributedLabel (EditedState)

#pragma mark - 已编辑状态支持

- (void)setTextWithEditedState:(NSString *)text isEdited:(BOOL)isEdited {
    if (!text || text.length == 0) {
        [self setText:@"" dataDetectorEnabled:YES];
        return;
    }
    
    if (isEdited) {
        // 生成包含"已编辑"的显示文本
        NSString *displayText = [RCEditedStateUtil displayTextForOriginalText:text isEdited:YES];
        
        // 使用正常的 setText 流程，让电话号码检测正常工作
        [self setText:displayText dataDetectorEnabled:YES];
        
        // 异步应用"已编辑"部分的灰色样式
        [self applyEditedTextStyleWithOriginalTextLength:text.length];
    } else {
        // 未编辑：直接设置原文本
        [self setText:text dataDetectorEnabled:YES];
    }
}

- (void)applyEditedTextStyleWithOriginalTextLength:(NSUInteger)originalTextLength {
    // 等待电话号码检测完成后再修改样式
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableAttributedString *currentAttributedText = [self.attributedText mutableCopy];
        
        if (currentAttributedText && currentAttributedText.length > 0) {
            NSString *fullText = currentAttributedText.string;
            NSString *editedSuffix = [RCEditedStateUtil editedSuffix];
            NSRange editedRange = [fullText rangeOfString:editedSuffix];
            
            if (editedRange.location != NSNotFound) {
                // 为"已编辑"部分设置灰色
                UIColor *editedColor = [RCEditedStateUtil editedTextColor];
                [currentAttributedText addAttribute:NSForegroundColorAttributeName 
                                               value:editedColor 
                                               range:editedRange];
                
                // 直接修改 attributedText（避免触发重新检测）
                [self setValue:currentAttributedText forKey:@"attributedText"];
            }
        }
    });
}

@end

#pragma mark - 工具方法实现

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
    return [RCKitUtility generateDynamicColor:HEXCOLOR(0x999999) 
                                    darkColor:RCMASKCOLOR(0xffffff, 0.5)];
}

+ (NSString *)editedSuffix {
    return @"（已编辑）";
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