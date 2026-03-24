//
//  RCLocationViewController.m
//  iOS-IMKit
//
//  Created by YangZigang on 14/11/4.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCLocationViewController.h"
#import <RongLocation/RongLocation.h>

@interface RCLocationViewControllerAnnotation : NSObject <MKAnnotation>
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@end

@implementation RCLocationViewControllerAnnotation

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location locationName:(NSString *)locationName {
    if (self = [super init]) {
        self.coordinate = location;
        self.title = locationName;
    }
    return self;
}

@end

@interface RCLocationViewController ()
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) RCLocationViewControllerAnnotation *annotation;
- (void)setLatitude:(double)latitude longitude:(double)longitude locationName:(NSString *)locationName;
@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, copy) NSString *locationName;
@end

@implementation RCLocationViewController

#pragma mark - Life Cycle

- (instancetype)initWithLocationMessage:(RCLocationMessage *)locationMessage {
    self = [super init];
    if (self) {
        self.locationName = locationMessage.locationName;
        self.location = [self convertCoordinate:locationMessage];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mapView];
    self.annotation =
        [[RCLocationViewControllerAnnotation alloc] initWithLocation:self.location locationName:self.locationName];
    [self.mapView addAnnotation:self.annotation];
    self.mapView.delegate = self;
    self.navigationItem.title = self.title = RCLocalizedString(@"LocationInformation"); //@"位置信息";
    [self configureNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    MKCoordinateRegion coordinateRegion;
    coordinateRegion.center = self.location;
    coordinateRegion.span.latitudeDelta = 0.01;
    coordinateRegion.span.longitudeDelta = 0.01;
    if (-90.0f <= self.location.latitude && self.location.latitude <= 90.0f && -180.0f <= self.location.longitude &&
        self.location.longitude <= 180.0f) {
        [self.mapView setRegion:coordinateRegion animated:NO];
        [self.mapView selectAnnotation:self.annotation animated:YES];
    } else {
        NSLog(@"Invalid latitude and longitude！！！");
    }
}

#pragma mark - MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    static NSString *pinAnnotationIdentifier = @"PinAnnotationIdentifier";
    MKAnnotationView *pinAnnotationView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pinAnnotationIdentifier];
    if (!pinAnnotationView) {
        pinAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pinAnnotationIdentifier];
        pinAnnotationView.image = RCDynamicImage(@"location_map_annotation_img", @"map_annotation");
        pinAnnotationView.canShowCallout = YES;
    }
    return pinAnnotationView;
}

#pragma mark - Public Methods
- (void)leftBarButtonItemPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Private Methods

- (void)configureNavigationBar {
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:RCResourceImage(@"navigator_btn_back") title:nil target:self action:@selector(leftBarButtonItemPressed:)];
}

- (void)setLatitude:(double)latitude longitude:(double)longitude locationName:(NSString *)locationName {
    self.location = CLLocationCoordinate2DMake(latitude, longitude);
    self.locationName = locationName;
}

- (CLLocationCoordinate2D)convertCoordinate:(RCLocationMessage *)locationMessage {
    if (RCLocationCoordinateType_WGS84 == locationMessage.type) {
        return [self wgs84ToGcj02:locationMessage.location];
    }
    return locationMessage.location;
}

#pragma mark - 坐标转化
#define LAT_OFFSET_0(x,y) -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x))
#define LAT_OFFSET_1 (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0
#define LAT_OFFSET_2 (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0
#define LAT_OFFSET_3 (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0

#define LON_OFFSET_0(x,y) 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x))
#define LON_OFFSET_1 (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0
#define LON_OFFSET_2 (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0
#define LON_OFFSET_3 (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0

#define RANGE_LON_MAX 137.8347
#define RANGE_LON_MIN 72.004
#define RANGE_LAT_MAX 55.8271
#define RANGE_LAT_MIN 0.8293
#define jzA 6378245.0
#define jzEE 0.00669342162296594323

- (CLLocationCoordinate2D)wgs84ToGcj02:(CLLocationCoordinate2D)location
{
    return [self gcj02Encrypt:location.latitude bdLon:location.longitude];
}

- (double)transformLat:(double)x bdLon:(double)y
{
    double ret = LAT_OFFSET_0(x, y);
    ret += LAT_OFFSET_1;
    ret += LAT_OFFSET_2;
    ret += LAT_OFFSET_3;
    return ret;
}

- (double)transformLon:(double)x bdLon:(double)y
{
    double ret = LON_OFFSET_0(x, y);
    ret += LON_OFFSET_1;
    ret += LON_OFFSET_2;
    ret += LON_OFFSET_3;
    return ret;
}

- (BOOL)outOfChina:(double)lat bdLon:(double)lon
{
    if (lon < RANGE_LON_MIN || lon > RANGE_LON_MAX)
        return true;
    if (lat < RANGE_LAT_MIN || lat > RANGE_LAT_MAX)
        return true;
    return false;
}

- (CLLocationCoordinate2D)gcj02Encrypt:(double)ggLat bdLon:(double)ggLon
{
    CLLocationCoordinate2D resPoint;
    double mgLat;
    double mgLon;
    if ([self outOfChina:ggLat bdLon:ggLon]) {
        resPoint.latitude = ggLat;
        resPoint.longitude = ggLon;
        return resPoint;
    }
    double dLat = [self transformLat:(ggLon - 105.0)bdLon:(ggLat - 35.0)];
    double dLon = [self transformLon:(ggLon - 105.0) bdLon:(ggLat - 35.0)];
    double radLat = ggLat / 180.0 * M_PI;
    double magic = sin(radLat);
    magic = 1 - jzEE * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((jzA * (1 - jzEE)) / (magic * sqrtMagic) * M_PI);
    dLon = (dLon * 180.0) / (jzA / sqrtMagic * cos(radLat) * M_PI);
    mgLat = ggLat + dLat;
    mgLon = ggLon + dLon;

    resPoint.latitude = mgLat;
    resPoint.longitude = mgLon;
    return resPoint;
}


@end
