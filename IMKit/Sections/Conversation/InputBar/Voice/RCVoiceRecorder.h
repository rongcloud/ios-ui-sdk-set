//
//  RCVoiceRecorder.h
//  RongExtensionKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol RCVoiceRecorderDelegate;

@interface RCVoiceRecorder : NSObject

+ (RCVoiceRecorder *)defaultVoiceRecorder;

+ (RCVoiceRecorder *)hqVoiceRecorder;

@property (nonatomic, readonly) BOOL isRecording;

- (BOOL)startRecordWithObserver:(id<RCVoiceRecorderDelegate>)observer;

- (BOOL)cancelRecord;

- (void)stopRecord:(void (^)(NSData *wavData, NSTimeInterval secs))compeletion;

- (CGFloat)updateMeters;

@end

@protocol RCVoiceRecorderDelegate <NSObject>

- (void)RCVoiceAudioRecorderDidFinishRecording:(BOOL)success;
- (void)RCVoiceAudioRecorderEncodeErrorDidOccur:(NSError *)error;

@end
