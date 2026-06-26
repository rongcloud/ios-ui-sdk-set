//
//  RCSightRecorder.h
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/24.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@protocol RCSightRecorderDelegate;

/**
 视频录制器，负责视频文件的生成。
 */
@interface RCSightRecorder : NSObject

/**
 初始化recorder

 @param videoSettings 视频设置
 @param audioSettings 音频设置
 @param dispatchQueue 队列
 @return 返回recorder对象
 */
- (instancetype)initWithVideoSettings:(NSDictionary *)videoSettings
                        audioSettings:(NSDictionary *)audioSettings
                        dispatchQueue:(dispatch_queue_t)dispatchQueue;

/**
 录制对象代理
 */
@property (nonatomic, readwrite, weak) id<RCSightRecorderDelegate> delegate;

/**
  准备录制

 @param orientation 录制方向
 */
- (void)prepareToRecord:(AVCaptureVideoOrientation)orientation;

/**
 向recorder中处理 媒体样本 （视频帧,音频样本）

 @param sampleBuffer 未编码的视频样本
 */
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 结束录制

 @discussion 异步调用，完成时调用sightRecorderDidFinishRecording： 失败调用sightRecorder:didFailWithError:
 */
- (void)finishRecording;

@end

@protocol RCSightRecorderDelegate <NSObject>
@required
/**
 完成视频录制时会被调用

 @param recorder 录制实例
 @param outputURL 文件存储路径
 */
- (void)sightRecorder:(RCSightRecorder *)recorder didWriteMovieAtURL:(NSURL *)outputURL;

/**
 录制失败或者出错时调用

 @param recorder 录制实例
 @param error 错误描述
 @param status AVAssetWriter 状态
 */
- (void)sightRecorder:(RCSightRecorder *)recorder
     didFailWithError:(NSError *)error
               status:(NSInteger)status;

@end
