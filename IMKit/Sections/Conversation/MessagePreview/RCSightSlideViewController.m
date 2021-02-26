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
#import "RCMessageModel.h"
#import "RCSightCollectionView.h"
#import "RCSightCollectionViewCell.h"
#import "RCSightFileBrowserViewController.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
#import "RCActionSheetView.h"
@interface RCSightSlideViewController () <UIScrollViewDelegate, RCSightCollectionViewCellDelegate,
                                          UICollectionViewDataSource, UICollectionViewDelegate,
                                          UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

//当前图片消息的数据模型
@property (nonatomic, strong) NSMutableArray<RCMessageModel *> *messageModelArray;
//当前图片消息的index
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, assign) NSInteger preSelectIndex;

@property (nonatomic, strong) RCSightCollectionView *collectionView;

@property (nonatomic, assign) CGFloat previousContentOffsetX;

@property (nonatomic, strong) UIButton *rightTopButton;

@property (nonatomic, assign) BOOL flag;

@property (nonatomic, assign) BOOL autoPlayFlag;

@end

@implementation RCSightSlideViewController {
    BOOL _statusBarHidden;
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    ////设置导航条透明
    self.autoPlayFlag = YES;
    [self getMessageFromModel:self.messageModel];
    
    [self.view addSubview:self.collectionView];
    [self strechToSuperview:self.collectionView];
    
    [self.view addSubview:self.rightTopButton];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if ([RCKitUtility isRTL]) {
        self.rightTopButton.frame = CGRectMake(8, ISX ? 40 : 8, 44, 44);
    } else {
        self.rightTopButton.frame = CGRectMake(screenSize.width - 44 - 8, ISX ? 40 : 8, 44, 44);
    }
    self.navigationController.navigationBarHidden = YES;
    [self performSelector:@selector(setStatusBarHidden:) withObject:@(YES) afterDelay:0.6];
    self.automaticallyAdjustsScrollViewInsets = NO;

    [self registerNotificationCenter];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!self.flag) {
        self.flag = YES;
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionNone
                                            animated:NO];
        self.previousContentOffsetX = self.collectionView.contentOffset.x;
    }
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
    NSArray<RCMessageModel *> *imageArrayBackward =
        [[RCIMClient sharedRCIMClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCSightMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:false
                                                    count:(int)count];
    NSArray *messages = [self filterDestructSightMessage:imageArrayBackward];
    if (times < 2 && messages.count == 0 && imageArrayBackward.count == count) {
        messages = [self getBackMessagesForModel:imageArrayBackward.lastObject count:count times:times + 1];
    }
    return messages;
}

