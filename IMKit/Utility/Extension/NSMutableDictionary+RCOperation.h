//
//  NSMutableDictionary+RCOperation.h
//  RongIMLibCore
//
//  Created by chinaspx on 2022/11/29.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (RCOperation)

- (void)rclib_setValue:(nullable id)value forKey:(NSString *)key;

- (void)rclib_setObject:(id)anObject forKey:(id<NSCopying>)aKey;

- (void)rclib_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;

- (void)rclib_removeObjectForKey:(id)aKey;

@end

NS_ASSUME_NONNULL_END
