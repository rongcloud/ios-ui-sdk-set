//
//  RCStreamUtilities.m
//  RongIMKit
//
//  Created by zgh on 2025/3/6.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStreamUtilities.h"
#import "NSDictionary+RCAccessor.h"
#import <RongIMLibCore/RCStreamMessage.h>
@implementation RCStreamSummaryModel

@end

@implementation RCStreamUtilities
+ (RCStreamSummaryModel *)parserStreamSummary:(RCMessageModel *)model {
    if (![model.content isKindOfClass:RCStreamMessage.class]) {
        return nil;
    }
    NSString *summaryConfig = [model.expansionDic rclib_stringForKey:RCStreamMessageExpansionSummeryKey];;
    NSData *data = [summaryConfig dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    // 从 NSData 创建 NSDictionary
    NSError *error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    // 错误处理
    if (error) {
        return nil;
    }
    RCStreamSummaryModel *summary = [RCStreamSummaryModel new];
    summary.isComplete = [dictionary rclib_boolForKey:@"complete"];
    summary.summary = [dictionary rclib_stringForKey:@"summary"];
    return summary;
}

@end
