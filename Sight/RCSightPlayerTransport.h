//
//  RCSightPlayerTransport.h
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/28.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol RCSightTransportDelegate <NSObject>

- (void)play;
- (void)pause;
- (void)stop;
- (void)cancel;

- (void)scrubbingDidStart;
- (void)scrubbedToTime:(NSTimeInterval)time;
- (void)scrubbingDidEnd;

- (void)jumpedToTime:(NSTimeInterval)time;

@optional
- (void)subtitleSelected:(NSString *)subtitle;
- (BOOL)prefersControlBardHidden;
- (BOOL)prefersBottomBarHidden;

@end

@protocol RCSightPlayerTransport <NSObject>

@property (weak, nonatomic) id<RCSightTransportDelegate> delegate;

/**
 设置缩略图

 @param img 缩略图对象
 */
- (void)setThumbnailImage:(UIImage *)img;

/**
 设置控制条隐藏，或者显示

 @param hidden YES 表示隐藏，NO 表示显示。
 */
- (void)setControlBarHidden:(BOOL)hidden;

- (void)hideCenterPlayBtn;
- (void)startIndicatorViewAnimating;
- (void)stopIndicatorViewAnimating;
- (void)setCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration;
- (void)setScrubbingTime:(NSTimeInterval)time;

/**
 播放器已准备好播放
 */
- (void)readyToPlay;

/**
 将要播放时调用
 */
- (void)willPlay;
- (void)playbackComplete;

@end
