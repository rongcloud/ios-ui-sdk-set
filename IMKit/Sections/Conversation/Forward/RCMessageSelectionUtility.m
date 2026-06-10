//
//  RCMessageSelectionUtility.m
//  RongIMKit
//
//  Created by 张改红 on 2018/3/29.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCMessageSelectionUtility.h"
NSString *const RCMessageMultiSelectStatusChanged = @"RCMessageMultiSelectStatusChanged";

NSString *const RCNotificationMessagesMultiSelectedCountChanged = @"RCNotificationMessagesMultiSelectedCountChanged";

@interface RCMessageSelectionUtility ()
@property (nonatomic, strong) NSMutableArray<RCMessageModel *> *messages;
@end
@implementation RCMessageSelectionUtility
+ (instancetype)sharedManager {
    static RCMessageSelectionUtility *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[[self class] alloc] init];
        manager.messages = [NSMutableArray new];
    });
    return manager;
}

- (void)setMultiSelect:(BOOL)multiSelect {
    if (self.multiSelect != multiSelect) {
        _multiSelect = multiSelect;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:RCMessageMultiSelectStatusChanged
                                                                object:@(multiSelect)];
        });
    } else {
        _multiSelect = multiSelect;
    }
}

- (void)addMessageModel:(RCMessageModel *)model {
    BOOL exectued = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(onMessagesMultiSelectedCountWillChanged:model:)]) {
        exectued =
            [self.delegate onMessagesMultiSelectedCountWillChanged:RCMessageMultiSelectStatusSelected model:model];
    }
    if (exectued && model && ![self isContainMessage:model]) {
        [self.messages addObject:model];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onMessagesMultiSelectedCountDidChanged:model:)]) {
            [self.delegate onMessagesMultiSelectedCountDidChanged:RCMessageMultiSelectStatusSelected model:model];
        }
    }
}

- (void)removeMessageModel:(RCMessageModel *)model {
    BOOL exectued = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(onMessagesMultiSelectedCountWillChanged:model:)]) {
        exectued = [self.delegate onMessagesMultiSelectedCountWillChanged:RCMessageMultiSelectStatusCancelSelected
                                                                    model:model];
    }
    if (exectued) {
        [self.messages removeObject:model];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onMessagesMultiSelectedCountDidChanged:model:)]) {
            [self.delegate onMessagesMultiSelectedCountDidChanged:RCMessageMultiSelectStatusCancelSelected model:model];
        }
    }
}

- (BOOL)isContainMessage:(RCMessageModel *)model {
    for (int i = 0; i < self.messages.count; i++) {
        RCMessageModel *tmp = self.messages[i];
        if (tmp.conversationType == model.conversationType && [tmp.targetId isEqualToString:model.targetId] &&
            tmp.messageId == model.messageId) {
            return YES;
        }
    }
    return NO;
}

- (NSArray<RCMessageModel *> *)selectedMessages {
    [self.messages sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        if (((RCMessageModel *)obj1).sentTime < ((RCMessageModel *)obj2).sentTime) {
            return NSOrderedAscending;
        } else if (((RCMessageModel *)obj1).sentTime == ((RCMessageModel *)obj2).sentTime) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
    return self.messages;
}

- (void)removeAllMessages {
    [self.messages removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:RCNotificationMessagesMultiSelectedCountChanged
                                                        object:nil];
}

- (void)clear {
    [self.messages removeAllObjects];
    self.multiSelect = NO;
}
@end
