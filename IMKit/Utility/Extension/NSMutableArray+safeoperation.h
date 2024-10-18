//
//  NSMutableArray+safeoperation.h
//  RongIMLibCore
//
//  Created by chinaspx on 2022/11/29.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray (safeoperation)

- (void)rclib_addObject:(id)anObject;

- (void)rclib_insertObject:(id)anObject atIndex:(NSUInteger)index;

- (void)rclib_removeObjectAtIndex:(NSUInteger)index;

- (void)rclib_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;

@end

NS_ASSUME_NONNULL_END
