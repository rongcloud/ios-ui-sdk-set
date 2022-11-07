//
//  RCSightSlideViewController.m
//  RongIMKit
//
//  Created by zhaobingdong on 2017/5/2.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightSlideViewController.h"
#import "RCIM.h"
#import "RCKitUtility.h"
#import "RCAssetHelper.h"
#import "RCMessageModel.h"
#import "RCSightCollectionView.h"
#import "RCSightCollectionViewCell.h"
#import "RCSightFileBrowserViewController.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
#import "RCActionSheetView.h"
#import "RCSightPlayerOverlayView+imkit.h"
#import "RCSightModel.h"
#import "RCSightModel+internal.h"
#import "RCSightPlayerController+imkit.h"
#import "RCPhotoPreviewCollectionViewFlowLayout.h"

@interface RCSightSlideViewController () <UIScrollViewDelegate, RCSightCollectionViewCellDelegate,
                                          UICollectionViewDataSource, UICollectionViewDelegate,
                                          UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

//当前图片消息的数据模型
@property (nonatomic, strong) NSMutableArray<RCSightModel *> *messageModelArray;
//当前图片消息的index
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, assign) long previousMessageId;

@property (nonatomic, strong) RCSightCollectionView *collectionView;

@property (nonatomic, assign) CGFloat previousContentOffsetX;

@property (nonatomic, strong) UIButton *rightTopButton;

@property (nonatomic, assign) BOOL autoPlayFlag;

@property (nonatomic, assign) BOOL isAppear;

@property (nonatomic, assign) BOOL isTouchScroll;

@property (nonatomic, assign) CGFloat viewWidth;
@end

@implementation RCSightSlideViewController {
    BOOL _statusBarHidden;
    BOOL _isNotchScreen;//是否是刘海屏
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 11.0, *)) {
        if ([RCKitUtility getKeyWindow].safeAreaInsets.bottom > 0) {
            _isNotchScreen = YES;
        }
    }
    ////设置导航条透明
    self.autoPlayFlag = YES;
    [self getMessageFromModel:self.messageModel];
    
    [self.view addSubview:self.collectionView];
    [self strechToSuperview:self.collectionView];
    
    [self.view addSubview:self.rightTopButton];
    self.navigationController.navigationBarHidden = YES;
    [self performSelector:@selector(setStatusBarHidden:) withObject:@(YES) afterDelay:0.6];
    self.automaticallyAdjustsScrollViewInsets = NO;

    [self registerNotificationCenter];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.isTouchScroll) {
        return;
    }
    [self scrollToCurrentIndex];
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self setStatusBarHidden:@(YES)];
    [self updateRightTopButtonFrame];
    self.isAppear = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitViewSupportAutorotateNotification object:@(YES)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
    _statusBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    if (self.currentIndex < self.messageModelArray.count) {
        self.previousMessageId = self.messageModelArray[self.currentIndex].message.messageId;
    }
    [self resetPlay];
    self.isAppear = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitViewSupportAutorotateNotification object:@(NO)];
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

- (void)dealloc {
}

