//
//  RCCCUtilities.m
//  RongContactCard
//
//  Created by 杜立召 on 15/7/21.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCCCUtilities.h"
#import "RCCCpinyin.h"
#import "RCCCUserInfo.h"

@implementation RCCCUtilities
+ (UIImage *)imageNamed:(NSString *)name ofBundle:(NSString *)bundleName {
    UIImage *image = nil;
    NSString *image_name = [NSString stringWithFormat:@"%@.png", name];
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *bundlePath = [resourcePath stringByAppendingPathComponent:bundleName];
    NSString *image_path = [bundlePath stringByAppendingPathComponent:image_name];

    // NSString* path = [[[[NSBundle mainBundle] resourcePath]
    // stringByAppendingPathComponent:bundleName]stringByAppendingPathComponent:[NSString
    // stringWithFormat:@"%@.png",name]];

    // image = [UIImage imageWithContentsOfFile:image_path];
    image = [[UIImage alloc] initWithContentsOfFile:image_path];
    return image;
}

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
    NSString *firstUpperLetter = [[pinyin substringToIndex:1] uppercaseString];
    if ([firstUpperLetter compare:@"A"] != NSOrderedAscending &&
        [firstUpperLetter compare:@"Z"] != NSOrderedDescending) {
        return firstUpperLetter;
    } else {
        return @"#";
    }
}

+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList {
    if (!userList || userList.count < 1)
        return nil;

    NSMutableDictionary *infoDic = [NSMutableDictionary new];
    NSMutableArray *allkeyArr = [NSMutableArray new];
    for (id user in userList) {
        NSString *firstLetter = @"#";
        if ([user isMemberOfClass:[RCCCUserInfo class]]) {
            RCCCUserInfo *userInfo = (RCCCUserInfo *)user;
            if (userInfo.displayName.length > 0 && ![userInfo.displayName isEqualToString:@""]) {
                firstLetter = [self getFirstUpperLetter:userInfo.displayName];
            } else {
                firstLetter = [self getFirstUpperLetter:userInfo.name];
            }
        }
        if ([user isMemberOfClass:[RCUserInfo class]]) {
            RCUserInfo *userInfo = (RCUserInfo *)user;
            firstLetter = [self getFirstUpperLetter:userInfo.name];
        }

        if (![allkeyArr containsObject:firstLetter]) {
            [allkeyArr addObject:firstLetter];
        }
        NSMutableArray *result = [infoDic valueForKey:firstLetter];
        if (!result) {
            result = [NSMutableArray new];
        }
        [result addObject:user];
        [infoDic setObject:result forKey:firstLetter];
    }

    allkeyArr = [allkeyArr sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                    return [obj1 compare:obj2 options:NSNumericSearch];
                }].mutableCopy;
    NSMutableDictionary *resultDic = [NSMutableDictionary new];
    [resultDic setObject:infoDic forKey:@"infoDic"];
    [resultDic setObject:allkeyArr forKey:@"allKeys"];
    return resultDic;
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
