//
//  RCLocationViewController.m
//  iOS-IMKit
//
//  Created by YangZigang on 14/11/4.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCLocationViewController.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"

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
@end

@implementation RCLocationViewController
#pragma mark - Life Cycle
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    MKPinAnnotationView *pinAnnotationView =
        (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pinAnnotationIdentifier];
    if (!pinAnnotationView) {
        pinAnnotationView =
            [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pinAnnotationIdentifier];
        pinAnnotationView.pinColor = MKPinAnnotationColorGreen;
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
@end
