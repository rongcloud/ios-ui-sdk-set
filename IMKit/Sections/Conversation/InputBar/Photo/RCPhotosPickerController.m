//
//  RCPhotosPickerController.m
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/18.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCPhotosPickerController.h"
#import "RCAssetModel.h"
#import "RCKitCommonDefine.h"
#import "RCPhotoPickerCollectCell.h"
#import "RCPhotoPreviewCollectionViewController.h"
#import "RCExtensionService.h"
#import "RCKitConfig.h"
#import "RCAlertView.h"
#import "RCKitConfig.h"
#import "RCMBProgressHUD.h"


#define WIDTH ((SCREEN_WIDTH - 20) / 4)
#define SIZE CGSizeMake(WIDTH, WIDTH)

static NSString *const reuseIdentifier = @"Cell";

@interface RCPhotosPickerController () <UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver,RCPhotoPickerCollectCellDelegate>
@property (nonatomic, strong) NSMutableArray<RCAssetModel *> *selectedAssets;

@property (nonatomic, strong) UIView *toolBar;
@property (nonatomic, strong) UIButton *previewBtn;
@property (nonatomic, strong) UIButton *btnSend;
@property (nonatomic, assign) BOOL isFull;
@property (nonatomic, assign) BOOL disableFirstAppear;
@property (nonatomic, assign) BOOL isLoad;
@property (nonatomic, strong) PHCachingImageManager *cachingImageManager;
@property (nonatomic, assign) CGRect previousPreheatRect;
@property (nonatomic, assign) CGSize thumbnailSize;

@property (nonatomic, strong) RCMBProgressHUD *progressHUD;

@end

@implementation RCPhotosPickerController

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.assetArray = [NSMutableArray new];
        self.selectedAssets = [NSMutableArray new];
        self.collectionView.backgroundColor = RCDYCOLOR(0xffffff, 0x000000);
        if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        }
    }
    return self;
}

+ (instancetype)imagePickerViewController {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.itemSize = CGSizeMake(WIDTH, WIDTH);
    flowLayout.minimumLineSpacing = 4;
    flowLayout.minimumInteritemSpacing = 4;
    flowLayout.sectionInset = UIEdgeInsetsMake(4, 4, 1, 4);
    flowLayout.footerReferenceSize = CGSizeMake(SCREEN_WIDTH, 49);
    RCPhotosPickerController *pickerViewController =
        [[RCPhotosPickerController alloc] initWithCollectionViewLayout:flowLayout];
    return pickerViewController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    [self _updateBottomSendImageCountButton];
    if(self.isLoad) {
        return;
    }
    __weak RCPhotosPickerController *weakSelf = self;
    [[RCAssetHelper shareAssetHelper]
        getPhotosOfGroup:self.currentAsset
                 results:^(NSArray<RCAssetModel *> *photos) {
        [weakSelf updateDataSource:photos];
     }];
}

- (void)updateDataSource:(NSArray<RCAssetModel *> *)photos {
     self.assetArray = [NSMutableArray arrayWithArray:photos];
     self.isLoad = YES;
     for (int i = 0; i < photos.count; i++) {

         for (int j = 0; j < self.selectedAssets.count; j++) {
             if ([self.selectedAssets[j].asset isEqual:photos[i].asset]) {
                 self.assetArray[i].isSelect = YES;
                 break;
             }
         }
     }
     [self.collectionView reloadData];
     if (!self.disableFirstAppear) {
         [self.collectionView
             setContentOffset:CGPointMake(0, (self.count / 4) * (WIDTH + 4))];
         self.disableFirstAppear = YES;
     }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.previousPreheatRect = CGRectZero;
    CGFloat scale = [UIScreen mainScreen].scale;
    self.thumbnailSize = (CGSize){WIDTH * scale, WIDTH * scale};

    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.extendedLayoutIncludesOpaqueBars = YES;
    }
    [self.collectionView registerClass:[RCPhotoPickerCollectCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    [self setNaviItem];
    [self createTopView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGRect statusBarRect = [[UIApplication sharedApplication] statusBarFrame];
    int shouldBeSubtractionHeight = 0;
    if (statusBarRect.size.height == 40) {
        shouldBeSubtractionHeight = 20;
    }
    CGFloat height = 49 + [self getSafeAreaExtraBottomHeight];
    _toolBar.frame = CGRectMake(0, SCREEN_HEIGHT - shouldBeSubtractionHeight - height, SCREEN_WIDTH, height);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateCachedAssets];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.cachingImageManager stopCachingImagesForAllAssets];
}

