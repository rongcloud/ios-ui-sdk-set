//
//  RCPhotoPreviewCollectionViewController.m
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/17.
//  Copyright © 2016年 张改红. All rights reserved.
//

#import "RCPhotoPreviewCollectionViewController.h"
#import "RCAssetHelper.h"
#import "RCAssetModel.h"
#import "RCKitCommonDefine.h"
#import "RCPhotoPreviewCollectCell.h"
#import "RCPhotoEditorManager.h"
#import "RCVideoPreviewCell.h"
#import <RongIMLib/RongIMLib.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "RCAlertView.h"
#import "RCPhotoPreviewCollectionViewFlowLayout.h"
#import "RCKitConfig.h"

static NSString *const reuseIdentifier = @"Cell";
static NSString *const videoCellReuseIdentifier = @"VideoPreviewCell";

@interface RCPhotoPreviewCollectionViewController () <RCVideoPreviewCellDelegate>
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIButton *selectedButton;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIButton *fullButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, strong) NSMutableArray<RCAssetModel *> *previewPhotosArr;
@property (nonatomic, strong) NSArray<RCAssetModel *> *allPhotosArr;

@property (nonatomic, strong) NSMutableArray<RCAssetModel *> *selectedArr;
@property (nonatomic, strong) NSMutableArray<RCAssetModel *> *selectedVideoArray;
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, copy) NSString *currentAssetIdentifier;

@property (nonatomic, assign) int32_t imageRequestID;

@end

@implementation RCPhotoPreviewCollectionViewController
#pragma mark - Life Cycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.allPhotosArr = [NSArray new];
        self.selectedArr = [NSMutableArray new];
        self.selectedVideoArray = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.collectionView.scrollsToTop = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.contentSize = CGSizeMake(SCREEN_WIDTH * self.previewPhotosArr.count, SCREEN_HEIGHT);
    self.collectionView.pagingEnabled = YES;
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.collectionView addGestureRecognizer:gesture];

    [self.collectionView registerClass:[RCPhotoPreviewCollectCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerClass:RCVideoPreviewCell.class forCellWithReuseIdentifier:videoCellReuseIdentifier];
    [self creatTopView];
    [self createBottomView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imageDidFinishEditting:)
                                                 name:@"onClickEditPictureCompletion"
                                               object:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES];
    // fix: https://admin.rongcloud.cn/ticket/reply/138658?user_id=167777&type=1&action=first
    // iOS14 之后在 viewWillAppear 中调用 scrollToItemAtIndexPath 不生效，原因是：collectionView 在完成布局之前调用 scrollToItemAtIndexPath 是不会执行的。
    // 相关链接：https://www.jianshu.com/p/482703c25fb6 网上的解决方案为，将 scrollToItemAtIndexPath 放在 viewDidLayoutSubviews 中，但是在滚动 collectionView 或者横竖屏切换时也会回调 viewDidLayoutSubviews，导致滚动异常，所以在此处延时 0.1s 进行处理
    if (@available(iOS 14.0, *)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                animated:NO];
        });
    } else {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                            animated:NO];
    }
    [self _updateTopBarStatus];
    _fullButton.selected = self.isFull;
    if (_fullButton.selected) {
        [self updateImageSize];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public Methods
+ (instancetype)imagePickerViewController {
    RCPhotoPreviewCollectionViewFlowLayout *flowLayout = [[RCPhotoPreviewCollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    flowLayout.itemSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    RCPhotoPreviewCollectionViewController *previewViewController =
        [[RCPhotoPreviewCollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
    return previewViewController;
}

- (void)previewPhotosWithSelectArr:(NSMutableArray *)selectedArr
                      allPhotosArr:(NSArray *)allPhotosArr
                      currentIndex:(NSInteger)currentIndex
                  accordToIsSelect:(BOOL)isSelected {
    if (isSelected) {
        _previewPhotosArr = [NSMutableArray arrayWithArray:selectedArr];
    } else {
        _previewPhotosArr = [allPhotosArr mutableCopy];
    }
    _selectedArr = selectedArr;
    _allPhotosArr = allPhotosArr;
    _currentIndex = currentIndex;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.previewPhotosArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.previewPhotosArr.count <= indexPath.row) {
        return nil;
    }
    RCAssetModel *model = self.previewPhotosArr[indexPath.row];
//    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_0 &&
//        [UIView appearance].semanticContentAttribute == UISemanticContentAttributeForceRightToLeft) {
//        /* 测试时 需将 [UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft
//         添加到appdelegete 打包给测试。
//         在阿拉伯语言情况下 界面会设置[UIView appearance].semanticContentAttribute =
//         UISemanticContentAttributeForceRightToLeft(9.0才支持此方法)
//         会导致这个数组取值有问题
//         上一个页面传进来的数组在这个页面会发生错误。数值会倒着取值。所以这个地方把数组反向排列一遍
//         */
//        NSArray *reversePhotoArray = [self.previewPhotosArr reverseObjectEnumerator].allObjects;
//        model = reversePhotoArray[indexPath.row];
//    }
    RCPhotoPreviewCollectCell *cell = nil;
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:videoCellReuseIdentifier forIndexPath:indexPath];
        RCVideoPreviewCell *videoCell = (RCVideoPreviewCell *)cell;
        videoCell.delegate = self;
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
        //    [self _updateTopBarStatus];
        //        __weak typeof(self) weakSelf = self;
        [cell setSingleTap:^{
            //            weakSelf.topView.hidden = !weakSelf.topView.hidden;
            //            weakSelf.bottomView.hidden = weakSelf.topView.hidden;
        }];
    }
    [cell configPreviewCellWithItem:model];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[RCPhotoPreviewCollectCell class]]) {
        [(RCPhotoPreviewCollectCell *)cell resetSubviews];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint offSet = scrollView.contentOffset;
    self.currentIndex = offSet.x / self.view.frame.size.width;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self _updateTopBarStatus];
    [self _updateFullButton];
    [self _updateEditButton];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    RCAssetModel *model = self.previewPhotosArr[self.currentIndex];
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        RCVideoPreviewCell *videoCell = (RCVideoPreviewCell *)[self.collectionView
            cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
        [videoCell stop];
    }
}

