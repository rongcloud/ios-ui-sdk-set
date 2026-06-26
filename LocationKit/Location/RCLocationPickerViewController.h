//
//  RCLocationPickerViewController.h
//  RongExtensionKit
//
//  Created by YangZigang on 14/10/31.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>
#import "RongLocationKitAdaptiveHeader.h"


/*!
 POI搜索结束后的回调block

 - Parameter pois: 需要显示的POI列表
 - Parameter clearPreviousResult: 如果地图位置已经发生变化，需要清空之前的POI数据
 - Parameter hasMore: 如果POI数据很多，可以进行“更多”显示
 - Parameter error: 搜索POI出现错误时，返回错误信息
 */
typedef void (^OnPoiSearchResult)(NSArray *pois, BOOL clearPreviousResult, BOOL hasMore, NSError *error);

@protocol RCLocationPickerViewControllerDelegate;
@protocol RCLocationPickerViewControllerDataSource;

/// 地理位置选取的ViewController
@interface RCLocationPickerViewController
    : RCBaseViewController <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>

/// 地理位置选择完成之后的回调
@property (nonatomic, weak) id<RCLocationPickerViewControllerDelegate> delegate;

/// 位置选择的数据源
@property (nonatomic, strong) id<RCLocationPickerViewControllerDataSource> dataSource;

/// mapViewContainer
@property (nonatomic, strong) IBOutlet UIView *mapViewContainer;

/*!
 初始化地理位置选取的ViewController

 - Parameter dataSource: 位置选择的数据源
 - Returns: 地理位置选取的ViewController对象
 */
- (instancetype)initWithDataSource:(id<RCLocationPickerViewControllerDataSource>)dataSource;
/*!
 退出当前界面

 - Parameter sender: 返回按钮

 - Note: SDK在此方法中，会针对默认的NavigationBar退出当前界面；
 如果您使用自定义导航按钮或者自定义按钮，可以重写此方法退出当前界面。
 */
- (void)leftBarButtonItemPressed:(id)sender;

/*!
 完成位置获取

 - Parameter sender: 完成按钮

 - Note: 点击完成按钮的后会调用本函数。
 */
- (void)rightBarButtonItemPressed:(id)sender;

@end

/// 位置选择的数据源
@protocol RCLocationPickerViewControllerDataSource <NSObject>
@optional

/*!
 获取显示的地图控件

 - Returns: 在界面上显示的地图控件
 */
- (UIView *)mapView;

/*!
 获取显示的中心点标记

 - Returns: 界面上显示的中心点标记

 - Note: 如不想显示中心点标记，可以返回nil。
 */
- (CALayer *)annotationLayer;

/*!
 获取位置标注的名称

 - Parameter placeMark: 位置标注
 - Returns: 位置标注的名称
 */
- (NSString *)titleOfPlaceMark:(id)placeMark;

/*!
 获取位置标注的坐标

 - Parameter placeMark: 位置标注
 - Returns: 位置标注的二维坐标值
 */
- (CLLocationCoordinate2D)locationCoordinate2DOfPlaceMark:(id)placeMark;

/*!
 设置地图显示的中心点坐标

 - Parameter location: 中心点坐标
 - Parameter animated: 是否开启动画效果
 */
- (void)setMapViewCenter:(CLLocationCoordinate2D)location animated:(BOOL)animated;

/*!
 设置地图显示区域

 - Parameter coordinateRegion: 地图显示区域
 - Parameter animated: 是否开启动画效果
 */
- (void)setMapViewCoordinateRegion:(MKCoordinateRegion)coordinateRegion animated:(BOOL)animated;

- (void)didUpdateUserLocation;

/*!
 选择位置标注

 - Parameter placeMark: 选择的位置标注

 - Note: 开发者自己实现的RCLocationPickerViewControllerDataSource可以据此进行特定处理。
 当有新的POI列表时，默认选中第一个。
 */
- (void)userSelectPlaceMark:(id)placeMark;

/*!
 获取地图当前中心点的坐标

 - Returns: 当前地图中心点
 */
- (CLLocationCoordinate2D)mapViewCenter;

/*!
 设置POI搜索完毕后的回调

 - Parameter poiSearchResult: POI查询结果
 */
- (void)setOnPoiSearchResult:(OnPoiSearchResult)poiSearchResult;

/// 获取当前视野中POI
- (void)beginFetchPoisOfCurrentLocation;

/*!
 获取位置在地图中的缩略图

 - Returns: 位置在地图中的缩略图
 */
- (UIImage *)mapViewScreenShot;

@end

/// 地理位置选择完成之后的回调
@protocol RCLocationPickerViewControllerDelegate <NSObject>
@optional

/// 地理位置选择完成之后的回调
///
/// - Parameter locationPicker: 地理位置选取的ViewController
/// - Parameter location: 位置的二维坐标
/// - Parameter locationName: 位置的名称
/// - Parameter mapScreenShot: 位置在地图中的缩略图
///
/// - Note: 如果您需要重写地理位置选择的界面，当选择地理位置完成后，
/// 需要调用此回调通知RCConversationViewController定位已完成，可以进一步生成位置消息并发送。
- (void)locationPicker:(RCLocationPickerViewController *)locationPicker
     didSelectLocation:(CLLocationCoordinate2D)location
          locationName:(NSString *)locationName
         mapScreenShot:(UIImage *)mapScreenShot;



@end
