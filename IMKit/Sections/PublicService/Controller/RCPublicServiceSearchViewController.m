//
//  RCPublicServiceSearchViewController.m
//  RongIMKit
//
//  Created by litao on 15/4/21.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPublicServiceSearchViewController.h"
#import "RCPublicServiceListViewCell.h"
#import "RCPublicServiceProfileViewController.h"
#import "RCPublicServiceSearchHintCell.h"
#import "RCSearchItemView.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import <RongPublicService/RongPublicService.h>
@interface RCPublicServiceSearchViewController () <UISearchBarDelegate, UISearchControllerDelegate, UITableViewDelegate,
                                                   UITableViewDataSource, RCSearchItemDelegate>
@property (nonatomic, strong) UISearchBar *mySearchBar;
@property (nonatomic, strong) UISearchController *searchController; //搜索VC
@property (nonatomic, strong) RCSearchItemView *searchItem;
@property (nonatomic, strong) NSArray *searchResults; // of RCPublicServiceProfile
@property (nonatomic, copy) NSString *searchKey;
@property (nonatomic, strong) NSMutableDictionary *offscreenCells; // of RCPublicServiceListViewCell
@end

@implementation RCPublicServiceSearchViewController
#pragma mark – Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    self.definesPresentationContext = YES;
    self.tableView.backgroundColor = RCDYCOLOR(0xf0f0f6, 0x000000);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.tableView.tableFooterView = [UIView new];
    [self setTitle:RCLocalizedString(@"SearchPublicService")];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark – Private Methods

- (void)onSearchItemTapped {
    DebugLog(@"taped");
    [self startSearch];
}
- (void)startSearch {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];

    [RCKitUtility showProgressViewFor:self.tableView
                                       text:RCLocalizedString(@"Searching")
                                   animated:YES];

    [self.searchItem setHidden:YES];

    __weak RCPublicServiceSearchViewController *weakSelf = self;
    [[RCPublicServiceClient sharedPublicServiceClient] searchPublicService:RC_SEARCH_TYPE_FUZZY
        searchKey:self.searchKey
        success:^(NSArray *accounts) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.searchResults = accounts;
                [RCKitUtility hideProgressViewFor:weakSelf.tableView animated:YES];
            });
        }
        error:^(RCErrorCode status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [RCKitUtility hideProgressViewFor:weakSelf.tableView animated:YES];
            });
        }];
}


#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchKey = searchText;
    [self.searchItem setKeyContent:searchText];
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchResults = nil;
    [self.searchItem setHidden:NO];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self startSearch];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchKey = nil;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.searchKey.length == 0) {
        return 0;
    }
    if (self.searchKey) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchKey.length == 0) {
        return 0;
    }
    if (self.searchKey) {
        if ([self.searchResults count]) {
            return [self.searchResults count];
        } else {
            return 1;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchKey.length == 0) {
        return [[UITableViewCell alloc] init];
    }
    if (self.searchKey) {
        if ([self.searchResults count]) {
            RCPublicServiceListViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:@"public account list view cell"];

            if (!cell) {
                cell = [[RCPublicServiceListViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:@"public account list view cell"];
            }
            RCPublicServiceProfile *info = self.searchResults[indexPath.row];
            //[cell.headerImageView setImage:[RCPublicServiceUtility imagesNamedFromPABundle:@"searchItem"]];
            cell.searchKey = self.searchKey;
            [cell setName:info.name];
            [cell setDescription:info.introduction];
            [cell.headerImageView setImageURL:[NSURL URLWithString:info.portraitUrl]];
            [cell setNeedsUpdateConstraints];
            [cell updateConstraintsIfNeeded];

            return cell;
        }
        CGRect frame = tableView.bounds;
        frame.size.height = 50;
        RCPublicServiceSearchHintCell *cell = [[RCPublicServiceSearchHintCell alloc] initWithFrame:frame];
        return cell;
    }
    return [[UITableViewCell alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.searchKey.length == 0) {
        return 0;
    }
    if ([self.searchResults count]) {
        return 0;
    }
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (!self.searchItem) {
            self.searchItem = [[RCSearchItemView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
            self.searchItem.delegate = self;
        }
        [self.searchItem setKeyContent:self.searchKey];
        return self.searchItem;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchKey.length == 0) {
        return 0;
    }
    if (![self.searchResults count]) {
        return 0;
    }
    NSString *reuseIdentifier = @"public account list view cell";
    RCPublicServiceListViewCell *cell = [self.offscreenCells objectForKey:reuseIdentifier];
    if (!cell) {
        cell = [[RCPublicServiceListViewCell alloc] init];
        [self.offscreenCells setObject:cell forKey:reuseIdentifier];
    }

    RCPublicServiceProfile *info = self.searchResults[indexPath.row];

    [cell.headerImageView setImage:[UIImage imageNamed:@"searchItem"]];
    cell.searchKey = self.searchKey;
    [cell setName:info.name];
    [cell setDescription:info.introduction];
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));

    [cell setNeedsLayout];
    [cell layoutIfNeeded];

    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;

    height += 19.0f;

    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchKey && [self.searchResults count]) {
        RCPublicServiceProfile *serviceProfile = self.searchResults[indexPath.row];
        RCPublicServiceProfileViewController *infoVC = [[RCPublicServiceProfileViewController alloc] init];
        infoVC.serviceProfile = serviceProfile;
        [self.navigationController pushViewController:infoVC animated:YES];
    }
}

#pragma mark – Getters and Setters
- (NSMutableDictionary *)offscreenCells {
    if (!_offscreenCells) {
        _offscreenCells = [[NSMutableDictionary alloc] init];
    }
    return _offscreenCells;
}

- (void)setSearchResults:(NSArray *)searchResults {
    _searchResults = searchResults;
    [self.tableView reloadData];
}

- (UISearchController *)searchController {
    if (!_searchController) {
        _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        _searchController.delegate = self;
        _searchController.searchBar.barStyle = UIBarStyleDefault;
        _searchController.searchBar.delegate = self;
        _searchController.hidesNavigationBarDuringPresentation = NO;
        //提醒字眼
        _searchController.searchBar.placeholder = RCLocalizedString(@"ToSearch");
        //设置顶部搜索栏的背景色
        _searchController.searchBar.barTintColor = RCDYCOLOR(0xffffff, 0x000000);
        _searchController.searchBar.layer.borderColor = RCDYCOLOR(0xffffff, 0x000000).CGColor;
        _searchController.searchBar.layer.borderWidth = 1;
        if (@available(iOS 13.0, *)) {
            _searchController.searchBar.searchTextField.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xf9f9f9) darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.6]];;
        }
        _searchController.dimsBackgroundDuringPresentation = NO;
    }
    return _searchController;
}
@end