- (void)dealloc {
    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateCachedAssets];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCPhotoPickerCollectCell *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

    RCAssetModel *model = self.assetArray[indexPath.row];
    model.index = indexPath.row;

    [cell configPickerCellWithItem:self.assetArray[indexPath.row] delegate:self];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    RCAssetModel *model = self.assetArray[indexPath.row];
    if(![model.asset isKindOfClass:PHAsset.class]) {
        return;
    }
    
    RCPhotoPickerCollectCell *pickerCell = nil;
    if ([cell isKindOfClass:RCPhotoPickerCollectCell.class]) {
        pickerCell = (RCPhotoPickerCollectCell *)cell;
    }
    
    PHAsset *phasset = (PHAsset *)model.asset;
    if (phasset.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        if (!model.avAsset) {
            [[RCAssetHelper shareAssetHelper] getOriginVideoWithAsset:phasset result:^(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier) {
                if (!avAsset) {
                    return;
                }
                if (![pickerCell.representedAssetIdentifier isEqualToString:imageIdentifier]) {
                    return;
                }
                model.avAsset = avAsset;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (indexPath.row < self.assetArray.count) {
                        [collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
                    }
                });
            } progressHandler:nil];
        } else {
            RCPhotoPickerCollectCell *pickerCell = (RCPhotoPickerCollectCell *)cell;
            [pickerCell configPickerCellWithItem:model delegate:self];
        }
    }
}
#pragma mark - RCPhotoPickerCollectCellDelegate
/// 是否可以变成选中状态
- (BOOL)canChangeSelectedState:(RCAssetModel *)asset {
    return [self cellCanChangeSelectedState:asset];
}

- (void)downloadFailFromiCloud {
    NSString *msg = RCLocalizedString(@"DownloadFailFromiCloud");
    [self showAlertWithMessage:msg];
}

- (void)didChangeSelectedState:(BOOL)selected model:(RCAssetModel *)asset {
    [self cellDidChangeSelectedState:asset selected:selected];
}

- (void)didTapPickerCollectCell:(RCAssetModel *)selectModel {
    __weak typeof(self) weakSelf = self;
    [self checkDownloadFailFromiCloud:selectModel block:^(BOOL downloadFailFromiCloud) {
        [weakSelf doTapPhotoImageView:selectModel isDownloadFail:downloadFailFromiCloud];
    }];
}

- (void)enterPreviewCollectionViewController:(RCAssetModel *)selectModel {
    if(!selectModel) {
        return;
    }
    
    RCPhotoPreviewCollectionViewController *previewController =
        [RCPhotoPreviewCollectionViewController imagePickerViewController];
    previewController.isFull = self.isFull;
    [previewController previewPhotosWithSelectArr:self.selectedAssets
                                     allPhotosArr:self.assetArray
                                     currentIndex:selectModel.index
                                 accordToIsSelect:NO];
    __weak typeof(self) weakself = self;
    [previewController
        setFinishPreviewAndBackPhotosPicker:^(NSMutableArray *selectArr, NSArray *assetPhotos, BOOL isFull) {

            weakself.selectedAssets = selectArr;
            weakself.assetArray = assetPhotos.mutableCopy;
            weakself.isFull = isFull;
            [weakself setButtonEnable];
            [weakself.collectionView reloadData];
        }];
    [previewController setFinishiPreviewAndSendImage:^(NSArray *selectArr, BOOL isFull) {
        weakself.sendPhotosBlock(selectArr, isFull);
    }];
    [self.navigationController pushViewController:previewController animated:YES];
}