#pragma mark - 数据源处理
- (NSArray<RCMessageModel *> *)getBackMessagesForModel:(RCMessageModel *)model count:(NSInteger)count times:(int)times {
    NSArray<RCMessage *> *imageArrayBackward =
        [[RCIMClient sharedRCIMClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCSightMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:false
                                                    count:(int)count];
    NSArray *messages = [self filterDestructSightMessage:imageArrayBackward];
    if (times < 2 && messages.count == 0 && imageArrayBackward.count == count) {
        RCMessageModel *model = [RCMessageModel modelWithMessage:imageArrayBackward.lastObject];
        messages = [self getBackMessagesForModel:model count:count times:times + 1];
    }
    return messages;
}

- (NSArray<RCMessageModel *> *)getFrontMessagesForModel:(RCMessageModel *)model
                                                  count:(NSInteger)count
                                                  times:(int)times {
    NSArray<RCMessage *> *imageArrayForward =
        [[RCIMClient sharedRCIMClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCSightMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:true
                                                    count:(int)count];

    NSArray *messages = [self filterDestructSightMessage:imageArrayForward.reverseObjectEnumerator.allObjects];
    if (times < 2 && imageArrayForward.count == count && messages.count == 0) {
        RCMessageModel *model = [RCMessageModel modelWithMessage:imageArrayForward.lastObject];
        messages = [self getFrontMessagesForModel:model count:count times:times + 1];
    }
    return messages;
}

//过滤阅后即焚视频消息
- (NSArray *)filterDestructSightMessage:(NSArray *)array {
    NSMutableArray *backwardMessages = [NSMutableArray array];
    for (RCMessage *mesage in array) {
        if (!(mesage.content.destructDuration > 0)) {
            RCMessageModel *model = [RCMessageModel modelWithMessage:mesage];
            [backwardMessages addObject:model];
        }
    }
    return backwardMessages.copy;
}

- (void)getMessageFromModel:(RCMessageModel *)model {
    if (!model) {
        NSLog(@"Parameters are not allowed to be nil");
        return;
    }
    NSMutableArray *modelsArray = [[NSMutableArray alloc] init];
    if (self.onlyPreviewCurrentMessage) {
        [modelsArray addObject:model];
    } else {
        NSArray<RCMessageModel *> *frontMessagesArray = [self getFrontMessagesForModel:model count:5 times:0];
        [modelsArray addObjectsFromArray:frontMessagesArray];
        [modelsArray addObject:model];
        NSArray<RCMessageModel *> *backMessageArray = [self getBackMessagesForModel:model count:5 times:0];
        [modelsArray addObjectsFromArray:backMessageArray];
    }
    NSUInteger index = [modelsArray indexOfObject:model];
    self.currentIndex = index;
    self.messageModelArray = [self getSightModels:modelsArray].mutableCopy;
}

- (NSArray <RCSightModel *> *)getSightModels:(NSArray *)messages{
    NSMutableArray *array = @[].mutableCopy;
    for (RCMessage *model in messages) {
        RCSightModel *sight = [[RCSightModel alloc] initWithMessage:model];
        [array addObject:sight];
    }
    return array;
}

#pragma mark - collection view data source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.messageModelArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCSightCollectionViewCell *cell =
        [self.collectionView dequeueReusableCellWithReuseIdentifier:@"RCSightCell" forIndexPath:indexPath];
    cell.delegate = self;
    RCSightModel *model = self.messageModelArray[indexPath.row];
    [cell setDataModel:model];
    RCSightMessage *sightMessage = (RCSightMessage *)model.message.content;
    UIView *contentView = cell.contentView.subviews.firstObject;
    Class playerType = NSClassFromString(@"RCSightPlayerOverlayView");
    if (playerType) {
        for (UIView *view in contentView.subviews) {
            if ([view isKindOfClass:playerType.class]) {
                RCSightPlayerOverlayView *overlayView = ((RCSightPlayerOverlayView *)view);
                overlayView.durationTimeLabel.text =  [self formatSeconds:sightMessage.duration];
                break;
            }
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    RCSightModel *model = self.messageModelArray[indexPath.row];
    RCSightCollectionViewCell *sightCell = (RCSightCollectionViewCell *)cell;

    if (self.messageModel.messageId == model.message.messageId && self.autoPlayFlag) {
        sightCell.autoPlay = YES;
        self.autoPlayFlag = NO;
    } else {
        sightCell.autoPlay = NO;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.bounds.size;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isTouchScroll = YES;
    if (self.onlyPreviewCurrentMessage) {
        return;
    }
    self.viewWidth = self.view.bounds.size.width;
    self.previousContentOffsetX = self.currentIndex * self.view.bounds.size.width;
    self.previousMessageId = self.messageModelArray[self.currentIndex].message.messageId;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.isTouchScroll = NO;
    if (self.onlyPreviewCurrentMessage) {
        return;
    }
    NSInteger midIndex = self.messageModelArray.count / 2;
    
    int index = (int)(scrollView.contentOffset.x / self.view.bounds.size.width);
    if (index < self.messageModelArray.count && self.viewWidth == self.view.bounds.size.width) {
        self.currentIndex = index;
    }
    
    if (self.currentIndex >= midIndex && scrollView.contentOffset.x > self.previousContentOffsetX) {
        NSArray<RCMessageModel *> *models =
            [self getBackMessagesForModel:(RCMessageModel *)self.messageModelArray.lastObject.message count:5 times:0];
        if (models.count > 0) {
            NSMutableArray<NSIndexPath *> *indexPathes = [NSMutableArray new];
            NSInteger lastIndex = self.messageModelArray.count;
            for (int i = 0; i < models.count; i++) {
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:lastIndex + i inSection:0];
                [indexPathes addObject:indexpath];
            }
            [self.messageModelArray addObjectsFromArray:[self getSightModels:models]];
            [self.collectionView insertItemsAtIndexPaths:[indexPathes copy]];
            [self.collectionView reloadItemsAtIndexPaths:[indexPathes copy]];
            [self.collectionView
                scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0]
                       atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                               animated:NO];
        }
    } else if (self.currentIndex <= midIndex && scrollView.contentOffset.x < self.previousContentOffsetX) {
        NSArray<RCMessageModel *> *models =
            [self getFrontMessagesForModel:(RCMessageModel *)self.messageModelArray.firstObject.message count:5 times:0];
        if (models.count > 0) {
            NSMutableArray<NSIndexPath *> *indexPathes = [NSMutableArray new];

            /// NSInteger lastIndex = self.imageArray.count;
            for (int i = 0; i < models.count; i++) {
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:i inSection:0];
                [indexPathes addObject:indexpath];
            }
            [self.messageModelArray insertObjects:[self getSightModels:models]
                                        atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, models.count)]];
            [self.collectionView reloadData];
            self.currentIndex = self.currentIndex + models.count;
            [self.collectionView
                scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0]
                       atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                               animated:NO];
        }
    }else{
        [self scrollToCurrentIndex];
    }
    self.previousContentOffsetX = self.currentIndex * self.view.bounds.size.width;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    int index = (round)(scrollView.contentOffset.x / self.view.bounds.size.width);//四舍五入取整
    if (index < self.messageModelArray.count && self.viewWidth == self.view.bounds.size.width && self.isTouchScroll) {
        if (index != self.currentIndex) {
            [self resetPlay];
        }
        self.currentIndex = index;
    }
}

