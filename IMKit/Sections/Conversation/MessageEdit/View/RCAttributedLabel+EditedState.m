//
//  RCAttributedLabel+EditedState.m
//  RongIMKit
//
//  Created by RongCloud on 2024/01/XX.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCAttributedLabel+EditedState.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCEditedStateUtil.h"

@interface RCAttributedLabel ()

@property (nonatomic, assign) NSRange rc_editedSuffixRange;

@end

@implementation RCAttributedLabel (EditedState)

#pragma mark - 已编辑状态支持

- (void)edit_setTextWithEditedState:(NSString *)text isEdited:(BOOL)isEdited {
    self.rc_editedSuffixRange = NSMakeRange(NSNotFound, 0);
    if (!text || text.length == 0) {
        [self setText:@"" dataDetectorEnabled:YES];
        return;
    }
    
    if (isEdited) {
        // 生成包含"已编辑"的显示文本
        NSString *displayText = [RCEditedStateUtil displayTextForOriginalText:text isEdited:YES];
        
        NSRange suffixRange = NSMakeRange(text.length, [RCEditedStateUtil editedSuffix].length);
        if (NSMaxRange(suffixRange) <= displayText.length) {
            self.rc_editedSuffixRange = suffixRange;
        }
        [self setText:displayText dataDetectorEnabled:YES];
    } else {
        // 未编辑：直接设置原文本
        [self setText:text dataDetectorEnabled:YES];
    }
}

@end
