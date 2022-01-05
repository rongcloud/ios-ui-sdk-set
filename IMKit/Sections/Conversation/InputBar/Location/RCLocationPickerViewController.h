//
//  RCLocationPickerViewController.h
//  RongExtensionKit
//
//  Created by YangZigang on 14/10/31.
//  Copyright (c) 2014 RongCloud. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>
#import "RCBaseViewController.h"

/*!
 *  \~chinese
 POI搜索结束后的回调block

 @param pois                需要显示的POI列表
 @param clearPreviousResult 如果地图位置已经发生变化，需要清空之前的POI数据
 @param hasMore             如果POI数据很多，可以进行“更多”显示
 @param error               搜索POI出现错误时，返回错误信息
 
 *  \~english
 Callback block after POI search.

 @param pois List of POI to be displayed.
 @param clearPreviousResult If the location of the map has changed, you shall empty the previous POI data.
 @param hasMore If there is a lot of POI data, you can do "more" display.
 @param error When an error occurs in the search POI, an error message is returned.
 */
typedef void (^OnPoiSearchResult)(NSArray *pois, BOOL clearPreviousResult, BOOL hasMore, NSError *error);

@protocol RCLocationPickerViewControllerDelegate;
@protocol RCLocationPickerViewControllerDataSource;

/*!
 *  \~chinese
 地理位置选取的ViewController
 
 *  \~english
 ViewController selected by geographical location 
 */
@interface RCLocationPickerViewController
    : RCBaseViewController <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>

/*!
 *  \~chinese
 地理位置选择完成之后的回调
 
 *  \~english
 Callback after the completion of geographic location selection
 */
@property (nonatomic, weak) id<RCLocationPickerViewControllerDelegate> delegate;

/*!
 *  \~chinese
 位置选择的数据源
 
 *  \~english
 Data source for location selection
 */
@property (nonatomic, strong) id<RCLocationPickerViewControllerDataSource> dataSource;

/*!
 mapViewContainer
 */
@property (nonatomic, strong) UIView *mapViewContainer;

/*!
 *  \~chinese
 初始化地理位置选取的ViewController

 @param dataSource  位置选择的数据源
 @return            地理位置选取的ViewController对象
 
 *  \~english
 Initialize the geolocation selected ViewController.

 @param dataSource Location selected data source.
 @ return geographically selected ViewController object
 */
- (instancetype)initWithDataSource:(id<RCLocationPickerViewControllerDataSource>)dataSource;

/*!
 *  \~chinese
 退出当前界面

 @param sender 返回按钮

 @discussion SDK在此方法中，会针对默认的NavigationBar退出当前界面；
 如果您使用自定义导航按钮或者自定义按钮，可以重写此方法退出当前界面。
 
 *  \~english
 Exit the current interface.

 @param sender Return button.

 @ discussion SDK in this method, exits the current interface for the default NavigationBar.
 If you use custom navigation buttons or custom buttons, you can override this method to exit the current interface.
 */
- (void)leftBarButtonItemPressed:(id)sender;

/*!
 *  \~chinese
 完成位置获取

 @param sender 完成按钮

 @discussion 点击完成按钮的后会调用本函数。
 
 *  \~english
 Complete location acquisition.

 @param sender Finish button.

 @ discussion Call this function when you click the finish button.
 */
- (void)rightBarButtonItemPressed:(id)sender;

@end

/*!
 *  \~chinese
 位置选择的数据源
 
 *  \~english
 Data source for location selection
 */
@protocol RCLocationPickerViewControllerDataSource <NSObject>
@optional

/*!
 *  \~chinese
 获取显示的地图控件

 @return 在界面上显示的地图控件
 
 *  \~english
 Get the displayed map control.

 @ return map control displayed on the interface.
 */
- (UIView *)mapView;

/*!
 *  \~chinese
 获取显示的中心点标记

 @return 界面上显示的中心点标记

 @discussion 如不想显示中心点标记，可以返回nil。
 
 *  \~english
 Get the center point mark that is displayed.

 @ return The center point mark displayed on the interface.

 @ discussion If you don't want to display the center mark, you can return nil.
 */
- (CALayer *)annotationLayer;

/*!
 *  \~chinese
 获取位置标注的名称

 @param placeMark   位置标注
 @return            位置标注的名称
 
 *  \~english
 Get the name of the location dimension.

 @param placeMark Location annotation.
 @ return Name of location dimension.
 */