#pragma mark - RCSightCollectionViewCellDelegate

- (void)closeSight {
    self.isAppear = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sightLongPressed:(NSString *)localPath {
    [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"Save")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
        [self saveSight:localPath];
    } cancelBlock:^{
            
    }];
}

#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveRecallMessageNotification:)
                                                 name:RCKitDispatchRecallMessageNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarFrameNotification
                                               object:nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    if (!self.isAppear) {
        return;
    }
    UIDeviceOrientation interfaceOrientation = [UIDevice currentDevice].orientation;
    if (interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight || interfaceOrientation == UIDeviceOrientationPortrait){
        [self updateRightTopButtonFrame];
    }
}

- (void)didReceiveRecallMessageNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        long recalledMsgId = [notification.object longValue];
        RCSightCollectionViewCell *sightCell = (RCSightCollectionViewCell *)[self.collectionView
            cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0]];
        [sightCell stopPlay];
        RCSightModel *currentModel = self.messageModelArray[self.currentIndex];
        //产品需求：当前正在查看的小视频被撤回，dismiss 预览页面，否则不做处理
        if (recalledMsgId == currentModel.message.messageId) {
            UIAlertController *alertController = [UIAlertController
                alertControllerWithTitle:nil
                                 message:RCLocalizedString(@"MessageRecallAlert")
                          preferredStyle:UIAlertControllerStyleAlert];
            [alertController
                addAction:[UIAlertAction actionWithTitle:RCLocalizedString(@"Confirm")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                     [self.navigationController dismissViewControllerAnimated:YES
                                                                                                   completion:nil];
                                                 }]];
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
        }
    });
}

