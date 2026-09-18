//
//  RCUPinYinTools.m
//  RongUserProfile
//
//  Created by RobinCui on 2024/8/16.
//

#import "RCUPinYinTools.h"
#import "RCUPinYin.h"
@implementation RCUPinYinTools

/**
 *  汉字转拼音
 *
 *  @param hanZi 汉字
 *
 *  @return 转换后的拼音
 */
+ (NSString *)hanZiToPinYinWithString:(NSString *)hanZi {
    if (!hanZi) {
        return nil;
    }
    NSString *pinYinResult = [NSString string];
    for (int j = 0; j < hanZi.length; j++) {
        NSString *singlePinyinLetter = nil;
        if ([self isChinese:[hanZi substringWithRange:NSMakeRange(j, 1)]]) {
            singlePinyinLetter =
                [[NSString stringWithFormat:@"%c", pinyinFirstLetter([hanZi characterAtIndex:j])] uppercaseString];
        } else {
            singlePinyinLetter = [hanZi substringWithRange:NSMakeRange(j, 1)];
        }

        pinYinResult = [pinYinResult stringByAppendingString:singlePinyinLetter];
    }
    return pinYinResult;
}

+ (BOOL)isChinese:(NSString *)text {
    NSString *match = @"(^[\u4e00-\u9fa5]+$)";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    return [predicate evaluateWithObject:text];
}

+ (NSString *)getFirstUpperLetter:(NSString *)hanzi {
    NSString *pinyin = [self hanZiToPinYinWithString:hanzi];
    if (pinyin.length != 0) {
        NSString *firstUpperLetter = [[pinyin substringToIndex:1] uppercaseString];
        if ([firstUpperLetter compare:@"A"] != NSOrderedAscending &&
            [firstUpperLetter compare:@"Z"] != NSOrderedDescending) {
            return firstUpperLetter;
        }
    }
    return @"#";
}

+ (NSMutableDictionary *)sortedWithPinYinArray:(NSArray *)array
                                    usingBlock:(NSString * (^)(id obj, NSUInteger idx))block {
    
    if (!array || array.count == 0)
        return nil;

    NSMutableDictionary *infoDic = [NSMutableDictionary new];
    NSMutableArray *allkeyArr = [NSMutableArray new];
    for (int i = 0; i<array.count; i++) {
        NSString *firstLetter = @"#";
        id obj = array[i];
        NSString *key = block(obj, i);
        firstLetter = [self getFirstUpperLetter:key];
        if (![allkeyArr containsObject:firstLetter]) {
            [allkeyArr addObject:firstLetter];
        }
        
        NSMutableArray *result = [infoDic valueForKey:firstLetter];
        if (!result) {
            result = [NSMutableArray new];
            [infoDic setObject:result forKey:firstLetter];
        }
        [result addObject:obj];
    }
    return infoDic;
}

+ (BOOL)isContains:(NSString *)firstString withString:(NSString *)secondString {
    if (firstString.length == 0 || secondString.length == 0) {
        return NO;
    }
    NSString *twoStr = [[secondString stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    if ([[firstString lowercaseString] containsString:[secondString lowercaseString]] ||
        [[firstString lowercaseString] containsString:twoStr] ||
        [[[self hanZiToPinYinWithString:firstString] lowercaseString] containsString:twoStr]) {
        return YES;
    }
    return NO;
}

@end
