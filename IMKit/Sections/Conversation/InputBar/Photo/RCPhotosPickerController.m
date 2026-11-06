//
//  RCPhotosPickerController.m
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/18.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>

#import "RCPhotosPickerController.h"
#import "RCAssetModel.h"
#import "RCKitCommonDefine.h"
#import "RCPhotoPickerCollectCell.h"
#import "RCPhotoPreviewCollectionViewController.h"
#import "RCKitConfig.h"
#import "RCAlertView.h"
#import "RCMBProgressHUD.h"
#import "RCBaseButton.h"

static NSString *const reuseIdentifier = @"Cell";

@interface RCPhotosPickerController () <UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver,RCPhotoPickerCollectCellDelegate>
@property (nonatomic, strong) NSMutableArray<RCAssetModel *> *selectedAssets;

@property (nonatomic, strong) UIView *toolBar;
@property (nonatomic, strong) RCBaseButton *previewBtn;
@property (nonatomic, strong) RCBaseButton *btnSend;
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
        self.collectionView.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x000000");
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

+ (instancetype)imagePickerViewController {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = 4;
    flowLayout.minimumInteritemSpacing = 4;
    flowLayout.sectionInset = UIEdgeInsetsMake(4, 4, 1, 4);
    if (@available(iOS 11.0, *)) {
        flowLayout.sectionInsetReference = UICollectionViewFlowLayoutSectionInsetFromSafeArea;
    }
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
    self.collectionView.alpha = self.disableFirstAppear?1:0;
    [self.collectionView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xF3F6F9", @"0x191A1F");
    self.collectionView.backgroundColor = RCDynamicColor(@"common_background_color", @"0xFFFFFF", @"0x2D2D32");
    self.previousPreheatRect = CGRectZero;
    
    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.extendedLayoutIncludesOpaqueBars = YES;
    }
    [self.collectionView registerClass:[RCPhotoPickerCollectCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    [self setNaviItem];
    [self createTopView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    UIEdgeInsets safeInsets = UIEdgeInsetsZero;
    UIEdgeInsets contentInsets = self.collectionView.contentInset;
    if (@available(iOS 11.0, *)) {
        safeInsets = self.collectionView.safeAreaInsets;
        contentInsets = self.collectionView.adjustedContentInset;
    }
    // Flow layout 同时遵守安全区和内容边距，四列宽度使用相同的有效边界。
    CGFloat leftInset = MAX(safeInsets.left + layout.sectionInset.left, contentInsets.left);
    CGFloat rightInset = MAX(safeInsets.right + layout.sectionInset.right, contentInsets.right);
    CGFloat width = self.collectionView.bounds.size.width - leftInset - rightInset;
    CGFloat itemWidth = floor((width - layout.minimumInteritemSpacing * 3) / 4);
    if (itemWidth <= 0) {
        return;
    }
    CGSize itemSize = CGSizeMake(itemWidth, itemWidth);
    CGSize footerSize = CGSizeMake(width, 49);
    if (!CGSizeEqualToSize(layout.itemSize, itemSize) || !CGSizeEqualToSize(layout.footerReferenceSize, footerSize)) {
        layout.itemSize = itemSize;
        layout.footerReferenceSize = footerSize;
        [layout invalidateLayout];
    }
    CGFloat scale = self.collectionView.traitCollection.displayScale;
    CGSize thumbnailSize = CGSizeMake(itemWidth * scale, itemWidth * scale);
    if (!CGSizeEqualToSize(self.thumbnailSize, thumbnailSize)) {
        [self.cachingImageManager stopCachingImagesForAllAssets];
        self.thumbnailSize = thumbnailSize;
        self.previousPreheatRect = CGRectZero;
        [self updateCachedAssets];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateCachedAssets];
    
    if (!self.disableFirstAppear) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGSize size = self.collectionView.frame.size;
            CGSize contentSize = self.collectionView.contentSize;
            CGRect frame = CGRectMake(0, MAX(contentSize.height - size.height, 0), size.width, size.height);
            [self.collectionView scrollRectToVisible:frame animated:NO];
            [UIView animateWithDuration:0.1 animations:^{
                self.collectionView.alpha = 1;
            }];
        });
        self.disableFirstAppear = YES;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.cachingImageManager stopCachingImagesForAllAssets];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
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
    [previewController
     setFinishPreviewAndBackPhotosPicker:^(NSMutableArray *selectArr, NSArray *assetPhotos, BOOL isFull) {
        
        self.selectedAssets = selectArr;
        self.assetArray = assetPhotos.mutableCopy;
        self.isFull = isFull;
        [self setButtonEnable];
        [self.collectionView reloadData];
    }];
    [previewController setFinishiPreviewAndSendImage:^(NSArray *selectArr, BOOL isFull) {
        self.sendPhotosBlock(selectArr, isFull);
    }];
    [self.navigationController pushViewController:previewController animated:YES];
}


