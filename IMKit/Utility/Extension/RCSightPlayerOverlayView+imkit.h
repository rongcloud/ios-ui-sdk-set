//
//  RCSightPlayerOverlayView+imkit.h
//  RongIMKit
//
//  Created by 张改红 on 2020/12/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#ifndef RCSightPlayerOverlayView_imkit_h
#define RCSightPlayerOverlayView_imkit_h

@interface RCSightPlayerOverlayView : UIView
@property (nonatomic, strong) UILabel *currentTimeLab;
@property (nonatomic, strong) UILabel *durationTimeLabel;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIButton *centerPlayBtn;
@end

#endif /* RCSightPlayerOverlayView_imkit_h */
