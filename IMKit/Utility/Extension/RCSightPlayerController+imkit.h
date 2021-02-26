//
//  RCSightPlayerController+imkit.h
//  RongIMKit
//
//  Created by 张改红 on 2020/12/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#ifndef RCSightPlayerController_imkit_h
#define RCSightPlayerController_imkit_h
@interface RCSightPlayerController : UIViewController
@property (nonatomic, weak, nullable) id delegate;
@property (strong, nonatomic) NSURL * _Nullable rcSightURL;
@property (strong, nonatomic, nullable) UIImage *firstFrameImage;
@property (nonatomic, assign, getter=isAutoPlay) BOOL autoPlay;
- (void)setFirstFrameThumbnail:(nullable UIImage *)image;
- (void)play;
- (void)reset:(BOOL)inactivateAudioSession;
@end

#endif /* RCSightPlayerController_imkit_h */
