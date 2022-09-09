//
//  RCMessageModel+Translation.m
//  RongIMKit
//
//  Created by RobinCui on 2022/2/24.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCMessageModel+Translation.h"
#import <objc/runtime.h>
#import "RCMessageCellTool.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"

NSString * const RCTextTranslationMessageCellIdentifier = @"RCTextTranslationMessageCellIdentifier";
NSString * const RCVoiceTranslationMessageCellIdentifier = @"RCVoiceTranslationMessageCellIdentifier";
NSString *const RCTextTranslatingMessageCellIdentifier = @"RCTextTranslatingMessageCellIdentifier";
NSString *const RCVoiceTranslatingMessageCellIdentifier = @"RCVoiceTranslatingMessageCellIdentifier";
NSInteger const RCTranslationTextSpaceLeft = 12;
NSInteger const RCTranslationTextSpaceRight = 12;
NSInteger const RCTranslationTextSpaceTop = 9.5;
NSInteger const RCTranslationTextSpaceBottom = 9.5;
NSInteger const RCTranslationTextSpaceOffset = 6;
NSInteger const RCTranslationContentTranslatingSize = 40;

@implementation RCMessageModel (Translation)

- (void)setTranslationString:(NSString *)translationString {
    objc_setAssociatedObject(self, @selector(translationString), translationString, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self setIsTranslated:YES];
}

- (NSString *)translationString {
    return objc_getAssociatedObject(self, @selector(translationString));
}

- (void)setVoiceString:(NSString *)voiceString {
    objc_setAssociatedObject(self, @selector(voiceString), voiceString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)voiceString {
    return objc_getAssociatedObject(self, @selector(voiceString));
}

- (BOOL)isTranslated {
    NSNumber *ret = objc_getAssociatedObject(self, @selector(isTranslated));
    return  [ret boolValue];
}

- (void)setIsTranslated:(BOOL)isTranslated {
    objc_setAssociatedObject(self, @selector(isTranslated), @(isTranslated), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)translating {
    NSNumber *ret = objc_getAssociatedObject(self, @selector(translating));
    return  [ret boolValue];
}

- (void)setTranslating:(BOOL)translating {
    objc_setAssociatedObject(self, @selector(translating), @(translating), OBJC_ASSOCIATION_RETAIN);
}


- (void)setTranslationCategory:(RCTranslationCategory)translationCategory {
    objc_setAssociatedObject(self, @selector(translationCategory), @(translationCategory), OBJC_ASSOCIATION_RETAIN);
}

- (RCTranslationCategory)translationCategory {
    NSNumber *ret = objc_getAssociatedObject(self, @selector(translationCategory));
    return  [ret integerValue];
}


- (void)setTranslationSize:(CGSize)translationSize {
    NSValue *value = [NSValue valueWithCGSize:translationSize];
    objc_setAssociatedObject(self, @selector(translationSize), value, OBJC_ASSOCIATION_RETAIN);
}

- (CGSize)translationSize {
    NSValue *value = objc_getAssociatedObject(self, @selector(translationSize));
    if (value) {
        return [value CGSizeValue];
    } else {
        CGSize size = [self getTranslationTextSizeBy:self.translationString];
        [self setTranslationSize:size];
        return size;
    }
}

- (void)setVoiceStringSize:(CGSize)voiceStringSize {
    NSValue *value = [NSValue valueWithCGSize:voiceStringSize];
    objc_setAssociatedObject(self, @selector(voiceStringSize), value, OBJC_ASSOCIATION_RETAIN);
}

- (CGSize)voiceStringSize {
    NSValue *value = objc_getAssociatedObject(self, @selector(voiceStringSize));
    if (value) {
        return [value CGSizeValue];
    } else {
        CGSize size = [self getTranslationTextSizeBy:self.voiceString];
        [self setVoiceStringSize:size];
        return size;
    }
}
- (void)setTranslatingSize:(CGSize)translatingSize {
    NSValue *value = [NSValue valueWithCGSize:translatingSize];
    objc_setAssociatedObject(self, @selector(translatingSize), value, OBJC_ASSOCIATION_RETAIN);
}

- (CGSize)translatingSize {
    NSValue *value = objc_getAssociatedObject(self, @selector(translatingSize));
    if (value) {
        return [value CGSizeValue];
    } else {
        CGFloat height = RCTranslationTextSpaceBottom + RCTranslationTextSpaceOffset + self.cellSize.height + RCTranslationContentTranslatingSize;
        
        CGSize size = CGSizeMake(self.cellSize.width,height);
        [self setTranslatingSize:size];
        return size;
    }
}


- (void)setFinalSize:(CGSize)finalSize {
    NSValue *value = [NSValue valueWithCGSize:finalSize];
    objc_setAssociatedObject(self, @selector(finalSize), value, OBJC_ASSOCIATION_RETAIN);
}

- (CGSize)finalSize {
    NSValue *value = objc_getAssociatedObject(self, @selector(finalSize));
    if (value) {
        return [value CGSizeValue];
    } else {
        CGFloat height = RCTranslationTextSpaceBottom + RCTranslationTextSpaceOffset + self.cellSize.height + self.translationSize.height;
        if (self.translationCategory == RCTranslationCategorySpeech) {
            height += self.voiceStringSize.height;
        }
        CGSize size = CGSizeMake(self.cellSize.width,height);
        [self setFinalSize:size];
        return size;
    }
}

- (CGSize)getTranslationTextSizeBy:(NSString *)text {
    CGSize textTranslationSize = CGSizeZero;
    CGFloat textMaxWidth = [RCMessageCellTool getMessageContentViewMaxWidth] - RCTranslationTextSpaceLeft - RCTranslationTextSpaceRight;
    if (text) {
        textTranslationSize = [RCKitUtility getTextDrawingSize:text
                                                          font:[[RCKitConfig defaultConfig].font fontOfSecondLevel]
                                               constrainedSize:CGSizeMake(textMaxWidth, 80000)];
    }
    if (textTranslationSize.width > textMaxWidth) {
        textTranslationSize.width = textMaxWidth;
    }
    textTranslationSize = CGSizeMake(ceilf(textTranslationSize.width), ceilf(textTranslationSize.height+5));
    return textTranslationSize;
}

- (NSString *)translationCellIdentifier {
    if (self.translationCategory == RCTranslationCategoryText) {
        return self.translating ? RCTextTranslatingMessageCellIdentifier : RCTextTranslationMessageCellIdentifier;
    } else {
        return self.translating ? RCVoiceTranslatingMessageCellIdentifier : RCVoiceTranslationMessageCellIdentifier;
    }
}
@end
