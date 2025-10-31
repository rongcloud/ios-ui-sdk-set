//
//  RCInputStateManager.m
//  RongIMKit
//
//  Created by RongCloud on 2025/1/16.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCInputStateManager.h"
#import "RCMentionedStringRangeInfo.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

@interface RCInputStateManager ()

/// 关联的文本输入框
@property (nonatomic, weak) UITextView *textView;

/// @ 信息列表
@property (nonatomic, strong) NSMutableArray<RCMentionedStringRangeInfo *> *mentionedRangeInfoList;

@end

@implementation RCInputStateManager

#pragma mark - 初始化

- (instancetype)initWithTextView:(UITextView *)textView
                        delegate:(id<RCInputStateManagerDelegate>)delegate {
    self = [super init];
    if (self) {
        _textView = textView;
        _delegate = delegate;
        _isMentionedEnabled = YES;
        _mentionedRangeInfoList = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark -

- (BOOL)handleTextChange:(NSString *)text inRange:(NSRange)range {
    if (!self.isMentionedEnabled || !self.textView) {
        return YES;
    }
    
    BOOL shouldUseDefaultChangeText = YES;
    
    // 记录变化的范围
    NSInteger changedLocation = 0;
    NSInteger changedLength = 0;
    
    // 当长度是0 说明是删除字符
    if (text.length == 0) {
        for (RCMentionedStringRangeInfo *mentionedInfo in [self.mentionedRangeInfoList copy]) {
            NSRange mentionedRange = mentionedInfo.range;
            
            // 如果删除的光标在'@'信息的最后，删除这个'@'信息
            if (range.length == 1 && (mentionedRange.location + mentionedRange.length == range.location + 1)) {
                // 安全检查：只有在删除范围有效时才执行整个删除用户的逻辑
                if ([self isSafeToDeleteRange:mentionedRange fromTextStorage:self.textView.textStorage]) {
                    shouldUseDefaultChangeText = NO;
                    
                    [self.textView.textStorage deleteCharactersInRange:mentionedRange];
                    
                    // 修改 textStorage 不会触发 textViewDidChange, 需要手动调用相关代理
                    [self notifyTextViewDidChange];
                    
                    range.location = range.location - mentionedRange.length + 1;
                    range.length = 0;
                    self.textView.selectedRange = NSMakeRange(mentionedRange.location, 0);
                    
                    changedLocation = mentionedInfo.range.location;
                    changedLength = -(NSInteger)mentionedInfo.range.length;
                    
                    [self.mentionedRangeInfoList removeObject:mentionedInfo];
                    break;
                }
            } else if (mentionedRange.location <= range.location &&
                       range.location < mentionedRange.location + mentionedRange.length) {
                [self.mentionedRangeInfoList removeObject:mentionedInfo];
                // 不能break，否则整块删除会遗漏
            }
        }
        
        if (changedLength == 0) {
            // 如果删除的字符不在'@'信息字符中，记录变化的位置和长度
            changedLocation = range.location + 1;
            changedLength = -(NSInteger)range.length;
        }
    } else {
        if ([text isEqualToString:@"@"]) {
            if ([self shouldTriggerMentionedChoose:range]) {
                __weak typeof(self) weakSelf = self;
                [self.delegate inputStateManager:self
                                showUserSelector:^(RCUserInfo *selectedUser) {
                                    [weakSelf insertMentionedUser:selectedUser symbolRequest:NO];
                                }
                                          cancel:^{
                                              // 取消选择，无需处理
                                          }];
            }
        }
        
        // 输入内容变化，遍历所有'@'信息，如果输入的字符起始位置在'@'信息中，移除这个'@'信息
        // 否则根据变化情况更新'@'信息中的range
        for (RCMentionedStringRangeInfo *mentionedInfo in [self.mentionedRangeInfoList copy]) {
            NSRange strRange = mentionedInfo.range;
            if ((range.location > strRange.location) && (range.location < (strRange.location + strRange.length))) {
                [self.mentionedRangeInfoList removeObject:mentionedInfo];
                break;
            }
        }
        changedLocation = range.location;
        changedLength = text.length - range.length;
    }
    
    [self updateAllMentionedRangeInfo:changedLocation length:changedLength];
    [self notifyMentionsDidUpdate];
    
    return shouldUseDefaultChangeText;
}

- (BOOL)shouldTriggerMentionedChoose:(NSRange)range {
    if (range.location == 0) {
        return YES;
    } else if (!isalnum([self.textView.text characterAtIndex:range.location - 1])) {
        // @前是数字和字母才不弹出
        return YES;
    }
    return NO;
}

- (void)insertMentionedUser:(RCUserInfo *)userInfo {
    // 默认需要插入'@'符号（symbolRequest=YES）
    [self insertMentionedUser:userInfo symbolRequest:YES];
}

- (void)insertMentionedUser:(RCUserInfo *)userInfo symbolRequest:(BOOL)symbolRequest {
    if (!self.isMentionedEnabled || !userInfo.userId || !self.textView) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 获取光标位置
        NSUInteger cursorPosition = self.textView.selectedRange.location;
        if (cursorPosition > self.textView.textStorage.length) {
            cursorPosition = self.textView.textStorage.length;
        }
        
        // @位置和内容
        NSUInteger mentionedPosition;
        NSString *insertContent = nil;
        NSInteger changeRangeLength;
        
        if (symbolRequest) {
            // 需要插入'@'符号
            if (userInfo.name.length > 0) {
                insertContent = [NSString stringWithFormat:@"@%@ ", userInfo.name];
            } else {
                insertContent = [NSString stringWithFormat:@"@%@ ", userInfo.userId];
            }
            mentionedPosition = cursorPosition;
            changeRangeLength = [insertContent length];
        } else {
            // @符号已存在，只插入用户名
            if (userInfo.name.length > 0) {
                insertContent = [NSString stringWithFormat:@"%@ ", userInfo.name];
            } else {
                insertContent = [NSString stringWithFormat:@"%@ ", userInfo.userId];
            }
            mentionedPosition = (cursorPosition >= 1) ? (cursorPosition - 1) : 0;
            changeRangeLength = [insertContent length] + 1; // +1 包含已存在的'@'符号
        }
        
        // 创建属性字符串
        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:insertContent];
        [attStr addAttribute:NSFontAttributeName
                       value:self.textView.font
                       range:NSMakeRange(0, insertContent.length)];
        UIColor *foreColor = RCDynamicColor(@"text_primary_color", @"0x000000", @"0xffffffcc");
        if (foreColor) {
            [attStr addAttribute:NSForegroundColorAttributeName
                           value:foreColor
                           range:NSMakeRange(0, insertContent.length)];
        }

        // 插入文本
        [self.textView.textStorage insertAttributedString:attStr atIndex:cursorPosition];
        
        // 修改 textStorage 不会触发 textViewDidChange, 需要手动调用
        [self notifyTextViewDidChange];
        
        self.textView.selectedRange = NSMakeRange(cursorPosition + insertContent.length, 0);
        [self updateAllMentionedRangeInfo:cursorPosition length:insertContent.length];
        
        // 创建'@'信息
        RCMentionedStringRangeInfo *mentionedStrInfo = [[RCMentionedStringRangeInfo alloc] init];
        if (symbolRequest) {
            mentionedStrInfo.content = insertContent; // insertContent 已包含'@'符号
        } else {
            mentionedStrInfo.content = [@"@" stringByAppendingString:insertContent]; // 需要添加'@'符号到content中
        }
        mentionedStrInfo.userId = userInfo.userId;
        mentionedStrInfo.range = NSMakeRange(mentionedPosition, changeRangeLength);
        [self.mentionedRangeInfoList addObject:mentionedStrInfo];
        
        [self notifyMentionsDidUpdate];
    });
}

