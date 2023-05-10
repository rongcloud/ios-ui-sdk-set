//
//  RCCCUtilities.h
//  RongContactCard
//
//  Created by 杜立召 on 15/7/21.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>

@interface RCCCUtilities : NSObject
+ (UIImage *)imageNamed:(NSString *)name ofBundle:(NSString *)bundleName;
+ (NSString *)hanZiToPinYinWithString:(NSString *)hanZi;
+ (NSString *)getFirstUpperLetter:(NSString *)hanzi;
+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList;
+ (BOOL)isContains:(NSString *)firstString withString:(NSString *)secondString;
@end
