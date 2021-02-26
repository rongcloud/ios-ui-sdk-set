//
//  RCAlumListTableViewController.m
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/18.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCAlumListTableViewController.h"
#import "RCAlbumModel.h"
#import "RCAlbumTableCell.h"
#import "RCAssetModel.h"
#import "RCKitCommonDefine.h"
#import "RCPhotosPickerController.h"
#import "RCMBProgressHUD.h"
#import "RCPhotoEditorManager.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "RCKitConfig.h"

static NSString *const cellReuseIdentifier = @"cell";
static NSString *const lastIndexStr = @"rc_last_album_index";

@interface RCAlumListTableViewController ()
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) RCMBProgressHUD *progressHUD;
@property (nonatomic, assign) BOOL isShowHUD;
@end

@implementation RCAlumListTableViewController
#pragma mark - Life Cycle
- (void)dealloc {
    [[RCPhotoEditorManager sharedManager] removeAllEditPhotos];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.libraryList = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = RCLocalizedString(@"Albums");
    [self setAuthorizationStatusAuthorized];
    [self setNavigationItem];
    [self setupTableView];
    [self getDataSourceAndReloadView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.libraryList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCAlbumTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [cell configCellWithItem:self.libraryList[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCAlbumModel *assetsGroup = self.libraryList[indexPath.row];
    [self pushImagePickerController:assetsGroup animated:YES];
    [[NSUserDefaults standardUserDefaults] setObject:@(indexPath.row) forKey:lastIndexStr];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Private Methods
- (void)setNavigationItem{
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

- (void)setupTableView{
    [self.tableView registerClass:[RCAlbumTableCell class] forCellReuseIdentifier:cellReuseIdentifier];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.rowHeight = 65.0f;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x111111);
    self.tableView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
}

- (void)getDataSourceAndReloadView{
    RCAssetHelper *sharedAssetHelper = [RCAssetHelper shareAssetHelper];
    __weak RCAlumListTableViewController *weakSelf = self;
    NSArray *cacheAssetGroup = [sharedAssetHelper getCachePhotoGroups];
    if (cacheAssetGroup && cacheAssetGroup.count > 0) {
        self.libraryList = cacheAssetGroup;
        RCAlbumModel *assetsGroup = self.libraryList[0];
        //能获取到相册说明有权限，此时隐藏权限提示
        if (self.tipsLabel) {
            [self.tipsLabel setHidden:YES];
        }
        [self pushImagePickerController:assetsGroup animated:NO];
    } else {
        [RCKitUtility showProgressViewFor:self.tableView text:nil animated:YES];
        [sharedAssetHelper
            getGroupsWithALAssetsGroupType:ALAssetsGroupAll
                          resultCompletion:^(NSArray *assetGroup) {
                              if (assetGroup) {
                                  weakSelf.libraryList = assetGroup;
                              }

                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [RCKitUtility hideProgressViewFor:weakSelf.tableView animated:YES];

                                  if (weakSelf.libraryList.count) {
                                      int lastIndex =
                                          [[[NSUserDefaults standardUserDefaults] objectForKey:lastIndexStr] intValue];
                                      RCAlbumModel *assetsGroup;
                                      if (lastIndex >= weakSelf.libraryList.count) {
                                          assetsGroup = weakSelf.libraryList[0];
                                      } else {
                                          assetsGroup = weakSelf.libraryList[lastIndex];
                                      }

                                      [weakSelf pushImagePickerController:assetsGroup animated:NO];
                                      //能获取到相册说明有权限，此时隐藏权限提示
                                      if (weakSelf.tipsLabel) {
                                          [weakSelf.tipsLabel setHidden:YES];
                                      }
                                  } else {
                                      if ([[RCAssetHelper shareAssetHelper] hasAuthorizationStatusAuthorized]) {
                                          if (weakSelf.tipsLabel) {
                                              [weakSelf.tipsLabel setHidden:YES];
                                          }
                                      }
                                      [weakSelf.tableView reloadData];
                                  }

                              });
                          }];
    }
}

- (void)handlePhotos:(NSMutableArray *)photos result:(NSMutableArray *)results full:(BOOL)isFull {
    if (photos.count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideAnimated:YES];
            self.isShowHUD = NO;
            if ([self.delegate respondsToSelector:@selector(albumListViewController:selectedImages:isSendFullImage:)] &&
                results.count) {
                [self.delegate albumListViewController:nil selectedImages:results isSendFullImage:isFull];
            }
            [self dismissCurrentModelViewController];
        });
    } else {
        RCAssetModel *model = [photos objectAtIndex:0];
        [photos removeObjectAtIndex:0];
        __weak typeof(self) weakself = self;
        if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
            [[RCAssetHelper shareAssetHelper] getOriginVideoWithAsset:model.asset
                result:^(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier) {
                    if (![[[RCAssetHelper shareAssetHelper] getAssetIdentifier:model.asset] isEqualToString:imageIdentifier]) {
                        return;
                    }
                    if (avAsset) {
                        NSMutableDictionary *assetInfo = [[NSMutableDictionary alloc] initWithCapacity:5];
                        if (avAsset) {
                            [assetInfo setObject:avAsset forKey:@"avAsset"];
                        }
                        if (model.thumbnailImage) {
                            [assetInfo setObject:model.thumbnailImage forKey:@"thumbnail"];
                        }
                        NSString *localPath = @"";
                        if (@available(iOS 13.0, *)) {
                            AVURLAsset *urlAsset = (AVURLAsset *)avAsset;
                            // 添加判断，如果选择的是慢动作视频，这里返回的是 AVComposition 对象，这个时候没有 URL 属性
                            if ([urlAsset respondsToSelector:@selector(URL)]) {
                                NSURL *url = urlAsset.URL;
                                NSString *tempString = [url absoluteString];
                                localPath =
                                    [tempString stringByReplacingOccurrencesOfString:@"file:///" withString:@""];
                            }
                        }
                        if (localPath == nil || localPath.length < 1) {
                            NSArray *localPaths =
                                [info[@"PHImageFileSandboxExtensionTokenKey"] componentsSeparatedByString:@";"];
                            if (localPaths.count > 0) {
                                localPath = [localPaths lastObject];
                            }
                        }
                        [assetInfo setObject:localPath forKey:@"localPath"];

                        // NSDictionary* assetInfo = @{@"avAsset":model.avAsset,@"thumbnail":!model.thumbnailImage ?
                        // [NSNull null] : model.thumbnailImage};
                        [results addObject:[assetInfo copy]];
                    }
                    [self handlePhotos:photos result:results full:isFull];
                }
                progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                    if (progress < 1 && !error && !weakself.isShowHUD) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            weakself.isShowHUD = YES;
                            weakself.progressHUD =
                                [RCMBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
                            weakself.progressHUD.label.text = RCLocalizedString(@"iCloudDownloading");
                        });
                    }
                    if (error) {
                        // from iCloud download error
                        weakself.progressHUD.label.text = RCLocalizedString(@"iCloudDownloadFail");
                        [weakself.progressHUD hideAnimated:YES afterDelay:1];
                        weakself.isShowHUD = NO;
                    }
                }];
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.networkAccessAllowed = YES;
            [[PHImageManager defaultManager]
                requestAVAssetForVideo:model.asset
                               options:options
                         resultHandler:^(AVAsset *_Nullable asset, AVAudioMix *_Nullable audioMix,
                                         NSDictionary *_Nullable info){

                         }];

        } else {
            NSString *identifier = [[RCAssetHelper shareAssetHelper] getAssetIdentifier:model.asset];
            if ([[RCPhotoEditorManager sharedManager] hasBeenEdit:identifier]) {
                model = [[RCPhotoEditorManager sharedManager] getEditPhoto:identifier];
                [results addObject:UIImageJPEGRepresentation(model.previewImage, 1.0)];
                [self handlePhotos:photos result:results full:isFull];
            } else {
                __weak typeof(self) weakself = self;
                [[RCAssetHelper shareAssetHelper] getOriginImageDataWithAsset:model
                    result:^(NSData *imageData, NSDictionary *info, RCAssetModel *assetModel) {
                        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                                ![info objectForKey:PHImageErrorKey] &&
                                                ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                        if (downloadFinined && imageData) {
                            if ([[model.asset valueForKey:@"uniformTypeIdentifier"]
                                    isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
                                NSMutableDictionary *gifInfo = [[NSMutableDictionary alloc] init];
                                [gifInfo setObject:@"GIF" forKey:@"GIF"];
                                [gifInfo setObject:imageData forKey:@"imageData"];
                                [results addObject:gifInfo];
                            } else {
                                [results addObject:imageData];
                            }
                            [weakself handlePhotos:photos result:results full:isFull];
                        }
                    }
                    progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                        if (progress < 1 && !error && !weakself.isShowHUD) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                weakself.isShowHUD = YES;
                                weakself.progressHUD =
                                    [RCMBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow
                                                         animated:YES];
                                weakself.progressHUD.label.text = RCLocalizedString(@"iCloudDownloading");
                            });
                        }
                        if (error) {
                            // from iCloud download error
                            weakself.progressHUD.label.text = RCLocalizedString(@"iCloudDownloadFail");
                            [weakself.progressHUD hideAnimated:YES afterDelay:1];
                            weakself.isShowHUD = NO;
                        }
                    }];
            }
        }
    }
}

