//
//  RCIFlySpeechRecognizerManager.h
//  RongiFlyKit
//
//  Created by zhangke on 2018/11/12.
//  Copyright © 2018 Sin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^IFlyRecognitioResult)(NSString *result);

@interface RCIFlySpeechRecognizerManager : NSObject
@property (nonatomic, assign) BOOL isFlyRecognitioning;
+ (RCIFlySpeechRecognizerManager *)speechRecognizerSharedManager;
- (void)recognitionSpeech:(NSData *)data Result:(void (^)(NSDictionary *result))recognitionResultBlock;
@end

NS_ASSUME_NONNULL_END
