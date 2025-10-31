//
//  RCDestructSightViewController.m
//  RongIMKit
//
//  Created by Zhaoqianyu on 2018/5/12.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCDestructSightViewController.h"
#import "RCIM.h"
#import "RCMessageModel.h"
#import "RCSightCollectionView.h"
#import "RCDestructSightCollectionCell.h"
#import "RCKitCommonDefine.h"
#import "RCSightPlayerOverlayView+imkit.h"
#import "RCBaseImageView.h"
extern NSString *const RCKitDispatchDownloadMediaNotification;

@interface RCDestructSightViewController () <UIScrollViewDelegate, RCDestructSightCollectionCellDelegate,
                                         UICollectionViewDataSource, UICollectionViewDelegate,
                                         UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, strong) RCBaseImageView *imageView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) NSMutableArray<RCMessageModel *> *messageModelArray;

@property (nonatomic, strong) RCSightCollectionView *collectionView;

@property (nonatomic, strong) UIView *backView;

@property (nonatomic, assign) BOOL autoPlayFlag;

@end

@implementation RCDestructSightViewController {
    BOOL _statusBarHidden;
}

#pragma mark - Life Cycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateDownloadMediaStatus:)
                                                     name:@"RCKitSightDownloadComplete"
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    ////设置导航条透明
    self.autoPlayFlag = YES;
    [self getMessageFromModel:self.messageModel];

    self.backView.frame = self.view.bounds;
    [self.view addSubview:self.backView];
    [self.view addSubview:self.collectionView];
    [self strechToSuperview:self.collectionView];

    self.navigationController.navigationBarHidden = YES;
    [self performSelector:@selector(setStatusBarHidden:) withObject:@(YES) afterDelay:0.6];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [[RCCoreClient sharedCoreClient]
        messageStopDestruct:[[RCCoreClient sharedCoreClient] getMessage:self.messageModel.messageId]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessageDestructing:)
                                                 name:RCKitMessageDestructingNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self setStatusBarHidden:@(YES)];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
    _statusBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[RCCoreClient sharedCoreClient]
        messageBeginDestruct:[[RCCoreClient sharedCoreClient] getMessage:self.messageModel.messageId]];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.collectionView.contentInset = UIEdgeInsetsZero;
}

- (BOOL)prefersStatusBarHidden {
    return _statusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.messageModelArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCDestructSightCollectionCell *cell =
        [self.collectionView dequeueReusableCellWithReuseIdentifier:@"RCSightCell" forIndexPath:indexPath];
    RCMessageModel *model = self.messageModelArray[indexPath.row];
    [cell setDataModel:model];
    cell.delegate = self;
    UIView *contentView = cell.contentView.subviews.firstObject;
    Class playerType = NSClassFromString(@"RCSightPlayerOverlayView");
    if (playerType) {
        for (UIView *view in contentView.subviews) {
            if ([view isKindOfClass:playerType.class]) {
                RCSightPlayerOverlayView *overlayView = ((RCSightPlayerOverlayView *)view);
                overlayView.playBtn.hidden = YES;
                overlayView.slider.userInteractionEnabled = NO;
                overlayView.centerPlayBtn.hidden = YES;
                NSArray<NSLayoutConstraint *> *constraints = overlayView.slider.superview.constraints;
                for (NSLayoutConstraint *constraint in constraints) {
                    if (constraint.firstItem == overlayView.currentTimeLab &&
                        constraint.secondItem == overlayView.playBtn) {
                        constraint.constant = -22;
                    }
                    if (constraint.firstItem == overlayView.durationTimeLabel.superview &&
                        constraint.secondItem == overlayView.durationTimeLabel) {
                        constraint.constant = 22;
                    }
                }
                break;
            }
        }
    }
    UITapGestureRecognizer *sightTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSight)];
    [cell addGestureRecognizer:sightTap];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    RCMessageModel *model = self.messageModelArray[indexPath.row];
    RCDestructSightCollectionCell *sightCell = (RCDestructSightCollectionCell *)cell;

    if (self.messageModel == model && self.autoPlayFlag) {
        sightCell.autoPlay = YES;
        self.autoPlayFlag = NO;
    } else {
        sightCell.autoPlay = NO;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [UIScreen mainScreen].bounds.size;
}

#pragma mark - RCDestructSightCollectionCellDelegate

- (void)closeSight {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)playEnd {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Private Methods

- (void)strechToSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:|[view]|", @"V:|[view]|" ];
    for (NSString *each in formats) {
        NSArray *constraints =
            [NSLayoutConstraint constraintsWithVisualFormat:each options:0 metrics:nil views:@{
                @"view" : view
            }];
        [view.superview addConstraints:constraints];
    }
}

- (void)getMessageFromModel:(RCMessageModel *)model {
    if (model) {
        self.messageModelArray = [[NSMutableArray alloc] initWithObjects:model, nil];
    }
}

- (long long)fileSizeAtPath:(NSString *)filePath {
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

- (void)tapSight {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onMessageDestructing:(NSNotification *)notification {
    NSDictionary *dataDict = notification.userInfo;
    RCMessage *message = dataDict[@"message"];
    NSInteger duration = [dataDict[@"remainDuration"] integerValue];
    if (![message.messageUId isEqualToString:self.messageModel.messageUId]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (duration == 0) {
            [self onMessageDestructDestory:message];
        }
    });
}

- (void)onMessageDestructDestory:(RCMessage *)message {
    if (![message.messageUId isEqualToString:self.messageModel.messageUId]) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    //    RCSightMessage *sightMessage = (RCSightMessage *)self.messageModel.content;
}

#pragma mark - Getters and Setters
- (void)setStatusBarHidden:(NSNumber *)hidden {
    _statusBarHidden = [hidden boolValue];
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}

- (RCBaseImageView *)imageView {
    if (!_imageView) {
        _imageView = [[RCBaseImageView alloc] init];
        _imageView.backgroundColor = RCDynamicColor(@"pop_layer_background_color", @"0x000000", @"0x000000");
    }
    return _imageView;
}

- (RCSightCollectionView *)collectionView {
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        _collectionView = [[RCSightCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        [_collectionView registerClass:[RCDestructSightCollectionCell class] forCellWithReuseIdentifier:@"RCSightCell"];
        _collectionView.backgroundColor = RCDynamicColor(@"pop_layer_background_color", @"0x000000", @"0x000000");
        _collectionView.dataSource = self;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.delegate = self;
        [_collectionView setPagingEnabled:YES];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.scrollEnabled = NO;
    }
    return _collectionView;
}

- (UIView *)backView {
    if (_backView == nil) {
        _backView = [[UIView alloc] init];
        _backView.backgroundColor = RCDynamicColor(@"pop_layer_background_color", @"0x000000", @"0x000000");
    }
    return _backView;
}

@end
