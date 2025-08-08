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

/// @信息列表（核心数据）
@property (nonatomic, strong) NSMutableArray<RCMentionedStringRangeInfo *> *mentionedRangeInfoList;

/// 引用消息信息（新增）
@property (nonatomic, strong, nullable) NSString *referencedSenderName;
@property (nonatomic, strong, nullable) NSString *referencedContent;

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
        [attStr addAttribute:NSForegroundColorAttributeName
                       value:[RCKitUtility generateDynamicColor:HEXCOLOR(0x000000) darkColor:RCMASKCOLOR(0xffffff, 0.8)]
                       range:NSMakeRange(0, insertContent.length)];
        
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
                // 位置变成负数，说明@信息已被删除操作影响，移除无效数据
                [self.mentionedRangeInfoList removeObject:mentionedInfo];
            }
        }
    }
}

- (void)clearAllMentions {
    [self.mentionedRangeInfoList removeAllObjects];
    [self notifyMentionsDidUpdate];
}

#pragma mark - @信息属性

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

#pragma mark - 引用消息状态管理（新增功能）

- (void)setReferenceInfo:(NSString *)senderName content:(NSString *)content {
    self.referencedSenderName = senderName;
    self.referencedContent = content;
}

- (void)clearReferenceInfo {
    self.referencedSenderName = nil;
    self.referencedContent = nil;
}

- (BOOL)hasReferenceInfo {
    return (self.referencedSenderName.length > 0 || 
            self.referencedContent.length > 0);
}

#pragma mark - 完整状态管理（增强版）

- (BOOL)hasContent {
    // 检查文本内容
    BOOL hasText = (self.textView.text.length > 0);
    
    // 检查'@'信息
    BOOL hasMentionedUsers = (self.mentionedRangeInfoList.count > 0);
    
    // ✅ 检查引用消息信息（新增）
    BOOL hasReferenceInfo = self.hasReferenceInfo;
    
    return hasText || hasMentionedUsers || hasReferenceInfo;
}

- (NSDictionary *)stateData {
    // 使用统一的 hasContent 判断
    if (!self.hasContent) {
        return nil;
    }
    
    NSString *textContent = self.textView.text ?: @"";
    NSMutableDictionary *stateData = [NSMutableDictionary dictionary];
    [stateData setObject:textContent forKey:@"textContent"];
    
    // 保存'@'信息列表
    if (self.mentionedRangeInfoList.count > 0) {
        NSMutableArray *mentionedRangeInfoList = [NSMutableArray array];
        for (RCMentionedStringRangeInfo *info in self.mentionedRangeInfoList) {
            NSString *encodedInfo = [info encodeToString];
            if (encodedInfo) {
                [mentionedRangeInfoList addObject:encodedInfo];
            }
        }
        [stateData setObject:mentionedRangeInfoList forKey:@"mentionedRangeInfoList"];
    }
    
    // ✅ 引用消息信息（新增）
    if (self.hasReferenceInfo) {
        NSMutableDictionary *referenceInfo = [NSMutableDictionary dictionary];
        if (self.referencedSenderName) referenceInfo[@"senderName"] = self.referencedSenderName;
        if (self.referencedContent) referenceInfo[@"content"] = self.referencedContent;
        
        [stateData setObject:referenceInfo forKey:@"referenceInfo"];
    }
    
    return [stateData copy];
}

