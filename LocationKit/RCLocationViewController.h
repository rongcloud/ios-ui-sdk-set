//
//  RCLocationViewController.h
//  iOS-IMKit
//
//  Created by YangZigang on 14/11/4.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#if __has_include(<RongIMKit/RongIMKit.h>)

#import <RongIMKit/RongIMKit.h>

#else

#import "RongIMKit.h"

#endif

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

/*!
 在地图中展示位置消息的ViewController
 */
@interface RCLocationViewController : RCBaseViewController <MKMapViewDelegate>

- (instancetype)initWithLocationMessage:(RCLocationMessage *)locationMessage;

/*!
 返回按钮的点击事件

 @param sender 返回按钮

 @discussion SDK在此方法中，会针对默认的NavigationBa退出当前界面；
 如果您使用自定义导航按钮或者自定义按钮，可以重写此方法退出当前界面。
 */
- (void)leftBarButtonItemPressed:(id)sender;

@end
