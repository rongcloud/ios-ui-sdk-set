//
//  RCNetworkIndicatorView.h
//  RongIMKit
//
//  Created by MiaoGuangfa on 3/16/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCNetworkIndicatorView : UIView

@property (nonatomic, strong) UIImageView *networkUnreachableImageView;

- (instancetype)initWithText:(NSString *)text;
@end