#pragma mark - helper
- (void)scrollToCurrentIndex{
    if (_isNotchScreen) {
        [CATransaction begin];
        [CATransaction disableActions];
        self.collectionView.contentSize = CGSizeMake(self.messageModelArray.count*self.view.frame.size.width, self.view.frame.size.height);
        self.collectionView.contentOffset = CGPointMake(self.view.frame.size.width*self.currentIndex, 0);
        [CATransaction commit];
    }else{
        [self.collectionView performBatchUpdates:^{
            self.collectionView.contentSize = CGSizeMake(self.messageModelArray.count*self.view.frame.size.width, self.view.frame.size.height);
            self.collectionView.contentOffset = CGPointMake(self.view.frame.size.width*self.currentIndex, 0);
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)resetPlay{
    for (RCSightModel *model in self.messageModelArray) {
        if (model.message.messageId == self.previousMessageId) {
            [model.playerController reset:NO];
            return;
        }
    }
}

- (void)updateRightTopButtonFrame{
    if ([RCKitUtility isRTL]) {
        self.rightTopButton.frame = CGRectMake(8, [RCKitUtility getWindowSafeAreaInsets].top+30, 44, 44);
    } else {
        self.rightTopButton.frame = CGRectMake(self.view.frame.size.width - 44 - 8, [RCKitUtility getWindowSafeAreaInsets].top+30, 44, 44);
    }
}

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

- (void)saveSight:(NSString *)localPath {
    if (!localPath) {
        return;
    }
    [RCAssetHelper savePhotosAlbumWithVideoPath:localPath authorizationStatusBlock:^{
        [self showAlertController:RCLocalizedString(@"AccessRightTitle")
                          message:RCLocalizedString(@"photoAccessRight")
                      cancelTitle:RCLocalizedString(@"OK")];
    } resultBlock:^(BOOL success) {
        [self showAlertWithSuccess:success];
    }];
}

- (void)showAlertWithSuccess:(BOOL)success {
    if (success) {
        [self showAlertController:nil
                          message:RCLocalizedString(@"SaveSuccess")
                      cancelTitle:RCLocalizedString(@"OK")];
    } else {
        [self showAlertController:nil
                          message:RCLocalizedString(@"SaveFailed")
                      cancelTitle:RCLocalizedString(@"OK")];
    }
}

- (NSString *)formatSeconds:(NSInteger)value {
    NSInteger seconds = value % 60;
    NSInteger minutes = value / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    [RCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:self];
}

#pragma mark - Target Action
- (void)rightTopButtonClicked:(UIButton *)sender {
    RCSightCollectionViewCell *sightCell = (RCSightCollectionViewCell *)[self.collectionView
        cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0]];
    [sightCell stopPlay];
    RCSightFileBrowserViewController *sfv =
        [[RCSightFileBrowserViewController alloc] initWithMessageModel:self.messageModel];
    [self.navigationController pushViewController:sfv animated:YES];
}

#pragma mark - Getters and Setters

- (RCSightCollectionView *)collectionView {
    if(!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[RCPhotoPreviewCollectionViewFlowLayout alloc] init];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        _collectionView = [[RCSightCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        [_collectionView registerClass:[RCSightCollectionViewCell class] forCellWithReuseIdentifier:@"RCSightCell"];
        _collectionView.dataSource = self;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.delegate = self;
        [_collectionView setPagingEnabled:YES];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor blackColor];
        if (([RCKitUtility isRTL])) {
            _collectionView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }
    }
    return _collectionView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor blackColor];
    }
    return _imageView;
}

- (UIButton *)rightTopButton {
    if (!_rightTopButton) {
        _rightTopButton = [[UIButton alloc] init];
        UIImage *image = RCResourceImage(@"sight_list_button");
        [_rightTopButton setImage:image forState:UIControlStateNormal];
        _rightTopButton.hidden = self.topRightBtnHidden;
        [_rightTopButton addTarget:self
                            action:@selector(rightTopButtonClicked:)
                  forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightTopButton;
}

- (void)setStatusBarHidden:(NSNumber *)hidden {
    _statusBarHidden = [hidden boolValue];
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}
@end
