//
//  RCLocationPickerMKMapViewDataSource.m
//  RongExtensionKit
//
//  Created by YangZigang on 14/11/5.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCLocationPickerMKMapViewDataSource.h"
#import "RongLocationKitAdaptiveHeader.h"

@interface RCLocationPickerMKMapViewDataSource ()

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, copy) OnPoiSearchResult completion;
@property (nonatomic, strong) CALayer *annotationLayer;
@property (nonatomic, assign) BOOL userLocationUpdated;
@property (nonatomic, strong) NSDate *firstTimeLocationChanged;
@property (nonatomic, strong) CLLocation *lastPoiLocation;
@property (nonatomic, assign) BOOL ifUpdateUserLocation;
@property (nonatomic, assign) MKCoordinateSpan mapRegionSpan;
@end

@implementation RCLocationPickerMKMapViewDataSource
#pragma mark - Life Cycle
- (instancetype)init {
    if (self = [super init]) {
        self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        self.annotationLayer = [CALayer layer];
        UIImage *image = RCResourceImage(@"map_annotation");
        self.annotationLayer.contents = (id)image.CGImage;
        self.annotationLayer.frame = CGRectMake(0, 0, 27, 37.5);
        [self.mapView setShowsUserLocation:YES];
        self.mapView.delegate = self;
        self.ifUpdateUserLocation = NO;
        CLLocationCoordinate2D center;
        center.latitude = 40.034346;
        center.longitude = 116.344539;
        MKCoordinateSpan span;
        span.latitudeDelta = 0.1;
        span.longitudeDelta = 0.1;
        MKCoordinateRegion region;
        region.center = center;
        region.span = span;
        [self.mapView setRegion:region animated:YES];

        [self.mapView.userLocation addObserver:self
                                    forKeyPath:@"location"
                                       options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                       context:NULL];
    }
    return self;
}

- (void)dealloc {
    [self.mapView.userLocation removeObserver:self forKeyPath:@"location"];
    NSLog(@"%s",__func__);
}




#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self fetchPOIInfo];
    [self clearMapViewMemoryIfNeeded];
}

- (void)clearMapViewMemoryIfNeeded {
    // 不需要频繁切换mapType（影响体验）， 在zoomLevel达到一定变化范围才执行
    if (self.mapView.region.span.longitudeDelta < 0.005 || self.mapView.region.span.latitudeDelta < 0.005) {
        return;
    }
    
    float longitudeDelta = self.mapView.region.span.longitudeDelta - self.mapRegionSpan.longitudeDelta;
    float latitudeDelta = self.mapView.region.span.latitudeDelta - self.mapRegionSpan.latitudeDelta;
    
    if ( fabs(longitudeDelta) < 0.00005 && fabs(latitudeDelta) <0.00005) {
        return;
    }

    MKMapType mapType = self.mapView.mapType;
    switch (self.mapView.mapType) {
        case MKMapTypeHybrid:
            self.mapView.mapType = MKMapTypeStandard;
            break;
        case MKMapTypeStandard:
            self.mapView.mapType = MKMapTypeHybrid;
            break;

        default:
            break;
    }
    self.mapView.mapType = mapType;
    
    // 暂存
    self.mapRegionSpan = self.mapView.region.span;
}

#pragma mark - Private Methods
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    MKUserLocation *userLocation = self.mapView.userLocation;
    if (userLocation.location.coordinate.longitude < 0.000001) {
        return;
    }

    if (!self.firstTimeLocationChanged) {
        self.firstTimeLocationChanged = [NSDate date];
    }
    if ([self.firstTimeLocationChanged timeIntervalSinceNow] < -1.5) {
        return;
    }

    self.userLocationUpdated = YES;
    MKCoordinateRegion coordinateRegion;
    coordinateRegion.center = userLocation.coordinate;
    coordinateRegion.span.latitudeDelta = 0.01;
    coordinateRegion.span.longitudeDelta = 0.01 * self.mapView.frame.size.width / self.mapView.frame.size.height;
    [self.mapView setRegion:coordinateRegion animated:NO];
}

