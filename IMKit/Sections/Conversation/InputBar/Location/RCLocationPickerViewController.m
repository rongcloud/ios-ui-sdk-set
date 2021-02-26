//
//  RCLocationPickerViewController.m
//  RongExtensionKit
//
//  Created by YangZigang on 14/10/31.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCLocationPickerViewController.h"
#import "RCKitCommonDefine.h"
#import "RCExtensionService.h"
#import "RCLocationPickerMKMapViewDataSource.h"
#import "RCKitConfig.h"
#import "RCAlertView.h"

@interface RCLocationPickerViewController () <RCLocationPickerViewControllerDataSource>

@property (nonatomic, strong) UIView *mapView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CALayer *annotationLayer;

@property (nonatomic, strong) NSMutableArray *pois;
@property (nonatomic, assign) int currentSelectedPoi;
@property (nonatomic, strong) UIView *tableViewFooterView;
@property (nonatomic, strong) UILabel *moreLabel;
@property (nonatomic, strong) UIActivityIndicatorView *busyIndicator;
@property (nonatomic, assign) BOOL hasMore;
/** 设置UINavigationController的NavigationBar

 设置返回按钮、标题、完成按钮。用户可以根据情况编写自己的configureNavigationBar。
 */
- (void)configureNavigationBar;

@end

@implementation RCLocationPickerViewController
#pragma mark - Life Cycle
- (instancetype)initWithDataSource:(id<RCLocationPickerViewControllerDataSource>)dataSource {
    if (self = [super init]) {
        self.dataSource = dataSource;
        __weak typeof(self) weakSelf = self;
        if ([self.dataSource respondsToSelector:@selector(setOnPoiSearchResult:)]) {
            [self.dataSource setOnPoiSearchResult:^(NSArray *pois, BOOL clearPreviousResult, BOOL hasMore,
                                                    NSError *error) {
                [weakSelf onPoiSearchResult:pois clearPreviousResult:clearPreviousResult hasMore:hasMore error:error];
            }];
        }
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        __weak typeof(self) weakSelf = self;
        if ([self.dataSource respondsToSelector:@selector(setOnPoiSearchResult:)]) {
            [self.dataSource setOnPoiSearchResult:^(NSArray *pois, BOOL clearPreviousResult, BOOL hasMore,
                                                    NSError *error) {
                [weakSelf onPoiSearchResult:pois clearPreviousResult:clearPreviousResult hasMore:hasMore error:error];
            }];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        __weak typeof(self) weakSelf = self;
        if ([self.dataSource respondsToSelector:@selector(setOnPoiSearchResult:)]) {
            [self.dataSource setOnPoiSearchResult:^(NSArray *pois, BOOL clearPreviousResult, BOOL hasMore,
                                                    NSError *error) {
                [weakSelf onPoiSearchResult:pois clearPreviousResult:clearPreviousResult hasMore:hasMore error:error];
            }];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    if (!self.mapViewContainer) {
        [self loadMapViewContainer];
    }

    if (!self.title) {
        self.title = RCLocalizedString(@"PickLocation");
    }
    self.mapView = [self.dataSource mapView];
    self.mapView.layer.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.6f].CGColor;
    self.mapView.layer.shadowRadius = 3.0f;
    self.mapView.clipsToBounds = NO;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    CGRect frame = self.view.bounds;
    frame.size.height /= 2;
    self.mapView.frame = self.mapViewContainer.bounds;
    [self.mapViewContainer addSubview:self.mapView];
    CALayer *annotationLayer = [self.dataSource annotationLayer];
    annotationLayer.anchorPoint = CGPointMake(0.5, 1.0f);
    annotationLayer.position =
        CGPointMake(CGRectGetMidX(self.mapViewContainer.bounds), CGRectGetMidY(self.mapViewContainer.bounds));
    [self.mapViewContainer.layer addSublayer:annotationLayer];
    self.annotationLayer = annotationLayer;

    frame.origin.y = frame.size.height;
    self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    self.tableView.backgroundColor = RCDYCOLOR(0xffffff, 0x000000);
    self.tableView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];

    self.tableViewFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.tableViewFooterView.backgroundColor = [UIColor clearColor];
    self.moreLabel = [[UILabel alloc] initWithFrame:self.tableViewFooterView.bounds];
    self.moreLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.moreLabel.text = RCLocalizedString(@"More");
    self.moreLabel.textAlignment = NSTextAlignmentCenter;
    [self.tableViewFooterView addSubview:self.moreLabel];

    if (@available(iOS 13.0, *)) {
        self.busyIndicator =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    } else {
        self.busyIndicator =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    self.busyIndicator.center =
        CGPointMake(CGRectGetMidX(self.tableViewFooterView.bounds), CGRectGetMidY(self.tableViewFooterView.bounds));
    [self.tableViewFooterView addSubview:self.busyIndicator];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = self.tableViewFooterView.bounds;
    [button addTarget:self action:@selector(loadMorePoi:) forControlEvents:UIControlEventTouchUpInside];
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableViewFooterView addSubview:button];

    [self configureNavigationBar];

    [self startStandardUpdates];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appSuspend)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appResume)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewDidLayoutSubviews {
    CGRect frame = self.view.bounds;
    frame.size.height /= 2;
    self.mapViewContainer.frame = frame;
    self.annotationLayer.position =
        CGPointMake(CGRectGetMidX(self.mapViewContainer.bounds), CGRectGetMidY(self.mapViewContainer.bounds));

    frame.origin.y = frame.size.height;
    self.tableView.frame = frame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusDenied) {
        [RCAlertView showAlertController:nil message:RCLocalizedString(@"Location_Service") cancelTitle:RCLocalizedString(@"OK") inViewController:self];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)dealloc {
    if (nil != self.locationManager) {
        if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            [self stopTrackingLocation];
        } else {
            [self.locationManager stopUpdatingLocation];
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDelegate UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.pois.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"LocationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    id placeMark = [self.pois objectAtIndex:indexPath.row];
    cell.textLabel.text = [self.dataSource titleOfPlaceMark:placeMark];
    cell.textLabel.textColor = RCDYCOLOR(0x000000, 0x9f9f9f);
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    if (indexPath.row == self.currentSelectedPoi) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                          darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.dataSource userSelectPlaceMark:[self.pois objectAtIndex:indexPath.row]];
    self.currentSelectedPoi = (int)indexPath.row;
    [self.tableView reloadData];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height < 30) {
        [self.dataSource beginFetchPoisOfCurrentLocation];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (!self.tableView.tableFooterView) {
        return;
    }
    if (scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height < 30) {
        [self.dataSource beginFetchPoisOfCurrentLocation];
        [self setBusyIndicator:YES hidden:NO];
    }
}