- (void)checkDownloadFailFromiCloud:(RCAssetModel *)model block:(void(^)(BOOL downloadFailFromiCloud))block {
    // 尝试获取大图或者视频，检查是否能获取
    model.isDownloadFailFromiCloud = NO;
    void(^callback)(BOOL) = ^(BOOL result) {
        model.isDownloadFailFromiCloud = result;
        if (block) block(result);
    };
    void(^progressHandler)(double, NSError *, BOOL *, NSDictionary *) = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_main_async_safe(^{
            if(progress < 1 && !error && !self.progressHUD) {
                self.progressHUD = [RCMBProgressHUD showHUDAddedTo:self.view animated:YES];
            }
        });
    };
    if (model.mediaType == PHAssetMediaTypeImage) {
        [[RCAssetHelper shareAssetHelper] getOriginImageDataWithAsset:model result:^(NSData *photo, NSDictionary *info, RCAssetModel *assetModel) {
            dispatch_main_async_safe(^{
                if(self.progressHUD) {
                    [self.progressHUD hideAnimated:YES afterDelay:0.5];
                    self.progressHUD = nil;
                }
                callback(!photo);
            });
        } progressHandler:progressHandler];
    } else if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        [[RCAssetHelper shareAssetHelper] getOriginVideoWithAsset:model.asset result:^(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier) {
            dispatch_main_async_safe(^{
                if(self.progressHUD) {
                    [self.progressHUD hideAnimated:YES afterDelay:0.5];
                    self.progressHUD = nil;
                }
                model.avAsset = avAsset;
                callback(!avAsset);
            });
        } progressHandler:progressHandler];
    } else {
        callback(YES);
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
    [previewController
     setFinishPreviewAndBackPhotosPicker:^(NSMutableArray *selectArr, NSArray *assetPhotos, BOOL isFull) {
        self.selectedAssets = selectArr;
        [self setButtonEnable];
        self.assetArray = assetPhotos.mutableCopy;
        self.isFull = isFull;
        [self.collectionView reloadData];
    }];
    [previewController setFinishiPreviewAndSendImage:^(NSArray *selectArr, BOOL isFull) {
        self.sendPhotosBlock(selectArr, isFull);
    }];
    [self.navigationController pushViewController:previewController animated:YES];
}

