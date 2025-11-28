//
//  RCUAddFriendViewController.m
//  RongUserProfile
//
//  Created by RobinCui on 2024/8/16.
//

#import "RCUserSearchViewController.h"
#import "RCUserSearchView.h"
#import "RCKitCommonDefine.h"
@interface RCUserSearchViewController ()<RCListViewModelResponder>
@property (nonatomic, strong) RCUserSearchView *listView;
@property (nonatomic, strong) RCUserSearchViewModel *viewModel;
@end

@implementation RCUserSearchViewController

- (instancetype)initWithViewModel:(RCUserSearchViewModel *)viewModel
{
    self = [super init];
    if (self) {
        [viewModel bindResponder:self];
        self.viewModel = viewModel;
    }
    return self;
}

- (void)loadView {
    self.view = self.listView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.viewModel endEditingState];
}

- (void)setupView {
    self.edgesForExtendedLayout = UIRectEdgeNone;
    if (!self.title) {
        self.title = RCLocalizedString(@"UserSearchAddNew");
    }
    [self configureSearchBar];
//    [self configureRightNaviItems];
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)configureSearchBar {
    UISearchBar *bar = [self.viewModel configureSearchBarForViewController:self];
    [self.listView configureSearchBar:bar];
}

- (void)configureRightNaviItems {
    NSArray *items = [self.viewModel configureRightNaviItemsForViewController:self];
    self.navigationItem.rightBarButtonItems = items;
}

#pragma mark - RCFriendListViewModelResponder
- (void)reloadData:(BOOL)isEmpty {
    self.listView.labEmpty.hidden = !isEmpty;
}

#pragma mark - UITableViewDelegate


#pragma mark - Property

- (RCUserSearchView *)listView {
    if (!_listView) {
        RCUserSearchView *listView = [RCUserSearchView new];
        _listView = listView;
    }
    return _listView;
}

@end