// 遍历 mentionedInfo 列表，根据修改字符的范围更新 mentionedInfo 信息的range
- (void)updateAllMentionedRangeInfo:(NSInteger)changedLocation length:(NSInteger)changedLength {
    // 使用copy避免在迭代过程中修改数组导致的问题
    for (RCMentionedStringRangeInfo *mentionedInfo in [self.mentionedRangeInfoList copy]) {
        if (mentionedInfo.range.location >= changedLocation) {
            NSInteger newLocation = mentionedInfo.range.location + changedLength;
            if (newLocation >= 0) {
                // 位置仍然有效，更新Range
                mentionedInfo.range = NSMakeRange(newLocation, mentionedInfo.range.length);
            } else {
                // 位置变成负数，说明 @ 信息已被删除操作影响，移除无效数据
                [self.mentionedRangeInfoList removeObject:mentionedInfo];
            }
        }
    }
}

- (void)clearAllMentions {
    [self.mentionedRangeInfoList removeAllObjects];
    [self notifyMentionsDidUpdate];
}

- (void)setupMentionedRangeInfo:(NSArray<RCMentionedStringRangeInfo *> *)mentionedRangeInfo {
    [self.mentionedRangeInfoList removeAllObjects];
    [self.mentionedRangeInfoList addObjectsFromArray:mentionedRangeInfo];
    
    // 更新用户信息到最新
    [self updateMentionedInfoWithLatestUserInfo];
    [self notifyMentionsDidUpdate];
}

- (BOOL)hasContent {
    // 检查文本内容
    BOOL hasText = (self.textView.text.length > 0);
    return hasText;
}

