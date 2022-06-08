//
//  RCSightCapturer.h
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/24.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

/**
 音视频采集者采集样本输出代理
 */
@protocol RCSightCapturerOutputDelegate <NSObject>

@required

/**
 音视频样本输出是会调用该方法

 @param sampleBuffer 音频或者视频样本
 */
- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@optional

/**
 对焦完成时调用

 @param point 对焦中心点
 */
- (void)focusDidfinish:(CGPoint)point;

@end

/**
 视频，音频，图像采集者
 */
@interface RCSightCapturer : NSObject

- (instancetype)initWithVideoPreviewPlayer:(AVCaptureVideoPreviewLayer *)layer;

/**
 采集预览图层
 */
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;

/**
 视频帧和音频样本输出代理 一般会把这些数据交给SightRecorder
 */
@property (nonatomic, weak) id<RCSightCapturerOutputDelegate> delegate;

/**
 音视频样本输出队列
 */
@property (nonatomic, strong, readonly) dispatch_queue_t sessionQueue;

/**
 采集者推荐的视频压缩设置
 */
@property (nonatomic, copy, readonly) NSDictionary *recommendedVideoCompressionSettings;

/**
 采集者推荐的音频压缩设置
 */
@property (nonatomic, copy, readonly) NSDictionary *recommendedAudioCompressionSettings;

/**
 开始采集
 */
- (void)startRunning;

/**
 结束采集
 */
- (void)stopRunning;

/**
 切换摄像头

 @return 成功返回YES，失败返回NO
 */
- (BOOL)switchCamera;

/**
 在某个坐标点对焦

 @param point 坐标
 */
- (void)focusAtPoint:(CGPoint)point;

/**
 是否支持对焦

 @return YES 表示支持，否则为NO
 */
- (BOOL)cameraSupportsTapToFocus;

/**
  拍摄静止图片

 @param orientation 采集方向
 @param completion 拍摄图片回调block
 */
- (void)captureStillImage:(AVCaptureVideoOrientation)orientation completion:(void (^)(UIImage *image))completion;

- (BOOL)resetSessionInput;
- (void)resetAudioSession;
@end
