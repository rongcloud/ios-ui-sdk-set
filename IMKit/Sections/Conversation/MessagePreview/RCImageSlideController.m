//
//  RCImageSlideController.m
//  RongIMKit
//
//  Created by zhanggaihong on 2021/5/27.
//  Copyright © 2021年 RongCloud. All rights reserved.
//

#import "RCImageSlideController.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCAssetHelper.h"
#import "RCMessageModel.h"
#import "RCloudImageLoader.h"
#import "RCloudImageView.h"
#import "RCIM.h"
#import "RCAlertView.h"
#import "RCActionSheetView.h"
#import "RCImagePreviewCell.h"
#import "RCPhotoPreviewCollectionViewFlowLayout.h"

@interface RCImageSlideController () <UIScrollViewDelegate, RCImagePreviewCellDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

//当前图片消息的数据模型
@property (nonatomic, strong) NSMutableArray<RCMessageModel *> *messageModelArray;
//当前图片消息的index
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, assign) long previousMessageId;

@property (nonatomic, strong) RCPhotoPreviewCollectionViewFlowLayout *flowLayout;

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, assign) CGFloat previousContentOffsetX;

@property (nonatomic, assign) BOOL isAppear;

@property (nonatomic, assign) BOOL isTouchScroll;

@property (nonatomic, assign) CGFloat viewWidth;

@end

@implementation RCImageSlideController {
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
    [self.view addSubview:self.collectionView];
    [self strechToSuperview:self.collectionView];
    [self getMessageFromModel:self.messageModel];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self setStatusBarHidden:@(YES)];
    self.isAppear = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitViewSupportAutorotateNotification object:@(YES)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
    _statusBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.previousMessageId = self.messageModelArray[self.currentIndex].messageId;
    self.isAppear = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitViewSupportAutorotateNotification object:@(NO)];
}

