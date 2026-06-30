//
//  RCApplyFriedSectionItem.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCApplyFriendSectionItem.h"


@interface RCApplyFriendSectionItem()
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, copy) RCFriendApplyItemFilterBlock filterBlock;
@property (nonatomic, copy) RCFriedApplyItemCompareBlock compareBlock;
@end

@implementation RCApplyFriendSectionItem

- (instancetype)initWithFilterBlock:(RCFriendApplyItemFilterBlock)filterBlock
                       compareBlock:(RCFriedApplyItemCompareBlock)compareBlock
{
    self = [super init];
    if (self) {
        self.filterBlock = filterBlock;
        self.compareBlock = compareBlock;
        self.items = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)filterAndSortItems:(NSArray *)items {
    NSMutableArray *array = [NSMutableArray array];
    if (!self.filterBlock) {
        [array addObjectsFromArray:items];
    } else {
        BOOL stop = NO;
        for (int i = 0; i< [items count]; i++) {
            id obj = items[i];
            if (self.filterBlock) {
                BOOL savable = self.filterBlock(obj, self.timeStart, self.timeEnd, &stop);
                if (savable) {
                    [array addObject:obj];
                }
                if (stop) {
                    break;
                }
            }
        }
    }

    if (array.count > 0 && self.compareBlock) {
       NSArray *sorted =  [array sortedArrayUsingComparator:self.compareBlock];
        return sorted;
    } else {
        return array;
    }
}

- (BOOL)isValidSectionItem {
    return (self.title != nil) && self.items.count > 0;
}

- (id)itemAtIndex:(NSInteger)index {
    if (index>=0 && index<self.items.count) {
        return [self.items objectAtIndex:index];
    }
    return nil;
}
- (void)removeItemAtIndex:(NSInteger)index {
    if (index>=0 && index<self.items.count) {
        [self.items removeObjectAtIndex:index];
    }
}

- (NSInteger)countOfItems {
    return self.items.count;
}

- (void)clean {
    [self.items removeAllObjects];
}

- (void)appendItems:(NSArray *)items {
    [self.items addObjectsFromArray:items];

}
@end
