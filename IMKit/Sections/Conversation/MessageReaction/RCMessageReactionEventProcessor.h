//
//  RCMessageReactionEventProcessor.h
//  RongIMKit
//
//  Created by RC on 2026/6/24.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>

NS_ASSUME_NONNULL_BEGIN

@class RCMessageModel;

typedef NSMutableArray<RCMessageModel *> *_Nullable (^RCMessageReactionEventModelsProvider)(void);
typedef BOOL (^RCMessageReactionEventPreviewTrackingProvider)(void);

@interface RCMessageReactionEventProcessResult : NSObject

@property (nonatomic, copy) NSArray<RCMessageModel *> *updatedModels;
@property (nonatomic, copy) NSArray<NSIndexPath *> *updatedIndexPaths;
@property (nonatomic, copy) NSArray<RCMessageModel *> *modelsNeedingUserInfoPreload;

@end

@interface RCMessageReactionEventProcessor : NSObject

- (void)enqueueEvents:(NSArray<RCMessageReactionEventData *> *)events
       modelsProvider:(RCMessageReactionEventModelsProvider)modelsProvider
     previewUserLimit:(NSUInteger)previewUserLimit
trackPreviewUserChangesProvider:(RCMessageReactionEventPreviewTrackingProvider)trackPreviewUserChangesProvider
           completion:(nullable void (^)(RCMessageReactionEventProcessResult *result))completion;

- (RCMessageReactionEventProcessResult *)processEvents:(NSArray<RCMessageReactionEventData *> *)events
                                                models:(NSMutableArray<RCMessageModel *> *)models
                                      previewUserLimit:(NSUInteger)previewUserLimit
                               trackPreviewUserChanges:(BOOL)trackPreviewUserChanges;

- (BOOL)applyEvent:(RCMessageReactionEventData *)eventData
     operationType:(RCMessageReactionOperationType)operationType
             model:(RCMessageModel *)model
  previewUserLimit:(NSUInteger)previewUserLimit;

@end

NS_ASSUME_NONNULL_END