#pragma mark - CCLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];

    [(MKMapView *)self.mapView setCenterCoordinate:location.coordinate];
    MKCoordinateRegion coordinateRegion;
    coordinateRegion.center = location.coordinate;
    coordinateRegion.span.latitudeDelta = 0.01;
    coordinateRegion.span.longitudeDelta = 0.01;
    [self.dataSource didUpdateUserLocation];
    [self.dataSource setMapViewCoordinateRegion:coordinateRegion animated:YES];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    DebugLog(@"Error getting user location： %@", [error description]);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
    case kCLAuthorizationStatusAuthorizedAlways:
        [self startTrackingLocation];
        break;
    case kCLAuthorizationStatusAuthorizedWhenInUse:
        DebugLog(@"Got authorization, start tracking location");
        [self startTrackingLocation];
        break;
    case kCLAuthorizationStatusNotDetermined:
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [_locationManager requestWhenInUseAuthorization];
        }

    default:
        break;
    }
}

#pragma mark - Private Methods
- (void)appSuspend {
    if (nil != self.locationManager) {
        if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            [self stopTrackingLocation];
        } else {
            [self.locationManager stopUpdatingLocation];
        }
    }
}

- (void)appResume {
    if (nil != self.locationManager) {
        if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            [self startTrackingLocation];
        } else {
            [self.locationManager startUpdatingLocation];
        }
    }
}
- (void)loadMapViewContainer {
    CGRect frame = self.view.bounds;
    frame.size.height /= 2;
    self.mapViewContainer = [[UIView alloc] initWithFrame:frame];
    [self.view addSubview:self.mapViewContainer];
}