- (NSString *)titleOfPlaceMark:(id)placeMark;

/*!
 *  \~chinese
 获取位置标注的坐标

 @param placeMark   位置标注
 @return            位置标注的二维坐标值
 
 *  \~english
 Get the coordinates of the location dimension.

 @param placeMark Location annotation.
 Two-dimensional coordinate values of @ return position callout.
 */
- (CLLocationCoordinate2D)locationCoordinate2DOfPlaceMark:(id)placeMark;

/*!
 *  \~chinese
 设置地图显示的中心点坐标

 @param location 中心点坐标
 @param animated 是否开启动画效果
 
 *  \~english
 Set the coordinates of the center point displayed on the map.

 @param location Center point coordinate.
 @param animated Whether to turn on the animation effect.
 */
- (void)setMapViewCenter:(CLLocationCoordinate2D)location animated:(BOOL)animated;

/*!
 *  \~chinese
 设置地图显示区域

 @param coordinateRegion 地图显示区域
 @param animated         是否开启动画效果
 
 *  \~english
 set the map display area.

 @param coordinateRegion Map display area.
 @param animated Whether to turn on the animation effect.
 */
- (void)setMapViewCoordinateRegion:(MKCoordinateRegion)coordinateRegion animated:(BOOL)animated;

- (void)didUpdateUserLocation;

/*!
 *  \~chinese
 选择位置标示

 @param placeMark 选择的位置标注

 @discussion 开发者自己实现的RCLocationPickerViewControllerDataSource可以据此进行特定处理。
 当有新的POI列表时，默认选中第一个。
 
 *  \~english
 Select location marking.

 @param placeMark Selected location dimension.

 The RCLocationPickerViewControllerDataSource implemented by @ discussion developers can be specifically processed accordingly.
  When there is a new POI list, the first one is selected by default.
 */
- (void)userSelectPlaceMark:(id)placeMark;

/*!
 *  \~chinese
 获取地图当前中心点的坐标

 @return 当前地图中心点
 
 *  \~english
 Get the coordinates of the current center point of the map.

 @ return current map center point.
 */
- (CLLocationCoordinate2D)mapViewCenter;

/*!
 *  \~chinese
 设置POI搜索完毕后的回调

 @param poiSearchResult POI查询结果
 
 *  \~english
 Set callback after POI search.

 @param poiSearchResult POI query results.
 */
- (void)setOnPoiSearchResult:(OnPoiSearchResult)poiSearchResult;

/*!
 *  \~chinese
 获取当前视野中POI
 
 *  \~english
 Get the POI in the current field of view.
 */
- (void)beginFetchPoisOfCurrentLocation;

/*!
 *  \~chinese
 获取位置在地图中的缩略图

 @return 位置在地图中的缩略图
 
 *  \~english
 Get a thumbnail of the location in the map.

 @ return Thumbnail of  location in the map.
 */
- (UIImage *)mapViewScreenShot;

@end

/*!
 *  \~chinese
 地理位置选择完成之后的回调
 
 *  \~english
 Callback after the completion of geographic location selection
 */
@protocol RCLocationPickerViewControllerDelegate <NSObject>

/*!
 *  \~chinese
 地理位置选择完成之后的回调

 @param locationPicker 地理位置选取的ViewController
 @param location       位置的二维坐标
 @param locationName   位置的名称
 @param mapScreenShot  位置在地图中的缩略图

 @discussion
 如果您需要重写地理位置选择的界面，当选择地理位置完成后，需要调用此回调通知RCConversationViewController定位已完成，可以进一步生成位置消息并发送。
 
 *  \~english
 Callback after the completion of geographic location selection.

 @param locationPicker ViewController selected by geographical location.
 @param location Two-dimensional coordinates of the location.
 @param locationName The name of the location.
 @param mapScreenShot A thumbnail of a location in a map.

 @ discussion
 If you shall rewrite the interface for geolocation selection, when the geolocation selection is completed, you shall call this callback to notify RCConversationViewController that the location has been completed, and you can further generate a location message and send it.
 */
- (void)locationPicker:(RCLocationPickerViewController *)locationPicker
     didSelectLocation:(CLLocationCoordinate2D)location
          locationName:(NSString *)locationName
         mapScreenShot:(UIImage *)mapScreenShot;

@end
