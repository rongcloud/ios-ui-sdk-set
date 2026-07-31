//
//  RCTextPreviewView+Edit.h
//  RongIMKit
//
//  Created by Lang on 2025/8/11.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCTextPreviewView.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCTextPreviewView (Edit)

+ (void)edit_showText:(NSString *)text messageId:(long)messageId edited:(BOOL)edited delegate:(id<RCTextPreviewViewDelegate>)delegate;

- (NSString *)edit_copyText;

@end

NS_ASSUME_NONNULL_END
