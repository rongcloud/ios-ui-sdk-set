//
//  RCSightPreviewView.h
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/24.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol RCSightPreviewViewDelegate <NSObject>

- (void)tappedToFocusAtPoint:(CGPoint)point;

@end

/**
 视频捕捉预览视图
 */
@interface RCSightPreviewView : UIView

/**
 视频捕捉预览图层
 */
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;

/**
 预览视图代理
 */
@property (nonatomic, weak) id<RCSightPreviewViewDelegate> delegate;

/**
 显示对焦框动画在某个位置

 @param point 对焦框的中心位置
 */
- (void)showFocusBoxAnimationAtPoint:(CGPoint)point;

@end