- (void)configureNavigationBar {
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:RCLocalizedString(@"Cancel")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(leftBarButtonItemPressed:)];
    leftItem.tintColor = RCKitConfigCenter.ui.globalNavigationBarTintColor;
    self.navigationItem.leftBarButtonItem = leftItem;

    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:RCLocalizedString(@"Send")
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(rightBarButtonItemPressed:)];
    rightItem.tintColor = RCKitConfigCenter.ui.globalNavigationBarTintColor;
    rightItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)leftBarButtonItemPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setBusyIndicator:(BOOL)busy hidden:(BOOL)hidden {
    if (hidden) {
        self.tableView.tableFooterView = nil;
        return;
    }
    if (!self.tableViewFooterView.superview) {
        self.tableView.tableFooterView = self.tableViewFooterView;
    }
    self.moreLabel.hidden = busy;
    self.busyIndicator.hidden = !busy;
}

- (void)startStandardUpdates {
    // Create the location manager if this object does not
    // already have one.
    if (nil == self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
    }

    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;

    // Set a movement threshold for new events.
    self.locationManager.distanceFilter = 200; // meters

    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [self startTrackingLocation];
    } else {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)rightBarButtonItemPressed:(id)sender {
    if (self.delegate) {
        [self.delegate locationPicker:self
                    didSelectLocation:[self currentLocationCoordinate2D]
                         locationName:[self currentLocationName]
                        mapScreenShot:[self currentMapScreenShot]];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadMorePoi:(id)sender {
    [self setBusyIndicator:YES hidden:NO];
    [self.dataSource beginFetchPoisOfCurrentLocation];
}

- (void)onPoiSearchResult:(NSArray *)pois
      clearPreviousResult:(BOOL)clearPreviousResult
                  hasMore:(BOOL)hasMore
                    error:(NSError *)error {
    if (!self.pois) {
        self.pois = [NSMutableArray array];
    }
    if (clearPreviousResult) {
        [self.pois removeAllObjects];
        self.currentSelectedPoi = 0;
    }
    [self.pois addObjectsFromArray:pois];
    [self.tableView reloadData];
    if (hasMore) {
        [self setBusyIndicator:NO hidden:NO];
    } else {
        [self setBusyIndicator:NO hidden:YES];
    }
    if (self.pois.count > 0 && !self.navigationItem.rightBarButtonItem.isEnabled) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

- (void)startTrackingLocation {

    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        if (self.locationManager) {
            if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [_locationManager requestWhenInUseAuthorization];
            }
        }
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
               status == kCLAuthorizationStatusAuthorizedAlways) {
        if (self.locationManager) {
            [_locationManager startUpdatingLocation];
        }
    }
}

- (void)stopTrackingLocation {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        if (self.locationManager) {
            [_locationManager stopUpdatingLocation];
        }
    }
}

#pragma mark - Getters and Setters

- (void)setOnPoiSearchResult:(OnPoiSearchResult)poiSearchResult {
    [_dataSource setOnPoiSearchResult:poiSearchResult];
}

- (id<RCLocationPickerViewControllerDataSource>)dataSource {
    if (!_dataSource) {
        _dataSource = self;
        _dataSource = [[RCLocationPickerMKMapViewDataSource alloc] init];
    }
    return _dataSource;
}

- (CLLocationCoordinate2D)currentLocationCoordinate2D {
    return [self.dataSource mapViewCenter];
}

- (UIImage *)currentMapScreenShot {
    return [self.dataSource mapViewScreenShot];
}

- (NSString *)currentLocationName {
    if (self.pois) {
        @try {
            id placeMark = [self.pois objectAtIndex:self.currentSelectedPoi];
            return [self.dataSource titleOfPlaceMark:placeMark];
        } @catch (NSException *exception) {
        } @finally {
        }
    }
    CLLocationCoordinate2D location = [self currentLocationCoordinate2D];
    NSString *_longitude = RCLocalizedString(@"Longitude");
    NSString *_latitude = RCLocalizedString(@"Latitude");

    NSString *_f_longitude = [_longitude stringByAppendingFormat:@":%lf", location.longitude];
    NSString *_f_latitude = [_latitude stringByAppendingFormat:@":%lf", location.latitude];

    NSString *_current_locationName = [_f_longitude stringByAppendingFormat:@" %@", _f_latitude];
    return _current_locationName;
    // return [NSString stringWithFormat:@"经度:%lf 纬度:%lf", location.longitude, location.latitude];
}

@end