#pragma mark - RCPictureEditCompleteDelegate

- (void)imageDidFinishEditting:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.previewPhotosArr.count <= self.currentIndex) {
            return;
        }
        UIImage *editedImage = notification.object;
        RCAssetModel *model = self.previewPhotosArr[_currentIndex];
        model.originImageData = UIImageJPEGRepresentation(editedImage, 1.0);
        model.previewImage = editedImage;
        model.thumbnailImage = editedImage;
        [[RCPhotoEditorManager sharedManager]
             addEditPhoto:[[RCAssetHelper shareAssetHelper] getAssetIdentifier:model.asset]
            andAssetModel:model];
        [self.previewPhotosArr replaceObjectAtIndex:_currentIndex withObject:model];
        NSIndexPath *index = [NSIndexPath indexPathForRow:_currentIndex inSection:0];
        [self.collectionView reloadItemsAtIndexPaths:@[ index ]];

    });
}

#pragma mark - RCVideoPreviewCellDelegate

- (void)sendPlayActionInCell:(UICollectionViewCell *)cell {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    RCAssetModel *model = self.previewPhotosArr[indexPath.item];
    RCVideoPreviewCell *videocell = (RCVideoPreviewCell *)cell;
    [videocell play:model.asset];
}

#pragma mark - Gesture Action