- (NSArray<RCMessageModel *> *)getFrontMessagesForModel:(RCMessageModel *)model
                                                  count:(NSInteger)count
                                                  times:(int)times {
    NSArray<RCMessageModel *> *imageArrayForward =
        [[RCIMClient sharedRCIMClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCSightMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:true
                                                    count:(int)count];

    NSArray *messages = [self filterDestructSightMessage:imageArrayForward.reverseObjectEnumerator.allObjects];
    if (times < 2 && imageArrayForward.count == count && messages.count == 0) {
        messages = [self getFrontMessagesForModel:imageArrayForward.lastObject count:count times:times + 1];
    }
    return messages;
}

//过滤阅后即焚视频消息
- (NSArray *)filterDestructSightMessage:(NSArray *)array {
    NSMutableArray *backwardMessages = [NSMutableArray array];
    for (RCMessageModel *model in array) {
        if (!(model.content.destructDuration > 0)) {
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

    self.messageModelArray = modelsArray;

    NSUInteger index = [self.messageModelArray indexOfObject:model];
    self.currentIndex = index;
    self.preSelectIndex = index;
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
    RCMessageModel *model = self.messageModelArray[indexPath.row];
    [cell setDataModel:model];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    RCMessageModel *model = self.messageModelArray[indexPath.row];
    RCSightCollectionViewCell *sightCell = (RCSightCollectionViewCell *)cell;

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

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.onlyPreviewCurrentMessage) {
        return;
    }
    NSInteger midIndex = self.messageModelArray.count / 2;
    NSArray<NSIndexPath *> *array = [self.collectionView indexPathsForVisibleItems];
    NSIndexPath *indexpath = array.firstObject;

    if (indexpath.row >= midIndex && scrollView.contentOffset.x > self.previousContentOffsetX) {
        NSArray<RCMessageModel *> *models =
            [self getBackMessagesForModel:self.messageModelArray.lastObject count:5 times:0];
        if (models.count <= 0) {
            return;
        }
        NSMutableArray<NSIndexPath *> *indexPathes = [NSMutableArray new];
        NSInteger lastIndex = self.messageModelArray.count;
        for (int i = 0; i < models.count; i++) {
            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:lastIndex + i inSection:0];
            [indexPathes addObject:indexpath];
        }
        [self.messageModelArray addObjectsFromArray:models];
        [self.collectionView insertItemsAtIndexPaths:[indexPathes copy]];
        self.preSelectIndex = lastIndex;
    } else if (indexpath.row <= midIndex && scrollView.contentOffset.x < self.previousContentOffsetX) {
        NSArray<RCMessageModel *> *models =
            [self getFrontMessagesForModel:self.messageModelArray.firstObject count:5 times:0];
        if (models.count <= 0) {
            return;
        }
        NSMutableArray<NSIndexPath *> *indexPathes = [NSMutableArray new];

        /// NSInteger lastIndex = self.imageArray.count;
        for (int i = 0; i < models.count; i++) {
            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:i inSection:0];
            [indexPathes addObject:indexpath];
        }
        [self.messageModelArray insertObjects:models
                                    atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, models.count)]];
        [self.collectionView reloadData];
        [self.collectionView
            scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:indexpath.row + models.count inSection:0]
                   atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                           animated:NO];
        self.preSelectIndex = indexpath.row + models.count;
    }

    self.previousContentOffsetX = self.collectionView.contentOffset.x;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    NSInteger offset = (NSInteger)(scrollView.contentOffset.x) % (NSInteger)screenSize.width;
    NSInteger currentindex = (NSInteger)(scrollView.contentOffset.x + offset) / screenSize.width;

    if (abs((int)(self.preSelectIndex - currentindex)) == 1) {
        RCSightCollectionViewCell *sightCell = (RCSightCollectionViewCell *)[self.collectionView
            cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.preSelectIndex inSection:0]];
        [sightCell resetPlay];
        self.preSelectIndex = currentindex;
    }
}

#pragma mark - RCSightCollectionViewCellDelegate

- (void)closeSight {
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
}

- (void)didReceiveRecallMessageNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        long recalledMsgId = [notification.object longValue];
        RCSightCollectionViewCell *sightCell = (RCSightCollectionViewCell *)[self.collectionView
            cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.preSelectIndex inSection:0]];
        [sightCell stopPlay];
        RCMessageModel *currentModel = self.messageModelArray[self.currentIndex];
        //产品需求：当前正在查看的小视频被撤回，dismiss 预览页面，否则不做处理
        if (recalledMsgId == currentModel.messageId) {
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
    UISaveVideoAtPathToSavedPhotosAlbum(localPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self handleError:error];
}

/**
 错误处理
 */
- (void)handleError:(NSError *)error {
    if (error != NULL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertController:nil
                              message:RCLocalizedString(@"SaveFailed")
                          cancelTitle:RCLocalizedString(@"OK")];
        });

    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertController:nil
                              message:RCLocalizedString(@"SaveSuccess")
                          cancelTitle:RCLocalizedString(@"OK")];
        });
    }
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    [RCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:self];
}

#pragma mark - Target Action
- (void)rightTopButtonClicked:(UIButton *)sender {
    RCSightCollectionViewCell *sightCell = (RCSightCollectionViewCell *)[self.collectionView
        cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.preSelectIndex inSection:0]];
    [sightCell stopPlay];
    RCSightFileBrowserViewController *sfv =
        [[RCSightFileBrowserViewController alloc] initWithMessageModel:self.messageModel];
    [self.navigationController pushViewController:sfv animated:YES];
}

#pragma mark - Getters and Setters

- (RCSightCollectionView *)collectionView {
    if(!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
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
        _rightTopButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
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