#pragma mark - Private Methods
- (BOOL)cellCanChangeSelectedState:(RCAssetModel *)assetModel {
    if (!assetModel.isSelect) {
        if (self.selectedAssets.count >= 9) {
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"Max_Selected_Photos") cancelTitle:RCLocalizedString(@"i_know_it") inViewController:self];
            return NO;
        }
        
        if (assetModel.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
            CGFloat durationLimit = RCKitConfigCenter.message.uploadVideoDurationLimit;
            if (round(assetModel.duration) > durationLimit) {
                NSString *localizedString = durationLimit < 60 ? RCLocalizedString(@"Selected_Video_Warning_fmt_second") : RCLocalizedString(@"Selected_Video_Warning_fmt");
                CGFloat limit = durationLimit < 60 ? durationLimit : (durationLimit / 60.0f);
                NSString *format = durationLimit < 60 ? @"%.0f" : @"%.1f";
                NSString *text = [NSString stringWithFormat:format, limit];
                NSString *msg = [NSString stringWithFormat:localizedString, text];
                [self showAlertWithMessage:msg];
                return NO;
            }
        } else if ([[assetModel.asset valueForKey:@"uniformTypeIdentifier"]
                    isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
            if (assetModel.imageSize > [[RCCoreClient sharedCoreClient] getGIFLimitSize] * 1024) {
                [self showAlertWithMessage:RCLocalizedString(@"GIFAboveMaxSize")];
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
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    UIColor *color = RCDynamicResourceColor(@"primary_color", @"photoPicker_cancel", @"0x0099ff");
    [btn setTitleColor:color forState:UIControlStateNormal];
    [btn addTarget:self
            action:@selector(dismissCurrentModelViewController)
  forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:RCLocalizedString(@"Cancel") forState:UIControlStateNormal];
    [btn sizeToFit];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    [self.navigationItem setRightBarButtonItem:rightItem];
}

- (void)createTopView {
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    _toolBar.translatesAutoresizingMaskIntoConstraints = NO;
    _toolBar.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xF3F6F9", @"0x191A1F");
    [self.view addSubview:_toolBar];
    NSLayoutYAxisAnchor *bottomAnchor = self.view.bottomAnchor;
    id toolbarLayoutItem = _toolBar;
    if (@available(iOS 11.0, *)) {
        bottomAnchor = self.view.safeAreaLayoutGuide.bottomAnchor;
        toolbarLayoutItem = _toolBar.safeAreaLayoutGuide;
    }
    // 背景延伸到底边，按钮区域保持在当前页面的安全区内。
    [NSLayoutConstraint activateConstraints:@[
        [_toolBar.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [_toolBar.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [_toolBar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_toolBar.topAnchor constraintEqualToAnchor:bottomAnchor constant:-49]
    ]];
    
    // add button for bottom bar
    _btnSend = [[RCBaseButton alloc] init];
    _btnSend.layer.cornerRadius = 5.0f;
    _btnSend.contentEdgeInsets = UIEdgeInsetsMake(5, 12, 5, 12);

    [_btnSend setTitle:RCLocalizedString(@"Send") forState:UIControlStateNormal];
    [_btnSend addTarget:self action:@selector(btnSendCliced:) forControlEvents:UIControlEventTouchUpInside];
    _btnSend.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_toolBar addSubview:_btnSend];
    
    _previewBtn = [[RCBaseButton alloc] init];
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
                                                                toItem:toolbarLayoutItem
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                              constant:-10]];
        
        [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_btnSend
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:toolbarLayoutItem
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
                                                                toItem:toolbarLayoutItem
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                              constant:-10]];
        
        [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_previewBtn
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:toolbarLayoutItem
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1
                                                              constant:10]];
    }
    
    [_btnSend setTitleColor:RCDynamicResourceColor(@"control_title_white_color",@"photoPicker_send_disable", @"0x9fcdfd")
                   forState:UIControlStateDisabled];
    [_btnSend setTitleColor:RCDynamicResourceColor(@"control_title_white_color",@"photoPicker_send_normal", @"0x0099ff")
                   forState:UIControlStateNormal];
    [_btnSend setBackgroundColor:RCDynamicColor(@"disabled_color", @"0x00000000", @"0x00000000")];
    [self.btnSend setEnabled:NO];
    [_previewBtn setTitleColor:RCDynamicResourceColor(@"text_secondary_color", @"photoPreview_send_disable", @"0x959595")
                      forState:UIControlStateDisabled];
    UIColor *titleColor = nil;
    if ([RCKitUtility isTraditionInnerThemes]) {
        titleColor = [RCKitUtility
                      generateDynamicColor:RCResourceColor(@"photoPicker_preview_normal", @"0x000000")
                      darkColor:RCResourceColor(@"photoPicker_preview_normal_dark",
                                                @"0xffffff")];
    } else {
        titleColor = RCDynamicColor(@"primary_color", @"0x000000", @"0xffffff");
    }
    [_previewBtn setTitleColor:titleColor forState:UIControlStateNormal];
    [self.previewBtn setEnabled:NO];
}

- (void)setButtonEnable {
    if (self.selectedAssets.count > 0) {
        [self.btnSend setEnabled:YES];
        [self.btnSend setBackgroundColor:RCDynamicColor(@"primary_color", @"0x00000000", @"0x00000000")];
        [self.previewBtn setEnabled:YES];
    } else {
        [self.btnSend setEnabled:NO];
        [self.btnSend setBackgroundColor:RCDynamicColor(@"disabled_color", @"0x00000000", @"0x00000000")];
        [self.previewBtn setEnabled:NO];
    }
}

// show  alert
- (void)showAlertWithMessage:(NSString *)message {
    [RCAlertView showAlertController:nil message:message cancelTitle:RCLocalizedString(@"Confirm") inViewController:self];
}

- (void)_updateBottomSendImageCountButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.selectedAssets.count && self.toolBar) {
            [self.btnSend setTitle:[NSString stringWithFormat:@"%@ (%lu)",RCLocalizedString(@"Send"), (unsigned long)self.selectedAssets.count] forState:(UIControlStateNormal)];
        } else {
            [self.btnSend setTitle:RCLocalizedString(@"Send") forState:(UIControlStateNormal)];
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
    
    CGSize thumbnailSize = self.thumbnailSize;
    if (thumbnailSize.width <= 0 || thumbnailSize.height <= 0) {
        return;
    }
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
    NSMutableArray *assets = [[NSMutableArray alloc] initWithCapacity:50];
    [rects enumerateObjectsUsingBlock:^(NSValue *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        CGRect rect = [obj CGRectValue];
        NSArray<UICollectionViewLayoutAttributes *> *attribtutes =
        [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
        [attribtutes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *_Nonnull obj, NSUInteger idx,
                                                  BOOL *_Nonnull stop) {
            if (obj.indexPath.item < self.assetArray.count) {
                RCAssetModel *model = [self.assetArray objectAtIndex:obj.indexPath.item];
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