- (void)userSelectPlaceMark:(id)placeMark {
}

- (void)setOnPoiSearchResult:(OnPoiSearchResult)poiSearchResult {
    self.completion = poiSearchResult;
}

- (void)beginFetchPoisOfCurrentLocation {
    if (!self.completion) {
        DebugLog(@"Use the setOnPoiSearchResult function to set the callback block of POI search results");
        return;
    }
}

// CLLocationManager 定位不准确，直接通过 MKMapView 中对自身定位来获得
- (void)setMapViewCenter:(CLLocationCoordinate2D)location animated:(BOOL)animated {
}

- (void)setMapViewCoordinateRegion:(MKCoordinateRegion)coordinateRegion animated:(BOOL)animated {
}

- (void)didUpdateUserLocation {
    self.ifUpdateUserLocation = YES;
}

- (void)fetchPOIInfo {
    void (^updateUserLocationBlock)(void) = ^(void){
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        CLLocationCoordinate2D locationCoordinate2D = self.mapView.centerCoordinate;
        CLLocation *location =
            [[CLLocation alloc] initWithLatitude:locationCoordinate2D.latitude longitude:locationCoordinate2D.longitude];
        __weak typeof(self) weakSelf = self;
        if (self.ifUpdateUserLocation) {
            [geocoder reverseGeocodeLocation:location
                           completionHandler:^(NSArray *placemarks, NSError *error) {
                               //        for (CLPlacemark *placemark in placemarks) {
                               //            DebugLog(@"%@", [placemark description]);
                               //        }
                               if (placemarks.count && weakSelf.completion) {
                                   weakSelf.completion(placemarks, YES, NO, nil);
                               }
                           }];
        }
    };
    
    if (self.lastPoiLocation == nil) {
        self.lastPoiLocation = [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude
                                                          longitude:self.mapView.centerCoordinate.longitude];
        updateUserLocationBlock();
    } else {
        // 关闭精确定位时，这里会获取不到最新设置的值，会导致 < 5 生效，进而导致无法获取位置信息。加了延迟之后就正常了。
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude
                                                                     longitude:self.mapView.centerCoordinate.longitude];
            if ([self.lastPoiLocation distanceFromLocation:currentLocation] < 5) {
                return;
            }
            self.lastPoiLocation = currentLocation;
            updateUserLocationBlock();
        });
    }
    
}

- (NSString *)titleOfPlaceMark:(id)placeMark {
    if (![placeMark isKindOfClass:[CLPlacemark class]]) {
        return nil;
    }
    CLPlacemark *tPlaceMark = (CLPlacemark *)placeMark;
    return [tPlaceMark name];
}

- (CLLocationCoordinate2D)locationCoordinate2DOfPlaceMark:(id)placeMark {
    if (![placeMark isKindOfClass:[CLPlacemark class]]) {
        return CLLocationCoordinate2DMake(0, 0);
    }
    CLPlacemark *tPlaceMark = (CLPlacemark *)placeMark;
    return [tPlaceMark location].coordinate;
}

#pragma mark - Getters and Setters

- (UIView *)mapView {
    return _mapView;
}

- (CALayer *)annotationLayer {
    return _annotationLayer;
}

- (CLLocationCoordinate2D)mapViewCenter {
    return [self.mapView centerCoordinate];
}

- (UIImage *)mapViewScreenShot {
    self.mapView.showsUserLocation = NO;
    UIGraphicsBeginImageContextWithOptions(self.mapView.frame.size, NO, 0.0);
    [self.mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, self.mapView.frame.size.height);
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), flipVertical);
    UIImage *imageAnnotation = RCResourceImage(@"map_annotation");
    CGRect imageAnnotationFrame = CGRectMake(0, 0, 27, 37.5);
    imageAnnotationFrame.origin.y = self.mapView.frame.size.height / 2;
    imageAnnotationFrame.origin.x = self.mapView.frame.size.width / 2 - 16;
    CGContextDrawImage(UIGraphicsGetCurrentContext(), imageAnnotationFrame, imageAnnotation.CGImage);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