- (BOOL)restoreFromStateData:(NSDictionary *)stateData {
    if (!stateData || ![stateData isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    // 恢复文本内容
    NSString *textContent = stateData[@"textContent"];
    if (textContent && textContent.length > 0) {
        self.textView.text = textContent;
    }
    
    // 恢复'@'信息
    NSArray *mentionedRangeInfoList = stateData[@"mentionedRangeInfoList"];
    [self.mentionedRangeInfoList removeAllObjects];
    
    for (NSString *encodedInfo in mentionedRangeInfoList) {
        RCMentionedStringRangeInfo *info = [[RCMentionedStringRangeInfo alloc] initWithDecodeString:encodedInfo];
        if (info) {
            [self.mentionedRangeInfoList addObject:info];
        }
    }

    // 如果从缓存恢复时,将输入框中的 @ 用户名更新为最新的   
    [self updateMentionedInfoWithLatestUserInfo];
    
    // 恢复引用消息信息
    NSDictionary *referenceInfo = stateData[@"referenceInfo"];
    if (referenceInfo) {
        [self setReferenceInfo:referenceInfo[@"senderName"]
                       content:referenceInfo[@"content"]];
    } else {
        [self clearReferenceInfo];
    }
    
    [self notifyMentionsDidUpdate];
    
    return YES;
}

- (void)restoreFromOriginalMessage:(RCMentionedInfo *)mentionedInfo {
    if (!mentionedInfo) {
        return;
    }
    // 清空现有'@'信息
    [self.mentionedRangeInfoList removeAllObjects];
    
    if (mentionedInfo.userIdList.count == 0) {
        [self notifyMentionsDidUpdate];
        return;
    }
    // 重建'@'信息位置映射 - 支持重复用户名的正确定位
    NSString *currentText = [self currentText];
    if (!currentText || currentText.length == 0) {
        return;
    }
    
    // 预处理：获取所有用户信息，避免重复调用delegate
    NSMutableDictionary *userDisplayNames = [NSMutableDictionary dictionary];
    for (NSString *userId in mentionedInfo.userIdList) {
        RCUserInfo *userInfo = nil;
        if ([self.delegate respondsToSelector:@selector(inputStateManager:getUserInfoForUserId:)]) {
            userInfo = [self.delegate inputStateManager:self getUserInfoForUserId:userId];
        }
        if (userInfo) {
            userDisplayNames[userId] = userInfo.name ?: userId;
        }
    }
    
    // 一次扫描找到所有可能的@匹配位置
    NSMutableArray *allFoundMatches = [NSMutableArray array];
    NSRange searchRange = NSMakeRange(0, currentText.length);
    
    while (searchRange.location < currentText.length) {
        NSRange atRange = [currentText rangeOfString:@"@" options:0 range:searchRange];
        if (atRange.location == NSNotFound) {
            break; // 没有更多@符号
        }
        
        // 检查这个@位置是否匹配任何用户名
        for (NSString *userId in mentionedInfo.userIdList) {
            NSString *displayName = userDisplayNames[userId];
            if (!displayName) continue;
            
            NSString *pattern = [NSString stringWithFormat:@"@%@ ", displayName];
            if ([self text:currentText hasPrefix:pattern atIndex:atRange.location]) {
                NSRange matchRange = NSMakeRange(atRange.location, pattern.length);
                
                // 检查这个位置是否已经被记录（避免重复）
                if (![self isRangeAlreadyInMatches:matchRange matches:allFoundMatches]) {
                    [allFoundMatches addObject:@{
                        @"range": [NSValue valueWithRange:matchRange],
                        @"userId": userId ?: @"",
                        @"content": pattern ?: @""
                    }];
                    break; // 找到匹配就跳出内层循环
                }
            }
        }
        
        // 移动到下一个字符位置继续搜索
        searchRange.location = atRange.location + 1;
        searchRange.length = currentText.length - searchRange.location;
    }
    
    // 按位置排序所有匹配项
    [allFoundMatches sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        NSRange range1 = [obj1[@"range"] rangeValue];
        NSRange range2 = [obj2[@"range"] rangeValue];
        if (range1.location < range2.location) return NSOrderedAscending;
        if (range1.location > range2.location) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    for (NSDictionary *match in allFoundMatches) {
        NSString *matchedUserId = match[@"userId"];
            // 创建RangeInfo
            RCMentionedStringRangeInfo *rangeInfo = [[RCMentionedStringRangeInfo alloc] init];
            rangeInfo.range = [match[@"range"] rangeValue];
            rangeInfo.userId = matchedUserId;
            rangeInfo.content = match[@"content"];
            
            [self.mentionedRangeInfoList addObject:rangeInfo];
    }
    
    [self notifyMentionsDidUpdate];
}

// 如果从缓存恢复时,将输入框中的 @ 用户名更新为最新的
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
    
    // 清除引用消息信息
    [self clearReferenceInfo];
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

@end 