- (void)tapAction:(UIGestureRecognizer *)gesture {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    CGPoint point = [gesture locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    RCAssetModel *model = self.previewPhotosArr[indexPath.row];
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        RCVideoPreviewCell *videoCell = (RCVideoPreviewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [videoCell stop];
    }

    self.topView.hidden = !self.topView.hidden;
    self.bottomView.hidden = self.topView.hidden;
}

- (void)backButtonAction {
    self.finishPreviewAndBackPhotosPicker(self.selectedArr, self.allPhotosArr, self.fullButton.selected);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)isSelectedButtonAction:(UIButton *)button {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    RCAssetModel *selectModel = self.previewPhotosArr[self.currentIndex];
    if (!selectModel) {
        return;
    }
    [self selectedImageCanSend:selectModel
                      complete:^(BOOL canSend) {
                          if (canSend) {
                              NSInteger i = selectModel.index;
                              if (self.selectedButton.selected) {
                                  RCAssetModel *model = self.previewPhotosArr[self.currentIndex];
                                  for (int i = 0; i < self.selectedArr.count; i++) {
                                      if ([self.selectedArr[i].asset isEqual:model.asset]) {
                                          [self.selectedArr removeObject:self.selectedArr[i]];
                                          break;
                                      }
                                  }
                                  self.previewPhotosArr[self.currentIndex].isSelect = NO;
                                  self.allPhotosArr[i].isSelect = NO;
                                  [self _updateTopBarStatus];
                              } else {
                                  if (self.selectedArr.count < 9) {
                                      [self animationWithLayer:self.selectedButton.layer];
                                      RCAssetModel *model = self.previewPhotosArr[self.currentIndex];
                                      model.isSelect = YES;
                                      BOOL isNotContains = YES;
                                      for (int i = 0; i < self.selectedArr.count; i++) {
                                          if ([self.selectedArr[i].asset isEqual:model.asset]) {
                                              isNotContains = NO;
                                              break;
                                          }
                                      }
                                      if (isNotContains) {
                                          if (model.mediaType == PHAssetMediaTypeVideo &&
                                              NSClassFromString(@"RCSightCapturer")) {
                                              if (!model.thumbnailImage) {
                                                  [self showAlertWithMessage:RCLocalizedString(
                                                                                 @"Selected_Damaged_Video")];
                                                  model.isSelect = NO;
                                                  return;
                                              }
                                              CGFloat durationLimit = RCKitConfigCenter.message.uploadVideoDurationLimit;
                                              if (round(model.duration) <= durationLimit) {
                                                  [self.selectedArr addObject:model];
                                              } else {
                                                  CGFloat minutes = durationLimit / 60.0f;
                                                  NSString *minutesText = [NSString stringWithFormat:@"%.2g", minutes];
                                                  NSString *msg =
                                                      [NSString stringWithFormat:RCLocalizedString(
                                                                                     @"Selected_Video_Warning_fmt"),
                                                                                 minutesText];
                                                  [self showAlertWithMessage:msg];
                                                  model.isSelect = NO;
                                                  return;
                                              }
                                          } else {
                                              [self.selectedArr addObject:model];
                                          }
                                      }
                                      self.allPhotosArr[i].isSelect = YES;
                                      [self _updateTopBarStatus];
                                  } else {
                                      [RCAlertView showAlertController:nil message:RCLocalizedString(@"Max_Selected_Photos") cancelTitle:RCLocalizedString(@"i_know_it") inViewController:self];
                                  }
                              }
                              [self _updateBottomSendImageCountButton];
                          }
                      }];
}

- (void)fullBtnCliced:(UIButton *)sender {
    self.fullButton.selected = !self.fullButton.selected;
    self.isFull = !self.isFull;
    if (_fullButton.selected) {
        if (!self.selectedButton.selected) {
            [self isSelectedButtonAction:nil];
        };
        [self updateImageSize];
    } else {
        [_fullButton setTitle:[NSString stringWithFormat:@"%@", RCLocalizedString(@"Full_Image")]
                     forState:UIControlStateNormal];
    }
}

- (void)editBtnClick:(UIButton *)sender {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    if (self.onClickEditPhotoBlock) {
        RCAssetModel *editModel = self.previewPhotosArr[self.currentIndex];
        self.onClickEditPhotoBlock(self, editModel);
    }
}

- (void)sendImageMessageButton:(UIButton *)sender {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    if (self.selectedArr.count == 0) {
        [self.selectedArr addObject:self.previewPhotosArr[self.currentIndex]];
    }
    self.finishiPreviewAndSendImage(self.selectedArr, self.fullButton.selected);
}

#pragma mark - Private Methods

- (void)creatTopView {
    CGFloat originY = RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") ? 20 : 0;
    if ([UIApplication sharedApplication].statusBarFrame.size.height > 25) {
        originY = 44;
    }
    self.topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, originY + 44)];
    _topView.backgroundColor = [HEXCOLOR(0x222222) colorWithAlphaComponent:0.8];
    [self.view addSubview:_topView];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:RCResourceImage(@"navigator_white_back") forState:UIControlStateNormal];
    [backButton setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 6)];
    [backButton sizeToFit];
    if ([UIApplication sharedApplication].statusBarFrame.size.height > 25) {
        backButton.frame = CGRectMake(10, _topView.frame.size.height / 2, 44, 44);
    } else {
        backButton.frame = CGRectMake(10, _topView.frame.size.height / 2 - 44 / 2, 44, 44);
    }

    [backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:backButton];

    UIButton *stateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [stateButton setImage:RCResourceImage(@"photo_preview_unselected") forState:UIControlStateNormal];
    [stateButton setImage:RCResourceImage(@"photo_preview_selected") forState:UIControlStateSelected];
    [stateButton sizeToFit];
    stateButton.imageEdgeInsets = (UIEdgeInsets){12, 12, 12, 12};
    if ([UIApplication sharedApplication].statusBarFrame.size.height > 25) {
        stateButton.frame = CGRectMake(_topView.frame.size.width - 10 - 44, _topView.frame.size.height / 2, 44, 44);
    } else {
        stateButton.frame =
            CGRectMake(_topView.frame.size.width - 10 - 44, _topView.frame.size.height / 2 - 44 / 2, 44, 44);
    }

    [stateButton addTarget:self action:@selector(isSelectedButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:self.selectedButton = stateButton];
}