- (void)pushImagePickerController:(RCAlbumModel *)assetsGroup animated:(BOOL)animated {

    RCPhotosPickerController *imagePickerVC = [RCPhotosPickerController imagePickerViewController];
    imagePickerVC.count = assetsGroup.count;
    imagePickerVC.currentAsset = assetsGroup.asset;
    imagePickerVC.title = assetsGroup.albumName;
    imagePickerVC.photoEditEnable = self.photoEditEnable;
    __weak typeof(self) weakself = self;
    [imagePickerVC setSendPhotosBlock:^(NSArray *photos, BOOL isFull) {
        NSMutableArray *selectedPhotos = [NSMutableArray array];
        [weakself handlePhotos:[photos mutableCopy] result:selectedPhotos full:isFull];
    }];
    [imagePickerVC setEditPhotoBlock:^(UIViewController *rootCtrl, RCAssetModel *asset) {
        if (weakself.delegate && [weakself.delegate respondsToSelector:@selector(onClickEditPhoto:previewImage:)]) {
            [weakself.delegate onClickEditPhoto:rootCtrl previewImage:asset.previewImage];
        }
    }];

    [self.navigationController pushViewController:imagePickerVC animated:animated];
}

- (void)dismissCurrentModelViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setAuthorizationStatusAuthorized {
    if (![[RCAssetHelper shareAssetHelper] hasAuthorizationStatusAuthorized]) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.frame = CGRectMake(8, 64, self.view.frame.size.width - 16, 100);
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.numberOfLines = 0;
        _tipsLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
        _tipsLabel.textColor = [UIColor blackColor];
        _tipsLabel.text = RCLocalizedString(@"PhotoAccessRight");
        [self.view addSubview:_tipsLabel];
    }
}

@end