- (void)checkDownloadFailFromiCloud:(RCAssetModel *)model block:(void(^)(BOOL downloadFailFromiCloud))block {
    __weak typeof(self) weakself = self;
    // 尝试获取大图或者视频，检查是否能获取
    model.isDownloadFailFromiCloud = NO;
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        [[RCAssetHelper shareAssetHelper] getOriginVideoWithAsset:model.asset result:^(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier) {
            dispatch_main_async_safe(^{
                if(weakself.progressHUD) {
                    [weakself.progressHUD hideAnimated:YES afterDelay:0.5];
                    weakself.progressHUD = nil;
                }

                BOOL isDownloadFail = !avAsset ? YES : NO;
                model.isDownloadFailFromiCloud = isDownloadFail;
                if(block) {
                    block(isDownloadFail);
                }
            });
        } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            dispatch_main_async_safe(^{
                if(progress < 1 && !error && !weakself.progressHUD) {
                    weakself.progressHUD = [RCMBProgressHUD showHUDAddedTo:weakself.view animated:YES];
                }
            });
        }];

    }else {
        [[RCAssetHelper shareAssetHelper] getOriginImageDataWithAsset:model result:^(NSData *photo, NSDictionary *info, RCAssetModel *assetModel) {
            dispatch_main_async_safe(^{
                if(weakself.progressHUD) {
                    [weakself.progressHUD hideAnimated:YES afterDelay:0.5];
                    weakself.progressHUD = nil;
                }

                BOOL isDownloadFail = !photo ? YES : NO;
                model.isDownloadFailFromiCloud = isDownloadFail;
                if(block) {
                    block(isDownloadFail);
                }
            });
        } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            dispatch_main_async_safe(^{
                if(progress < 1 && !error && !weakself.progressHUD) {
                    weakself.progressHUD = [RCMBProgressHUD showHUDAddedTo:weakself.view animated:YES];
                }
            });
        }];
    }
}


- (void)doTapPhotoImageView:(RCAssetModel *)model isDownloadFail:(BOOL)isDownloadFail {
    if(isDownloadFail|| [model isVideoAssetInvalid]) {
        [self downloadFailFromiCloud];
        return;
    }
    [self enterPreviewCollectionViewController:model];
}

#pragma mark - Target Action

- (void)dismissCurrentModelViewController {
    [self dismissViewControllerAnimated:YES
                             completion:^{

                             }];
}

- (void)btnSendCliced:(UIButton *)sender {
    self.sendPhotosBlock(self.selectedAssets, self.isFull);
}

- (void)previewBtnCliced:(UIButton *)sender {
    RCPhotoPreviewCollectionViewController *previewController =
        [RCPhotoPreviewCollectionViewController imagePickerViewController];
    previewController.isFull = self.isFull;
    [previewController previewPhotosWithSelectArr:self.selectedAssets
                                     allPhotosArr:self.assetArray
                                     currentIndex:0
                                 accordToIsSelect:YES];
    __weak typeof(self) weakself = self;
    [previewController
        setFinishPreviewAndBackPhotosPicker:^(NSMutableArray *selectArr, NSArray *assetPhotos, BOOL isFull) {
            weakself.selectedAssets = selectArr;
            [weakself setButtonEnable];
            weakself.assetArray = assetPhotos.mutableCopy;
            weakself.isFull = isFull;
            [weakself.collectionView reloadData];
        }];
    [previewController setFinishiPreviewAndSendImage:^(NSArray *selectArr, BOOL isFull) {
        weakself.sendPhotosBlock(selectArr, isFull);
    }];
    [self.navigationController pushViewController:previewController animated:YES];
}

