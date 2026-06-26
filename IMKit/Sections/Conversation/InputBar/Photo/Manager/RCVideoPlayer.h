//
//  RCVideoPlayer.h
//  RongExtensionKit
//
//  Created by birney on 2018/7/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol RCVideoPlayerDelegate <NSObject>
- (void)itemWillPlay;
- (void)itemDidPlayToEnd;
@end

@interface RCVideoPlayer : UIView

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, weak) id<RCVideoPlayerDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)play;

- (void)pause;

@end
