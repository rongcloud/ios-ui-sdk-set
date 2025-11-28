//
//  RCUUserProfileViewController.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCProfileViewController.h"
#import "RCUserProfileViewModel.h"
#import "RCProfileTableView.h"
#import "RCKitCommonDefine.h"
#import "RCViewModelAdapterCenter.h"
#import "RCMyProfileViewModel.h"
#import "RCGroupProfileViewModel.h"

@interface RCProfileViewController ()<
UITableViewDelegate,
UITableViewDataSource,
RCListViewModelResponder
>

@property (nonatomic, strong) RCProfileViewModel *viewModel;

@property (nonatomic, strong) RCProfileTableView *profileView;

@end

@implementation RCProfileViewController

- (instancetype)initWithViewModel:(RCProfileViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.viewModel.responder = self;
        if ([viewModel isKindOfClass:[RCMyProfileViewModel class]]) {
            self.title = RCLocalizedString(@"MyProfileTitle");
        } else if ([viewModel isKindOfClass:[RCGroupProfileViewModel class]]) {
            self.title = RCLocalizedString(@"GroupProfileTitle");
        } else {
            self.title = RCLocalizedString(@"UserProfileTitle");
        }
    }
    return self;
}

- (void)loadView {
    self.view = self.profileView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationBarItems];
    [self.viewModel registerCellForTableView:self.profileView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.viewModel updateProfile];
}

#pragma mark -- UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
}

#pragma mark -- UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.profileList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.profileList[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCProfileCellViewModel *viewModel = self.viewModel.profileList[indexPath.section][indexPath.row] ;
    return [viewModel tableView:tableView cellForRowAtIndexPath:indexPath];;
}

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    RCProfileCellViewModel *viewModel = self.viewModel.profileList[indexPath.section][indexPath.row] ;
    return [viewModel tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark -- RCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.profileView reloadData];
}

- (UIViewController *)currentViewController {
    return self;
}

- (void)updateTitle:(NSString *)title {
    self.title = title;
}

- (void)reloadFooterView {
    self.profileView.tableFooterView = [self.viewModel loadFooterView];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- private

- (void)setNavigationBarItems {
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

#pragma mark -- getter

- (RCProfileTableView *)profileView {
    if (!_profileView) {
        _profileView = [[RCProfileTableView alloc] initWithFrame:CGRectZero style:(UITableViewStyleGrouped)];
        _profileView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
        _profileView.backgroundColor =  RCDYCOLOR(0xf5f6f9, 0x111111);
        _profileView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 15)];
        _profileView.sectionHeaderHeight = 0;
        if (@available(iOS 15.0, *)) {
            _profileView.sectionHeaderTopPadding = 15;
        }
        _profileView.delegate = self;
        _profileView.dataSource = self;
        if ([_profileView respondsToSelector:@selector(setSeparatorInset:)]) {
            _profileView.separatorInset = UIEdgeInsetsMake(0, 12, 0, 0);
        }
        if ([_profileView respondsToSelector:@selector(setLayoutMargins:)]) {
            _profileView.layoutMargins = UIEdgeInsetsMake(0, 12, 0, 0);
        }
    }
    return _profileView;
}
@end
