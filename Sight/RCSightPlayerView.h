//
//  RCSightPlayerView.h
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/28.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightPlayerOverlay.h"
#import "RCSightPlayerTransport.h"
#import <UIKit/UIKit.h>

@interface RCSightPlayerView : UIView

- (instancetype)initWithPlayer:(AVPlayer *)player;

@property (nonatomic, readonly) id<RCSightPlayerTransport, RCSightPlayerOverlay> transport;

@property (nonatomic, strong) AVPlayer *player;

@end
