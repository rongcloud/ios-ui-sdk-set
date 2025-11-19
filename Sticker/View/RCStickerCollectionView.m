//
//  RCStickerCollectionView.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/14.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerCollectionView.h"
#import "RCStickerCollectionViewCell.h"
#import "RCStickerModule.h"
#import "RCStickerMessage.h"
#import "RCStickerUtility.h"
#import "RCStickerPreviewView.h"
#import "RongStickerAdaptiveHeader.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define CellIdentifier @"CellIdentifier"

static CGFloat const RCStickerPreviewViewWidth = 150.0;
static CGFloat const RCStickerPreviewViewHeight = 168.0;
static CGFloat const RCStickerPreviewBottomInset = 4.0;
@interface RCStickerCollectionViewCell ()
@property (nonatomic, strong) RCBaseImageView *thumbImageView;
@end

@interface RCStickerCollectionView () <UICollectionViewDataSource, UICollectionViewDelegate,
                                       UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) RCBaseCollectionView *collectionView;

@property (nonatomic, strong) NSArray<RCStickerSingle *> *stickers;
@property (nonatomic, weak) RCStickerCollectionViewCell *lastPreviewCell;
@property (nonatomic, strong) RCStickerPreviewView *stickerPreviewView;

@end

@implementation RCStickerCollectionView

- (instancetype)initWithStickers:(NSArray *)stickers {
    self = [super initWithFrame:CGRectMake(0, 0, ScreenWidth, 186)];
    if (self) {
        self.stickers = stickers;
        [self initialize];
        [self registerNotification];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initialize {
    self.backgroundColor = RCDYCOLOR(0xF2F2F3, 0x0b0b0b);
    self.collectionView.frame = self.bounds;
    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(myHandleCollectionViewCellLongPressed:)];
    [self.collectionView addGestureRecognizer:longPress];
    [self addSubview:self.collectionView];
}

- (RCStickerPreviewView *)stickerPreviewView {
    if (!_stickerPreviewView) {
        _stickerPreviewView = [[RCStickerPreviewView alloc] init];
    }
    return _stickerPreviewView;
}
#pragma mark - LongPressGestureRecognizer

- (void)myHandleCollectionViewCellLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    CGPoint pointTouch = [gestureRecognizer locationInView:self.collectionView];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:pointTouch];
        RCStickerCollectionViewCell *cell =
            (RCStickerCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (indexPath == nil) {
        } else {
            RongStickerLog(@"Section = %ld,Row = %ld,cellframe = %@", (long)indexPath.section, (long)indexPath.row,
                           NSStringFromCGRect(cell.frame));
            RCStickerSingle *stikerModel = self.stickers[indexPath.row];
            cell.stickerBackgroundView.backgroundColor = HEXCOLOR(0xD8D8D8);
            [self showPreviewViewWithSticker:stikerModel collectionCell:cell indexPath:indexPath];
            self.lastPreviewCell = cell;
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self hidePreviewViewForSticker:nil];
        self.lastPreviewCell.stickerBackgroundView.backgroundColor = [UIColor clearColor];
    } else {
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:pointTouch];
        RCStickerCollectionViewCell *cell =
            (RCStickerCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (indexPath == nil) {
        } else {
            RongStickerLog(@"Section = %ld,Row = %ld,cellframe = %@", (long)indexPath.section, (long)indexPath.row,
                           NSStringFromCGRect(cell.frame));
            RCStickerSingle *stikerModel = self.stickers[indexPath.row];
            [self showPreviewViewWithSticker:stikerModel collectionCell:cell indexPath:indexPath];
            if (self.lastPreviewCell != cell) {
                cell.stickerBackgroundView.backgroundColor = HEXCOLOR(0xD8D8D8);
                self.lastPreviewCell.stickerBackgroundView.backgroundColor = [UIColor clearColor];
            }
            self.lastPreviewCell = cell;
        }
    }
}