#pragma mark - Private Methods
- (BOOL)cellCanChangeSelectedState:(RCAssetModel *)asset {
    if (!asset.isSelect) {
        if (self.selectedAssets.count >= 9) {
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"Max_Selected_Photos") cancelTitle:RCLocalizedString(@"i_know_it") inViewController:self];
            return NO;
        }

        if (asset.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
            CGFloat durationLimit = RCKitConfigCenter.message.uploadVideoDurationLimit;
            if (round(asset.duration) > durationLimit) {
                CGFloat minutes = durationLimit / 60.0f;
                NSString *minutesText = [NSString stringWithFormat:@"%.2g", minutes];
                NSString *msg = [NSString
                    stringWithFormat:RCLocalizedString(@"Selected_Video_Warning_fmt"), minutesText];
                [self showAlertWithMessage:msg];
                return NO;
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)cellDidChangeSelectedState:(RCAssetModel *)asset selected:(BOOL)selected{
    if (selected) {
        asset.isSelect = YES;
        BOOL isNotContains = YES;
        for (int i = 0; i < self.selectedAssets.count; i++) {
            if ([self.selectedAssets[i].asset isEqual:asset.asset]) {
                isNotContains = NO;
                break;
            }
        }
        if (isNotContains) {
            [self.selectedAssets addObject:asset];
        }

    } else {
        asset.isSelect = NO;
        for (int i = 0; i < self.selectedAssets.count; i++) {
            if ([self.selectedAssets[i].asset isEqual:asset.asset]) {
                [self.selectedAssets removeObject:self.selectedAssets[i]];
                break;
            }
        }
    }
    for (RCAssetModel *model in self.assetArray) {
        if (model.index == asset.index) {
            model.isSelect = selected;
            break;
        }
    }
    
    [self setButtonEnable];
    [self _updateBottomSendImageCountButton];
}

- (void)setNaviItem{
    UIView *rightBarView = [[UIView alloc] init];
    rightBarView.frame = CGRectMake(0, 0, 80, 40);
    UILabel *doneTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
    doneTitleLabel.text = RCLocalizedString(@"Cancel");
    doneTitleLabel.textAlignment = NSTextAlignmentRight;
    doneTitleLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    doneTitleLabel.textColor = [RCKitUtility
        generateDynamicColor:RCResourceColor(@"photoPicker_cancel", @"0x0099ff")
                   darkColor:RCResourceColor(@"photoPicker_cancel", @"0x0099ff")];
    [rightBarView addSubview:doneTitleLabel];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissCurrentModelViewController)];
    [rightBarView addGestureRecognizer:tap];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightBarView];
    [self.navigationItem setRightBarButtonItem:rightItem];
}

- (void)createTopView {
    CGFloat height = 49 + [self getSafeAreaExtraBottomHeight];
    _toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - height, SCREEN_WIDTH, height)];
    _toolBar.backgroundColor = RCDYCOLOR(0xffffff, 0x000000);
    [self.view addSubview:_toolBar];

    // add button for bottom bar
    _btnSend = [[UIButton alloc] init];
    [_btnSend setTitle:RCLocalizedString(@"Send") forState:UIControlStateNormal];
    [_btnSend addTarget:self action:@selector(btnSendCliced:) forControlEvents:UIControlEventTouchUpInside];
    _btnSend.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_toolBar addSubview:_btnSend];

    _previewBtn = [[UIButton alloc] init];
    [_previewBtn setTitle:RCLocalizedString(@"Preview") forState:UIControlStateNormal];
    _previewBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_previewBtn addTarget:self action:@selector(previewBtnCliced:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar addSubview:_previewBtn];

    [_btnSend setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_previewBtn setTranslatesAutoresizingMaskIntoConstraints:NO];

    if ([RCKitUtility isRTL]) {
        [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_previewBtn(30)]"
                                                                         options:kNilOptions
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(_previewBtn)]];
        [_toolBar
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_btnSend(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_btnSend)]];
        [_toolBar
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_btnSend]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_btnSend)]];
        [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_previewBtn
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_toolBar
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                              constant:-10]];

        [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_btnSend
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_toolBar
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1
                                                              constant:10]];
    } else {
        [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_btnSend(30)]"
                                                                         options:kNilOptions
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(_btnSend)]];

        [_toolBar
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_previewBtn(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_previewBtn)]];
        [_toolBar
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_previewBtn]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_previewBtn)]];
        [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_btnSend
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_toolBar
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                              constant:-10]];

        [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_previewBtn
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_toolBar
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1
                                                              constant:10]];
    }

    [_btnSend setTitleColor:RCResourceColor(@"photoPicker_send_disable", @"0x9fcdfd")
                   forState:UIControlStateDisabled];
    [_btnSend setTitleColor:RCResourceColor(@"photoPicker_send_normal", @"0x0099ff")
                   forState:UIControlStateNormal];
    [self.btnSend setEnabled:NO];
    [_previewBtn setTitleColor:RCResourceColor(@"photoPicker_preview_disable", @"0x959595")
                      forState:UIControlStateDisabled];
    [_previewBtn
        setTitleColor:[RCKitUtility
                          generateDynamicColor:RCResourceColor(@"photoPicker_preview_normal", @"0x000000")
                                     darkColor:RCResourceColor(@"photoPicker_preview_normal_dark",
                                                                        @"0xffffff")]
             forState:UIControlStateNormal];
    [self.previewBtn setEnabled:NO];
}

