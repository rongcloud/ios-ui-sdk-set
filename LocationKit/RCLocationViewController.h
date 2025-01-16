//
//  RCLocationViewController.h
//  iOS-IMKit
//
//  Created by YangZigang on 14/11/4.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RongLocationKitAdaptiveHeader.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

/// 在地图中展示位置消息的ViewController
@interface RCLocationViewController : RCBaseViewController <MKMapViewDelegate>

- (instancetype)initWithLocationMessage:(RCLocationMessage *)locationMessage;

/// 返回按钮的点击事件
/// - Parameter sender: 返回按钮
/// - Note: SDK在此方法中，会针对默认的NavigationBa退出当前界面；
/// 如果您使用自定义导航按钮或者自定义按钮，可以重写此方法退出当前界面。
- (void)leftBarButtonItemPressed:(id)sender;

@end
