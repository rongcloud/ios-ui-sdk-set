//
//  RCNetworkIndicatorView.h
//  RongIMKit
//
//  Created by MiaoGuangfa on 3/16/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseImageView.h"
#import "RCBaseView.h"
@interface RCNetworkIndicatorView : RCBaseView

@property (nonatomic, strong) RCBaseImageView *networkUnreachableImageView;

- (instancetype)initWithText:(NSString *)text;

- (void)setText:(NSString *)text;
@end