- (void)setButtonEnable {
    if (self.selectedAssets.count > 0) {
        [self.btnSend setEnabled:YES];
        [self.previewBtn setEnabled:YES];
    } else {
        [self.btnSend setEnabled:NO];
        [self.previewBtn setEnabled:NO];
    }
}

// show  alert
- (void)showAlertWithMessage:(NSString *)message {
    [RCAlertView showAlertController:nil message:message cancelTitle:RCLocalizedString(@"Confirm") inViewController:self];
}

- (void)_updateBottomSendImageCountButton {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.selectedAssets.count && weakSelf.toolBar) {
            [weakSelf.btnSend setTitle:[NSString stringWithFormat:@"%@ (%lu)",RCLocalizedString(@"Send"), (unsigned long)weakSelf.selectedAssets.count] forState:(UIControlStateNormal)];
        } else {
            [weakSelf.btnSend setTitle:RCLocalizedString(@"Send") forState:(UIControlStateNormal)];
        }
    });
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // Photos may call this method on a background queue;
    // switch to the main queue to update the UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        // Check for changes to the displayed album itself
        // (its existence and metadata, not its member assets).
        PHFetchResultChangeDetails *albumChanges = [changeInstance changeDetailsForFetchResult:self.currentAsset];
        if (albumChanges) {
            self.count = albumChanges.fetchResultAfterChanges.count;
            for (int i = 0; i < albumChanges.insertedObjects.count; i++) {
                if ([albumChanges.insertedObjects[i] isKindOfClass:[PHAsset class]]) {
                    BOOL isContain = NO;
                    BOOL isContainVideo = RCKitConfigCenter.message.isMediaSelectorContainVideo;
                    for (int j = 0; j < self.assetArray.count; j++) {
                        RCAssetModel *assetModel = self.assetArray[j];
                        PHAsset *newAsset = albumChanges.insertedObjects[i];
                        if (!isContainVideo && newAsset.mediaType == PHAssetMediaTypeVideo) {
                            isContain = YES;
                            break;
                        }
                        PHAsset *asset = assetModel.asset;
                        if ([newAsset.localIdentifier isEqualToString:asset.localIdentifier]) {
                            isContain = YES;
                            break;
                        }
                    }
                    if (!isContain) {
                        RCAssetModel *model = [RCAssetModel modelWithAsset:albumChanges.insertedObjects[i]];
                        [self.assetArray addObject:model];
                    }
                }
            }

            [self.collectionView reloadData];
        }

    });
}

- (float)getSafeAreaExtraBottomHeight {
    return [RCKitUtility getWindowSafeAreaInsets].bottom;
}

