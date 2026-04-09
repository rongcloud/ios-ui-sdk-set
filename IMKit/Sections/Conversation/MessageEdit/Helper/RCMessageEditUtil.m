//
//  RCMessageEditUtil.m
//  RongIMKit
//
//  Created by Lang on 2025/8/10.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageEditUtil.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@implementation RCMessageEditUtil

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

+ (BOOL)isEditTimeValid:(long long)sentTime {
    if (sentTime <= 0) {
        return NO;
    }
    RCAppSettings *appSettings = [[RCCoreClient sharedCoreClient] getAppSettings];
    NSTimeInterval appSettingsTime = appSettings.messageModifiableMinutes * 60 * 1000;
    if (appSettingsTime <= 0) {
        return NO;
    }
    // 获取当前手机与服务器的时间差
    NSTimeInterval deltaTime = [[RCCoreClient sharedCoreClient] getDeltaTime];
    NSTimeInterval currentTimestamp = ([[NSDate date] timeIntervalSince1970] * 1000) - deltaTime;
    // 时间间隔， 当前准确时间 - 消息发送时间
    NSTimeInterval timeInterval = currentTimestamp - sentTime;
    // 如果时间差大于 appSettingsTime，则不能编辑
    if (timeInterval > appSettingsTime) {
        return NO;
    }
    return YES;
}

@end
