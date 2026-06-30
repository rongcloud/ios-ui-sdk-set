//
//  RCPublicServiceWebViewController.h
//  RongIMLib
//
//  Created by litao on 15/4/11.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCPublicServiceWebViewController : UIViewController

@property (nonatomic, strong) UIColor *backButtonTextColor;
- (instancetype)initWithURLString:(NSString *)URLString;
@end
