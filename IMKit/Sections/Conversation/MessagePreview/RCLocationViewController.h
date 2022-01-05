//
//  RCLocationViewController.h
//  iOS-IMKit
//
//  Created by YangZigang on 14/11/4.
//  Copyright (c) 2014 RongCloud. All rights reserved.
//

#import "RCBaseViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

/*!
 *  \~chinese
 在地图中展示位置消息的ViewController
 
 *  \~english
 Show the ViewController of the location message in the map. 
 */
@interface RCLocationViewController : RCBaseViewController <MKMapViewDelegate>

/*!
 *  \~chinese
 位置信息中的地理位置的二维坐标
 
 *  \~english
 The two-dimensional coordinates of the geographical location in the location information.
 */
@property (nonatomic, assign) CLLocationCoordinate2D location;

/*!
 *  \~chinese
 位置消息中的地理位置的名称
 
 *  \~english
 The name of the geolocation in the location message.
 */
@property (nonatomic, copy) NSString *locationName;

/*!
 *  \~chinese
 返回按钮的点击事件

 @param sender 返回按钮

 @discussion SDK在此方法中，会针对默认的NavigationBa退出当前界面；
 如果您使用自定义导航按钮或者自定义按钮，可以重写此方法退出当前界面。
 
 *  \~english
 Return to the click event of the button.

 @param sender Return button.

 @ discussion SDK in this method will exit the current interface for the default NavigationBa.
 If you use custom navigation buttons or custom buttons, you can override this method to exit the current interface.
 */
- (void)leftBarButtonItemPressed:(id)sender;

@end