- (void)createBottomView {
    CGFloat safeAreaHomeBarHeight = [RCKitUtility getWindowSafeAreaInsets].bottom;
    _bottomView = [[UIView alloc]
        initWithFrame:CGRectMake(0, self.view.bounds.size.height - 49 - safeAreaHomeBarHeight,
                                 self.view.bounds.size.width, 49 + safeAreaHomeBarHeight)];
    _bottomView.backgroundColor = [HEXCOLOR(0x222222) colorWithAlphaComponent:0.8];
    [self.view addSubview:_bottomView];
    // add button for bottom bar
    _sendButton = [[UIButton alloc] init];
    _sendButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_sendButton setTitle:RCLocalizedString(@"Send") forState:UIControlStateNormal];
    [_sendButton setTitleColor:RCResourceColor(@"photoPreview_send_disable", @"0x959595")
                      forState:UIControlStateDisabled];
    [_sendButton addTarget:self action:@selector(sendImageMessageButton:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_sendButton];
    [self _updateBottomSendImageCountButton];
    _fullButton = [[UIButton alloc] init];
    [_fullButton setTitle:[NSString stringWithFormat: @"%@", RCLocalizedString(@"Full_Image")]
                 forState:UIControlStateNormal];
    _fullButton.contentMode = UIViewContentModeLeft;
    _fullButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_fullButton addTarget:self action:@selector(fullBtnCliced:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_fullButton];

    _editButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [_editButton setTitle:RCLocalizedString(@"Edit") forState:(UIControlStateNormal)];
    [_editButton setTitleColor:RCResourceColor(@"photoPreview_send_disable", @"0x959595")
                      forState:UIControlStateNormal];
    [_editButton addTarget:self action:@selector(editBtnClick:) forControlEvents:(UIControlEventTouchUpInside)];
    [_bottomView addSubview:_editButton];

    [_sendButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_editButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_fullButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    _fullButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    if ([RCKitUtility isRTL]) {
        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_fullButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_fullButton)]];

        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_sendButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_sendButton)]];
        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_editButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_editButton)]];

        [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_sendButton]-32-[_fullButton]"
                                                                            options:kNilOptions
                                                                            metrics:nil
                                                                              views:NSDictionaryOfVariableBindings(
                                                                                        _fullButton, _sendButton)]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_fullButton
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeRight
                                                               multiplier:1
                                                                 constant:-10]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_sendButton
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1
                                                                 constant:10]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_editButton
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1
                                                                 constant:0]];
    } else {
        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_sendButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_sendButton)]];

        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_fullButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_fullButton)]];
        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_editButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_editButton)]];

        [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_fullButton]-32-[_sendButton]"
                                                                            options:kNilOptions
                                                                            metrics:nil
                                                                              views:NSDictionaryOfVariableBindings(
                                                                                        _fullButton, _sendButton)]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_sendButton
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeRight
                                                               multiplier:1
                                                                 constant:-10]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_fullButton
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1
                                                                 constant:10]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_editButton
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1
                                                                 constant:0]];
    }

    [_sendButton setTitleColor:RCResourceColor(@"photoPreview_send_normal", @"0x0099ff")
                      forState:UIControlStateNormal];
    [_fullButton setTitleColor:RCResourceColor(@"photoPreview_original_normal_text", @"0x999999")
                      forState:UIControlStateNormal];
    [_fullButton setTitleColor:RCResourceColor(@"photoPreview_original_selected_text", @"0xffffff")
                      forState:UIControlStateSelected];
    [_fullButton setImage:RCResourceImage(@"unselected_full") forState:UIControlStateNormal];
    [_fullButton setImage:RCResourceImage(@"selected_full") forState:UIControlStateSelected];
    _fullButton.imageEdgeInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    [self.bottomView setNeedsUpdateConstraints];
    [self.bottomView updateConstraintsIfNeeded];
    [self.bottomView layoutIfNeeded];
    [self _updateFullButton];
    [self _updateEditButton];
}

