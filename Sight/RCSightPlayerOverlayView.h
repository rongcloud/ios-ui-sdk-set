//
//  RCSightPlayerOverlayView.h
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/28.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightPlayerOverlay.h"
#import "RCSightPlayerTransport.h"
#import <UIKit/UIKit.h>

@interface RCSightPlayerOverlayView : UIView <RCSightPlayerTransport, RCSightPlayerOverlay>

@property (weak, nonatomic) id<RCSightTransportDelegate, RCSightPlayerOverlay> delegate;

@end
