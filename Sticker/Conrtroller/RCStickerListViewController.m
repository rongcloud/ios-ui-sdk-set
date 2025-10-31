//
//  RCStickerListViewController.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/20.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerListViewController.h"
#import "RCStickerDataManager.h"
#import "RCStickerUtility.h"
#import "RCStickerListCell.h"
#import "RongStickerAdaptiveHeader.h"

#define CellIdentifity @"CellIdentifity"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width

@interface RCStickerListViewController () <UITableViewDelegate, UITableViewDataSource, RCStickerListCellDelegate>

@property (nonatomic, strong) NSArray *dataSource;

@property (nonatomic, strong) RCBaseTableView *tableView;

@property (nonatomic, strong) UIView *headerView;

@property (nonatomic, strong) UIView *emptyView;

@end

@implementation RCStickerListViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = RongStickerString(@"my_stickers");
    self.view.backgroundColor = RCDynamicColor(@"common_background_color", @"0xf0f0f6", @"0x000000");
    self.navigationController.navigationBar.titleTextAttributes =
        @{NSForegroundColorAttributeName : RCKitConfigCenter.ui.globalNavigationBarTintColor};
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(packageDownloading:)
                                                 name:RCStickersDownloadingNotification
                                               object:nil];

    [self.view addSubview:self.emptyView];
    [self.view addSubview:self.tableView];

    [self setNav];

    [self refreshDataSource];
}

- (UIImage *)imageflippedForRTL:(UIImage *)image
{
    if (@available(iOS 9.0, *)) {
        if ([RCKitUtility isRTL]) {
            return [UIImage imageWithCGImage:image.CGImage
                                       scale:image.scale
                                 orientation:UIImageOrientationUpMirrored];
        }
    }
    return image;
}

- (void)setNav {
    self.navigationController.navigationBar.translucent = NO;
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    imgMirror = [self imageflippedForRTL:imgMirror];
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:RongStickerString(@"back") target:self action:@selector(backAction)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshDataSource {
    self.dataSource = [[RCStickerDataManager sharedManager] getAllDownloadedPackages];
    if (self.dataSource.count > 0) {
        self.tableView.hidden = NO;
        self.emptyView.hidden = YES;
    } else {
        self.tableView.hidden = YES;
        self.emptyView.hidden = NO;
    }
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notification

- (void)packageDownloading:(NSNotification *)notification {
    //    NSString *packageId = [notification.userInfo objectForKey:@"packageId"];
    float progress = [[notification.userInfo objectForKey:@"progress"] floatValue];
    if (progress == 100) {
        [self refreshDataSource];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    RCStickerPackage *package = self.dataSource[indexPath.row];
    RCStickerListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifity];
    if (!cell) {
        cell = [[RCStickerListCell alloc] init];
    }
    [cell configWithModel:package];
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [self headerView];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    return 36.f;
}

#pragma mark - RCStickerListCellDelegate

- (void)onDeletePackage:(NSString *)packageId {
    [[RCStickerDataManager sharedManager] deletePackage:packageId];
    [self refreshDataSource];
    [self.tableView reloadData];
}

#pragma mark - Lazy load

- (RCBaseTableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[RCBaseTableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorColor = RCDynamicColor(@"line_background_color", @"0xe3e5e6", @"0x272727");
        _tableView.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf5f6f9", @"0x111111");
    }
    return _tableView;
}

- (UIView *)headerView {
    if (_headerView == nil) {
        _headerView = [[UIView alloc] init];
        RCBaseLabel *headerLabel = [[RCBaseLabel alloc] init];
        headerLabel.font = [UIFont systemFontOfSize:12];
        headerLabel.textColor = RCDynamicColor(@"text_secondary_color",@"0x999999", @"0x999999");
        headerLabel.text = RongStickerString(@"download_package");
        headerLabel.frame = CGRectMake(15, 10, ScreenWidth-30, 17);
        [_headerView addSubview:headerLabel];
    }
    return _headerView;
}

- (UIView *)emptyView {
    if (_emptyView == nil) {
        _emptyView = [[UIView alloc] initWithFrame:self.view.bounds];
        RCBaseImageView *emptyImage = [[RCBaseImageView alloc] init];
        CGFloat emptyViewWidth = 128.f;
        emptyImage.contentMode = UIViewContentModeScaleAspectFit;
        emptyImage.frame = CGRectMake((ScreenWidth - emptyViewWidth) / 2, 97, emptyViewWidth, emptyViewWidth);
        emptyImage.image = RongStickerImage(@"empty_list");
        [_emptyView addSubview:emptyImage];

        UILabel *descLabel = [[UILabel alloc] init];
        descLabel.font = [UIFont systemFontOfSize:18];
        descLabel.textAlignment = NSTextAlignmentCenter;
        descLabel.textColor = RCDynamicColor(@"text_secondary_color",@"0x666666", @"0x666666");
        descLabel.text = RongStickerString(@"package_list_empty");
        descLabel.frame = CGRectMake(0, CGRectGetMaxY(emptyImage.frame) + 72, ScreenWidth, 25);
        [_emptyView addSubview:descLabel];
    }
    return _emptyView;
}

@end