#pragma mark - Helper
- (void)updateCachedAssets {
    if (!self.isViewLoaded && !self.view.window) {
        return;
    }

    CGRect visibleRect = (CGRect){self.collectionView.contentOffset.x, self.collectionView.contentOffset.y,
                                  self.collectionView.bounds.size.width, self.collectionView.bounds.size.height};
    CGRect preheatRect = CGRectInset(visibleRect, 0, -0.5 * visibleRect.size.height);

    CGFloat delta = fabs(CGRectGetMinY(preheatRect) - CGRectGetMinY(self.previousPreheatRect));
    if (delta < self.collectionView.bounds.size.height / 3) {
        return;
    }

    NSArray<NSValue *> *addedRects = [self addedRectsBetween:self.previousPreheatRect and:preheatRect];
    NSArray<NSValue *> *removedRects = [self removedRectsBetween:self.previousPreheatRect and:preheatRect];
    NSArray<PHAsset *> *addAssets = [self assetsInRects:addedRects];
    NSArray<PHAsset *> *removedAssets = [self assetsInRects:removedRects];

    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.synchronous = NO;
    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
    imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;

    CGFloat screenScale = [UIScreen mainScreen].scale;
    CGSize thumbnailSize = (CGSize){SIZE.width * screenScale, SIZE.height * screenScale};
    [self.cachingImageManager startCachingImagesForAssets:addAssets
                                               targetSize:thumbnailSize
                                              contentMode:PHImageContentModeAspectFill
                                                  options:imageRequestOptions];
    [self.cachingImageManager stopCachingImagesForAssets:removedAssets
                                              targetSize:thumbnailSize
                                             contentMode:PHImageContentModeAspectFill
                                                 options:nil];
    self.previousPreheatRect = preheatRect;
}

- (NSArray<PHAsset *> *)assetsInRects:(NSArray<NSValue *> *)rects {
    __weak typeof(self) weakSelf = self;
    NSMutableArray *assets = [[NSMutableArray alloc] initWithCapacity:50];
    [rects enumerateObjectsUsingBlock:^(NSValue *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        CGRect rect = [obj CGRectValue];
        NSArray<UICollectionViewLayoutAttributes *> *attribtutes =
            [weakSelf.collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
        [attribtutes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *_Nonnull obj, NSUInteger idx,
                                                  BOOL *_Nonnull stop) {
            if (obj.indexPath.item < weakSelf.assetArray.count) {
                RCAssetModel *model = [weakSelf.assetArray objectAtIndex:obj.indexPath.item];
                if ([model.asset isKindOfClass:[PHAsset class]]) {
                    [assets addObject:model.asset];
                }
            }
        }];
    }];
    return [assets copy];
}

- (NSArray<NSValue *> *)addedRectsBetween:(CGRect)old and:(CGRect) new {
    if (CGRectIntersectsRect(old, new)) {
        NSMutableArray *rects = [[NSMutableArray alloc] initWithCapacity:2];
        if (CGRectGetMaxY(new) > CGRectGetMaxY(old)) {
            CGRect rect =
                (CGRect){new.origin.x, CGRectGetMaxY(old), new.size.width, CGRectGetMaxY(new) - CGRectGetMaxY(old)};
            [rects addObject:[NSValue valueWithCGRect:rect]];
        }
        if (CGRectGetMinY(old) > CGRectGetMinY(new)) {
            CGRect rect =
                (CGRect){new.origin.x, CGRectGetMinY(new), new.size.width, CGRectGetMinY(old) - CGRectGetMinY(new)};
            [rects addObject:[NSValue valueWithCGRect:rect]];
        }
        return [rects copy];
    } else {
        return @[ [NSValue valueWithCGRect:new] ];
    }
}

- (NSArray<NSValue *> *)removedRectsBetween:(CGRect)old and:(CGRect) new {
    if (CGRectIntersectsRect(old, new)) {
        NSMutableArray *rects = [[NSMutableArray alloc] initWithCapacity:2];

        if (CGRectGetMaxY(new) < CGRectGetMaxY(old)) {
            CGRect rect =
                (CGRect){new.origin.x, CGRectGetMaxY(new), new.size.width, CGRectGetMaxY(old) - CGRectGetMaxY(new)};
            [rects addObject:[NSValue valueWithCGRect:rect]];
        }
        if (CGRectGetMinY(old) < CGRectGetMinY(new)) {
            CGRect rect =
                (CGRect){new.origin.x, CGRectGetMinY(old), new.size.width, CGRectGetMinY(new) - CGRectGetMinY(old)};
            [rects addObject:[NSValue valueWithCGRect:rect]];
        }
        return [rects copy];
    } else {
        return @[ [NSValue valueWithCGRect:old] ];
    }
}

#pragma mark - Getters and Setters
- (PHCachingImageManager *)cachingImageManager {
    if (!_cachingImageManager) {
        _cachingImageManager = [[PHCachingImageManager alloc] init];
    }
    return _cachingImageManager;
}
@end