// 将输入框中的 @ 用户名更新为最新的
- (void)updateMentionedInfoWithLatestUserInfo {
    for (RCMentionedStringRangeInfo *mentionedInfo in self.mentionedRangeInfoList) {
        NSString *userId = mentionedInfo.userId;
        if (!userId) {
            continue;
        }
        RCUserInfo *userInfo = nil;
        NSString *latestMentionedContent = nil;
        if ([self.delegate respondsToSelector:@selector(inputStateManager:getUserInfoForUserId:)]) {
            userInfo = [self.delegate inputStateManager:self getUserInfoForUserId:userId];
        }
        if (userInfo && userInfo.name.length > 0) {
            latestMentionedContent = [NSString stringWithFormat:@"@%@ ", userInfo.name];
        }
        if (latestMentionedContent && ![latestMentionedContent isEqualToString:mentionedInfo.content]) {
            self.textView.text = [self.textView.text stringByReplacingOccurrencesOfString:mentionedInfo.content withString:latestMentionedContent];

            mentionedInfo.content = latestMentionedContent;
            mentionedInfo.range = NSMakeRange(mentionedInfo.range.location, latestMentionedContent.length);
        }
    }
}

- (void)clearAllStates {
    // 清除文本
    self.textView.text = @"";
    
    // 清除'@'信息
    [self clearAllMentions];
}

#pragma mark - 私有方法

- (NSString *)currentText {
    return self.textView.text ?: @"";
}

- (void)notifyTextViewDidChange {
    // 模拟textViewDidChange的调用
    if ([self.textView.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.textView.delegate textViewDidChange:self.textView];
    }
}

- (void)notifyMentionsDidUpdate {
    if ([self.delegate respondsToSelector:@selector(inputStateManagerDidUpdateMentions:)]) {
        [self.delegate inputStateManagerDidUpdateMentions:self];
    }
}

/// 安全检查：验证删除范围是否有效
/// @param range 要删除的范围
/// @param textStorage 目标文本存储
/// @return YES 表示安全可删除，NO 表示有风险
- (BOOL)isSafeToDeleteRange:(NSRange)range fromTextStorage:(NSTextStorage *)textStorage {
    // 检查文本存储是否存在
    if (!textStorage) {
        return NO;
    }
    
    // 检查范围是否有效
    if (range.location == NSNotFound || range.length == 0) {
        return NO;
    }
    
    // 检查起始位置是否在有效范围内
    if (range.location >= textStorage.length) {
        return NO;
    }
    
    // 检查结束位置是否在有效范围内
    NSUInteger endLocation = range.location + range.length;
    if (endLocation > textStorage.length) {
        return NO;
    }
    
    return YES;
}

/// 检查文本在指定位置是否以某个字符串开头
/// @param text 源文本
/// @param prefix 要检查的前缀字符串
/// @param index 检查的起始位置
/// @return YES 表示匹配，NO 表示不匹配
- (BOOL)text:(NSString *)text hasPrefix:(NSString *)prefix atIndex:(NSInteger)index {
    if (!text || !prefix || index < 0 || index >= text.length) {
        return NO;
    }
    
    NSInteger remainingLength = text.length - index;
    if (remainingLength < prefix.length) {
        return NO; // 剩余长度不足
    }
    
    NSRange checkRange = NSMakeRange(index, prefix.length);
    NSString *substring = [text substringWithRange:checkRange];
    return [substring isEqualToString:prefix];
}

/// 检查指定范围是否已经在匹配列表中
/// @param range 要检查的范围
/// @param matches 匹配列表
/// @return YES 表示已存在，NO 表示不存在
- (BOOL)isRangeAlreadyInMatches:(NSRange)range matches:(NSArray *)matches {
    for (NSDictionary *match in matches) {
        NSRange existingRange = [match[@"range"] rangeValue];
        if (NSEqualRanges(range, existingRange)) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - getter

- (RCMentionedInfo *)mentionedInfo {
    if (self.mentionedRangeInfoList.count > 0) {
        NSMutableSet *mentionedUserIdList = [[NSMutableSet alloc] init];
        for (RCMentionedStringRangeInfo *mentionedInfo in self.mentionedRangeInfoList) {
            if (mentionedInfo.userId) {
                [mentionedUserIdList addObject:mentionedInfo.userId];
            }
        }
        RCMentionedInfo *mentionedInfo = [[RCMentionedInfo alloc] initWithMentionedType:RC_Mentioned_Users
                                                                             userIdList:[mentionedUserIdList allObjects]
                                                                       mentionedContent:nil];
        return mentionedInfo;
    }
    return nil;
}

- (NSArray<RCMentionedStringRangeInfo *> *)mentionedRangeInfo {
    return [self.mentionedRangeInfoList copy];
}

@end 
