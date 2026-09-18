//
//  RCStreamUtilities.h
//  RongIMKit
//
//  Created by zgh on 2025/3/6.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCMessageModel.h"
NS_ASSUME_NONNULL_BEGIN
extern NSUInteger const RCStreamMessageCellLoadingLimit;
@interface RCStreamSummaryModel : NSObject

@property (nonatomic, assign) BOOL isComplete;

@property (nonatomic, copy) NSString *summary;

@end

@interface RCStreamUtilities : NSObject

+ (nullable RCStreamSummaryModel *)parserStreamSummary:(RCMessageModel *)model;

@end

NS_ASSUME_NONNULL_END