- (void)showPreviewViewWithSticker:(RCStickerSingle *)stickerModel
                    collectionCell:(RCStickerCollectionViewCell *)collectionCell
                         indexPath:(NSIndexPath *)indexPath {
    if (!stickerModel) {
        return;
    }
    self.stickerPreviewView.stickerModel = stickerModel;
    self.stickerPreviewView.packageId = self.packageId;
    UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
    CGRect collectionViewWindowFrame =
        [collectionCell.thumbImageView convertRect:collectionCell.thumbImageView.bounds toView:window];
    CGRect stickerPreviewViewFrame = CGRectMake(0, 0, 0, 0);
    switch (indexPath.row) {
    case 0:
    case 4:
        self.stickerPreviewView.previewPosition = RCStickerPreviewPositionLeft;
        stickerPreviewViewFrame =
            CGRectMake(CGRectGetWidth(collectionCell.thumbImageView.frame) / 2,
                       collectionViewWindowFrame.origin.y - RCStickerPreviewBottomInset - RCStickerPreviewViewHeight,
                       RCStickerPreviewViewWidth, RCStickerPreviewViewHeight);
        break;
    case 1:
    case 2:
    case 5:
    case 6:
        self.stickerPreviewView.previewPosition = RCStickerPreviewPositionCenter;
        stickerPreviewViewFrame =
            CGRectMake(CGRectGetMidX(collectionCell.frame) - RCStickerPreviewViewWidth / 2,
                       collectionViewWindowFrame.origin.y - RCStickerPreviewBottomInset - RCStickerPreviewViewHeight,
                       RCStickerPreviewViewWidth, RCStickerPreviewViewHeight);
        break;
    case 3:
    case 7:
        self.stickerPreviewView.previewPosition = RCStickerPreviewPositionRight;
        stickerPreviewViewFrame =
            CGRectMake(CGRectGetMaxX(collectionCell.frame) - RCStickerPreviewViewWidth -
                           CGRectGetMinX(collectionCell.thumbImageView.frame),
                       collectionViewWindowFrame.origin.y - RCStickerPreviewBottomInset - RCStickerPreviewViewHeight,
                       RCStickerPreviewViewWidth, RCStickerPreviewViewHeight);
        break;
    }

    self.stickerPreviewView.frame = stickerPreviewViewFrame;
    [window addSubview:self.stickerPreviewView];
}

- (void)hidePreviewViewForSticker:(RCStickerSingle *)sticker {
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self.stickerPreviewView removeFromSuperview];
                     }];
}
#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.stickers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCStickerSingle *model = self.stickers[indexPath.row];
    RCStickerCollectionViewCell *cell =
        [_collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[RCStickerCollectionViewCell alloc] init];
    }
    [cell configWithModel:model packageId:self.packageId];
    return cell;
}

#pragma mark - UICollectionViewDelegate

// 选中item
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    RCStickerSingle *model = self.stickers[indexPath.row];
    RCStickerMessage *stickerMsg = [RCStickerMessage messageWithPackageId:self.packageId
                                                                stickerId:model.stickerId
                                                                   digest:model.digest
                                                                    width:model.width
                                                                   height:model.height];
    [[RCIM sharedRCIM] sendMessage:[RCStickerModule sharedModule].conversationType
                          targetId:[RCStickerModule sharedModule].currentTargetId
                           content:stickerMsg
                       pushContent:nil
                          pushData:nil
                           success:nil
                             error:nil];
}

// 长按item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                                      layout:(UICollectionViewLayout *)collectionViewLayout
    minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return  (self.frame.size.width - 4 * 60 - 27 * 2-1) / 3;
}

#pragma mark - Notification
- (void)registerNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(didChangeStatusBarFrameNotification)
        name:UIApplicationDidChangeStatusBarFrameNotification
      object:nil];
}

- (void)didChangeStatusBarFrameNotification {
    [self reloadCollectView];
}

#pragma mark - Private
- (void)reloadCollectView {
    if (self.collectionView.frame.size.width != ScreenWidth) {
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.frame = CGRectMake(0, 0, ScreenWidth, 186);
                             self.collectionView.frame = self.frame;
                             [self.collectionView reloadData];
                         }];
    }
}

#pragma mark - Lazy load
- (RCBaseCollectionView *)collectionView {
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = (CGSize){60, 60 + 22};
        flowLayout.sectionInset = UIEdgeInsetsMake(6, 27, 6, 27);
        flowLayout.minimumLineSpacing = 0;
        // -1 是为了解决iphone 14 pro max的 间距问题
        flowLayout.minimumInteritemSpacing = (self.frame.size.width - 4 * 60 - 27 * 2-1) / 3;
        _collectionView = [[RCBaseCollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x1c1c1c);
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.scrollEnabled = NO;
        [_collectionView registerClass:[RCStickerCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
    }
    return _collectionView;
}

@end
