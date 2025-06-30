//
//  RCSTTObserverContext.h
//  RongIMKit
//
//  Created by RobinCui on 2025/6/11.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>
NS_ASSUME_NONNULL_BEGIN


@interface RCSTTObserverContext : NSObject
/// 添加语音转换监听
/// - Parameters:
///   - observer: 观察者
///   - messageUid: 语音消息ID
+ (void)registerObserver:(id<RCSpeechToTextDelegate>)observer forMessage:(NSString *)messageUid;


/// 移除观察者
/// - Parameter messageUid: 语音消息ID
+ (void)removeObserverForMessage:(NSString *)messageUid;
@end

NS_ASSUME_NONNULL_END
