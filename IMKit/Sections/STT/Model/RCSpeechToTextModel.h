//
//  RCSpeechToTextModel.h
//  RongIMKit
//
//  Created by RobinCui on 2025/6/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>
NS_ASSUME_NONNULL_BEGIN

@interface RCSpeechToTextModel : NSObject
@property (nonatomic, strong, readonly) RCSpeechToTextInfo *sttInfo;
/// 转换状态。
@property (nonatomic, assign) RCSpeechToTextStatus status;
/// 是否可见，默认 NO。
@property (nonatomic, assign) BOOL isVisible;

- (instancetype)initWithSTTInfo:(RCSpeechToTextInfo *)info;
- (void)synchronizeSTTInfo:(RCSpeechToTextInfo *)info;
@end

NS_ASSUME_NONNULL_END
