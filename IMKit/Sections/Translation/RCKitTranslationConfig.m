//
//  RCKitTranslationConfig.m
//  RongIMKit
//
//  Created by RobinCui on 2022/2/28.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCKitTranslationConfig.h"

@interface RCKitTranslationConfig()
@property (nonatomic, copy, readwrite) NSString *srcLanguage;
@property (nonatomic, copy, readwrite) NSString *targetLanguage;
@end

@implementation RCKitTranslationConfig
- (instancetype)initWithSrcLanguage:(NSString *)srcLanguage
                     targetLanguage:(NSString *)targetLanguage {
    if (self = [super init]) {
        if (![srcLanguage isKindOfClass:[NSString class]]) {
            NSLog(@"RCKitTranslationConfig: srcLanguage invalid");
        }
        self.srcLanguage = srcLanguage;
        
        if (![srcLanguage isKindOfClass:[targetLanguage class]]) {
            NSLog(@"RCKitTranslationConfig: targetLanguage invalid");
        }
        self.targetLanguage = targetLanguage;
    }
    return self;
}

@end
