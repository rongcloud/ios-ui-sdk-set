//
//  RCMessageModel+Translation.h
//  RongIMKit
//
//  Created by RobinCui on 2022/2/24.
//  Copyright © 2022 RongCloud. All rights reserved.
//


#import "RCMessageModel.h"
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RCTranslationCategory) {
    RCTranslationCategoryText,
    RCTranslationCategorySpeech
};

extern NSString *const RCTextTranslationMessageCellIdentifier;
extern NSString *const RCVoiceTranslationMessageCellIdentifier;
extern NSString *const RCTextTranslatingMessageCellIdentifier;
extern NSString *const RCVoiceTranslatingMessageCellIdentifier;
extern NSInteger const RCTranslationTextSpaceOffset;
extern NSInteger const RCTranslationTextSpaceBottom;
extern NSInteger const RCTranslationTextSpaceLeft;
extern NSInteger const RCTranslationTextSpaceRight;
extern NSInteger const RCTranslationTextSpaceTop;
extern NSInteger const RCTranslationContentTranslatingSize;

@interface RCMessageModel (Translation)

/// 翻译文本
@property (nonatomic, copy) NSString *translationString;

/// 音频中提取的文本
@property (nonatomic, copy) NSString *voiceString;

/// 是否翻译过
@property (nonatomic, assign, readonly) BOOL isTranslated;

/// 翻译类别
@property (nonatomic, assign) RCTranslationCategory translationCategory;

/// 翻译文本大小
@property (nonatomic, assign) CGSize translationSize;

/// 声音转文本大小
@property (nonatomic, assign) CGSize voiceStringSize;

/// 最终大小
@property (nonatomic, assign) CGSize finalSize;

//正在翻译
@property (nonatomic, assign) BOOL translating;

/// 翻译中的size
@property (nonatomic, assign) CGSize translatingSize;

- (NSString *)translationCellIdentifier;
@end

NS_ASSUME_NONNULL_END
