//
//  RCVoiceCaptureControl.h
//  RongExtensionKit
//
//  Created by xugang on 7/4/14.
//  Copyright (c) 2014 Heq.Shinoda. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <RongIMLib/RongIMLib.h>
@protocol RCVoiceCaptureControlDelegate <NSObject>
- (void)RCVoiceCaptureControlTimeout:(double)duration;

@optional
- (void)RCVoiceCaptureControlTimeUpdate:(double)duration;
@end

@interface RCVoiceCaptureControl : UIView

@property (nonatomic, weak) id<RCVoiceCaptureControlDelegate> delegate;

@property (nonatomic, readonly, copy) NSData *stopRecord;

@property (nonatomic, readonly, assign) double duration;

//客服会话不识别高音质语音消息，需要 RCConversationType 做判断
- (instancetype)initWithFrame:(CGRect)frame conversationType:(RCConversationType)type;

- (void)startRecord;

- (void)cancelRecord;

- (void)showCancelView;

- (void)hideCancelView;

- (void)showViewWithErrorMsg:(NSString *)errorMsg;

- (void)stopTimer;
@end
