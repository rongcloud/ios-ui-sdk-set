//
//  RCUPinYinTools.h
//  RongUserProfile
//
//  Created by RobinCui on 2024/8/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCUPinYinTools : NSObject
+ (NSMutableDictionary *)sortedWithPinYinArray:(NSArray *)array
                                    usingBlock:(NSString * (^)(id obj, NSUInteger idx))block;

/**
 *  汉字转拼音
 *
 *  @param hanZi 汉字
 *
 *  @return 转换后的拼音
 */
+ (NSString *)hanZiToPinYinWithString:(NSString *)hanZi;
@end

NS_ASSUME_NONNULL_END