- (BOOL)prefersStatusBarHidden {
    return _statusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 数据源处理
////取当前界面中一定数量的图片
- (void)getMessageFromModel:(RCMessageModel *)model {
    if (!model) {
        NSLog(@"Parameters are not allowed to be nil");
        return;
    }
    NSMutableArray *ImageArr = [[NSMutableArray alloc] init];
    if (self.onlyPreviewCurrentMessage) {
        [ImageArr addObject:model];
    } else {
        NSArray *imageArrayForward = [self getOlderMessagesThanModel:model count:5 times:0];
        NSArray *imageArrayBackward = [self getLaterMessagesThanModel:model count:5 times:0];
        for (NSInteger j = [imageArrayForward count] - 1; j >= 0; j--) {
            RCMessageModel *modelindex = [imageArrayForward objectAtIndex:j];
            [ImageArr addObject:modelindex];
        }
        [ImageArr addObject:model];
        for (int i = 0; i < [imageArrayBackward count]; i++) {
            RCMessageModel *modelindex = [imageArrayBackward objectAtIndex:i];
            [ImageArr addObject:modelindex];
        }
    }

    self.messageModelArray = ImageArr;
    for (int i = 0; i < ImageArr.count; i++) {
        RCMessageModel *modelindex1 = [ImageArr objectAtIndex:i];
        if (model.messageId == modelindex1.messageId) {
            self.currentIndex = i;
        }
    }
    [self.collectionView reloadData];
}

- (NSArray<RCMessageModel *> *)getLaterMessagesThanModel:(RCMessageModel *)model
                                                   count:(NSInteger)count
                                                   times:(int)times {
    NSArray<RCMessage *> *imageArrayBackward =
        [[RCIMClient sharedRCIMClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCImageMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:false
                                                    count:(int)count];
    NSArray *messages = [self filterDestructImageMessage:imageArrayBackward];
    if (times < 2 && messages.count == 0 && imageArrayBackward.count == count) {
        RCMessageModel *model = [RCMessageModel modelWithMessage:imageArrayBackward.lastObject];
        messages = [self getLaterMessagesThanModel:model count:count times:times + 1];
    }
    return messages;
}

- (NSArray<RCMessageModel *> *)getOlderMessagesThanModel:(RCMessageModel *)model
                                                   count:(NSInteger)count
                                                   times:(int)times {
    NSArray<RCMessage *> *imageArrayForward =
        [[RCIMClient sharedRCIMClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCImageMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:true
                                                    count:(int)count];
    NSArray *messages = [self filterDestructImageMessage:imageArrayForward];
    if (times < 2 && imageArrayForward.count == count && messages.count == 0) {
        RCMessageModel *model = [RCMessageModel modelWithMessage:imageArrayForward.lastObject];
        messages = [self getOlderMessagesThanModel:model count:count times:times + 1];
    }
    return messages;
}

//过滤阅后即焚图片消息
- (NSArray *)filterDestructImageMessage:(NSArray *)array {
    NSMutableArray *backwardMessages = [NSMutableArray array];
    for (RCMessage *mesage in array) {
        if (!(mesage.content.destructDuration > 0)) {
            RCMessageModel *model = [RCMessageModel modelWithMessage:mesage];
            [backwardMessages addObject:model];
        }
    }
    return backwardMessages.copy;
}

#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.messageModelArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCImagePreviewCell *cell =
        [self.collectionView dequeueReusableCellWithReuseIdentifier:@"RCImagePreviewCell" forIndexPath:indexPath];
    cell.delegate = self;
    RCMessageModel *model = self.messageModelArray[indexPath.row];
    [cell configPreviewCellWithItem:model];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[RCImagePreviewCell class]]) {
        [(RCImagePreviewCell *)cell resetSubviews];
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
    self.previousMessageId = self.messageModelArray[self.currentIndex].messageId;
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
            [self getBackMessagesForModel:self.messageModelArray.lastObject count:5 times:0];
        if (models.count > 0) {
            NSMutableArray<NSIndexPath *> *indexPathes = [NSMutableArray new];
            NSInteger lastIndex = self.messageModelArray.count;
            for (int i = 0; i < models.count; i++) {
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:lastIndex + i inSection:0];
                [indexPathes addObject:indexpath];
            }
            [self.messageModelArray addObjectsFromArray:models];
            [self.collectionView insertItemsAtIndexPaths:[indexPathes copy]];
            [self.collectionView reloadItemsAtIndexPaths:[indexPathes copy]];
            [self.collectionView
                scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0]
                       atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                               animated:NO];
        }
    } else if (self.currentIndex <= midIndex && scrollView.contentOffset.x < self.previousContentOffsetX) {
        NSArray<RCMessageModel *> *models =
            [self getFrontMessagesForModel:self.messageModelArray.firstObject count:5 times:0];
        if (models.count > 0) {
            NSMutableArray<NSIndexPath *> *indexPathes = [NSMutableArray new];

            /// NSInteger lastIndex = self.imageArray.count;
            for (int i = 0; i < models.count; i++) {
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:i inSection:0];
                [indexPathes addObject:indexpath];
            }
            [self.messageModelArray insertObjects:models
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
    int index = (int)(scrollView.contentOffset.x / self.view.bounds.size.width);
    if (index < self.messageModelArray.count && self.viewWidth == self.view.bounds.size.width && self.isTouchScroll) {
        self.currentIndex = index;
    }
}

- (NSArray<RCMessageModel *> *)getBackMessagesForModel:(RCMessageModel *)model
                                                 count:(NSInteger)count
                                                 times:(int)times {
    NSArray<RCMessage *> *imageArrayBackward =
        [[RCIMClient sharedRCIMClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCImageMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:false
                                                    count:(int)count];
    NSArray *messages = [self filterDestructImageMessage:imageArrayBackward];
    if (times < 2 && messages.count == 0 && imageArrayBackward.count == count) {
        RCMessageModel *model = [RCMessageModel modelWithMessage:imageArrayBackward.lastObject];
        messages = [self getLaterMessagesThanModel:model count:count times:times + 1];
    }
    return messages;
}

- (NSArray<RCMessageModel *> *)getFrontMessagesForModel:(RCMessageModel *)model
                                                  count:(NSInteger)count
                                                  times:(int)times {
    NSArray<RCMessage *> *imageArrayForward =
        [[RCIMClient sharedRCIMClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCImageMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:true
                                                    count:(int)count];
    NSArray *messages = [self filterDestructImageMessage:imageArrayForward.reverseObjectEnumerator.allObjects];
    if (times < 2 && imageArrayForward.count == count && messages.count == 0) {
        RCMessageModel *model = [RCMessageModel modelWithMessage:imageArrayForward.lastObject];
        messages = [self getOlderMessagesThanModel:model count:count times:times + 1];
    }
    return messages;
}

#pragma mark - RCImagePreviewCellDelegate
- (void)imagePreviewCellDidSingleTap:(RCImagePreviewCell *)cell{
    self.isAppear = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePreviewCellDidLongTap:(UILongPressGestureRecognizer *)sender{
    [self longPressed:sender];
}

- (void)longPressed:(id)sender {
    [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"Save")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
        [self saveImage];
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
        RCMessageModel *currentModel = self.messageModelArray[self.currentIndex];
        //产品需求：当前正在查看的图片被撤回，dismiss 预览页面，否则不做处理
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

- (void)saveImage {
    RCImageMessage *cImageMessage = (RCImageMessage *)self.messageModelArray[self.currentIndex].content;
    UIImage *image;
    if (cImageMessage.localPath.length > 0 &&
        [[NSFileManager defaultManager] fileExistsAtPath:cImageMessage.localPath]) {
        NSString *path = cImageMessage.localPath;
        NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
        image = [UIImage imageWithData:imageData];
    } else {
        NSData *imageData = [RCKitUtility getImageDataForURLString:cImageMessage.imageUrl];
        if (imageData) {
            image = [UIImage imageWithData:imageData];
        } else {
            image = cImageMessage.thumbnailImage;
        }
    }

    [RCAssetHelper savePhotosAlbumWithImage:image authorizationStatusBlock:^{
        [self showAlertController:RCLocalizedString(@"AccessRightTitle")
                          message:RCLocalizedString(@"photoAccessRight")
                      cancelTitle:RCLocalizedString(@"OK")];
    } resultBlock:^(BOOL success) {
        [self showAlertWithSuccess:success];
    }];
}

- (void)showAlertWithSuccess:(BOOL)success {
    if (success) {
        DebugLog(@"save image succeed");
        [self showAlertController:nil
                          message:RCLocalizedString(@"SavePhotoSuccess")
                      cancelTitle:RCLocalizedString(@"OK")];
    } else {
        DebugLog(@" save image fail");
        [self showAlertController:nil
                          message:RCLocalizedString(@"SavePhotoFailed")
                      cancelTitle:RCLocalizedString(@"OK")];
    }
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    [RCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:self];
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

#pragma mark - Getters and Setters
- (RCImageMessage *)currentPreviewImage {
    if (self.currentIndex < self.messageModelArray.count) {
        return (RCImageMessage *)(self.messageModelArray[self.currentIndex].content);
    }
    return nil;
}

- (UICollectionView *)collectionView {
    if(!_collectionView) {
        self.flowLayout = [[RCPhotoPreviewCollectionViewFlowLayout alloc] init];
        [self.flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        self.flowLayout.itemSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
        self.flowLayout.minimumLineSpacing = 0;
        self.flowLayout.minimumInteritemSpacing = 0;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        [_collectionView registerClass:[RCImagePreviewCell class] forCellWithReuseIdentifier:@"RCImagePreviewCell"];
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

- (void)setStatusBarHidden:(NSNumber *)hidden {
    _statusBarHidden = [hidden boolValue];
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}
@end