- (void)selectedImageCanSend:(RCAssetModel *)selectModel complete:(void (^)(BOOL canSend))completeBlock {
    if ([[selectModel.asset valueForKey:@"uniformTypeIdentifier"] isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
        [[RCAssetHelper shareAssetHelper]
            getOriginImageDataWithAsset:selectModel
                                 result:^(NSData *imageData, NSDictionary *info, RCAssetModel *assetModel) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         if (imageData.length >
                                             [[RCIMClient sharedRCIMClient] getGIFLimitSize] * 1024) {
                                             completeBlock(NO);
                                             UIAlertController *alertController = [UIAlertController
                                                 alertControllerWithTitle:RCLocalizedString(@"GIFAboveMaxSize")
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleAlert];
                                             [alertController
                                                 addAction:[UIAlertAction
                                                               actionWithTitle:RCLocalizedString(@"OK")
                                                                         style:UIAlertActionStyleDefault
                                                                       handler:nil]];
                                             [self presentViewController:alertController animated:YES completion:nil];
                                         } else {
                                             completeBlock(YES);
                                         }
                                     });
                                 }
                        progressHandler:nil];
    } else {
        completeBlock(YES);
    }
}

- (void)_updateTopBarStatus {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    RCAssetModel *asset = self.previewPhotosArr[self.currentIndex];
    self.selectedButton.selected = asset.isSelect;
    if (self.fullButton.selected) {
        [self updateImageSize];
    }
}

- (void)_updateFullButton {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    RCAssetModel *model = self.previewPhotosArr[self.currentIndex];
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        _fullButton.hidden = YES;
    } else {
        _fullButton.hidden = NO;
    }
}

- (void)_updateEditButton {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    RCAssetModel *model = self.previewPhotosArr[self.currentIndex];
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        self.editButton.hidden = YES;
    } else {
        self.editButton.hidden = !self.photoEditEnable;
    }
}

- (void)_updateBottomSendImageCountButton {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.selectedArr.count && weakSelf.bottomView) {
            self.sendButton.enabled = YES;
            if ([RCKitUtility isRTL]) {
                [self.sendButton setTitle:[NSString stringWithFormat:@"(%lu) %@", (unsigned long)weakSelf.selectedArr.count, RCLocalizedString(@"Send")] forState:(UIControlStateNormal)];
            } else {
                [self.sendButton setTitle:[NSString stringWithFormat:@"%@ (%lu)",RCLocalizedString(@"Send"), (unsigned long)weakSelf.selectedArr.count] forState:(UIControlStateNormal)];
            }
        } else {
            self.sendButton.enabled = NO;
            [self.sendButton setTitle:RCLocalizedString(@"Send") forState:(UIControlStateNormal)];
        }
    });
}

// show  alert
- (void)showAlertWithMessage:(NSString *)message {
    [RCAlertView showAlertController:nil message:message cancelTitle:RCLocalizedString(@"Confirm") inViewController:self];
}

- (void)animationWithLayer:(CALayer *)layer {
    NSNumber *animationScale1 = @(0.7);
    NSNumber *animationScale2 = @(0.92);

    [UIView animateWithDuration:0.15
        delay:0
        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
        animations:^{
            [layer setValue:animationScale1 forKeyPath:@"transform.scale"];
        }
        completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15
                delay:0
                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                animations:^{
                    [layer setValue:animationScale2 forKeyPath:@"transform.scale"];
                }
                completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1
                                          delay:0
                                        options:UIViewAnimationOptionBeginFromCurrentState |
                                                UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         [layer setValue:@(1.0) forKeyPath:@"transform.scale"];
                                     }
                                     completion:nil];
                }];
        }];
}

- (void)updateImageSize {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    [_fullButton setTitle:[NSString stringWithFormat:@"%@", RCLocalizedString(@"Full_Image")]
                 forState:UIControlStateNormal];

    RCAssetModel *model = self.previewPhotosArr[self.currentIndex];
    if (model.imageSize) {
        [self getImageSize:model.imageSize];
    } else {
        [self.indicatorView startAnimating];
        // 取消选中，取消存在的 size 请求
        if (self.imageRequestID) {
            [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
        }
        self.currentAssetIdentifier = [[RCAssetHelper shareAssetHelper] getAssetIdentifier:model.asset];
        __weak typeof(self) weakSelf = self;
        self.imageRequestID = [[RCAssetHelper shareAssetHelper]
            getAssetDataSizeWithAsset:self.previewPhotosArr[self.currentIndex].asset
                               result:^(CGFloat size) {
                                   if ([weakSelf.currentAssetIdentifier
                                           isEqualToString:[[RCAssetHelper shareAssetHelper]
                                                               getAssetIdentifier:model.asset]]) {
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [strongSelf getImageSize:size];
                                       });
                                   }
                               }];
    }
}

- (void)getImageSize:(CGFloat)size {
    NSString *imageSize = nil;
    if (size / 1024 / 1024 < 1) {
        imageSize = [NSString stringWithFormat:@"%dK", (int)size / 1024];
    } else {
        imageSize = [NSString stringWithFormat:@"%0.2fM", size / 1024 / 1024];
    }
    [self.indicatorView stopAnimating];
    [self.fullButton
        setTitle:[NSString stringWithFormat:@"%@ (%@)", RCLocalizedString(@"Full_Image"), imageSize]
        forState:UIControlStateNormal];
}

#pragma mark - Getters and Setters
- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        if ([RCKitUtility isRTL]) {
            _indicatorView.frame = CGRectMake(CGRectGetMinX(self.fullButton.frame) - 20 - 6, 18, 20, 20);
        } else {
            _indicatorView.frame = CGRectMake(CGRectGetMinX(self.fullButton.frame) + self.fullButton.titleLabel.frame.size.width + 6, 18, 20, 20);
        }
        [self.bottomView addSubview:_indicatorView];
    }
    return _indicatorView;
}

@end
