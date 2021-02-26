//
//  RCCCUserListViewController.m
//  RongContactCard
//
//  Created by liulin on 16/11/17.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RongIMKitHeader.h"
#import "RCCCUserListViewController.h"
#import "RCCCContactTableViewCell.h"
#import "UIColor+RCCCColor.h"
#import "RCCCUIBarButtonItem.h"
#import "RCSendCardMessageView.h"
#import "RCCCUtilities.h"
#import "RCContactCardKit.h"
@interface RCCCUserListViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate,
                                          UISearchDisplayDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *userListArr; //数据源
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, strong) UISearchBar *searchBar; //搜索框
//搜索出的结果数据集合
@property (nonatomic, strong) NSMutableArray *matchSearchList;

//是否是显示搜索的结果
@property (nonatomic, assign) BOOL isSearchResult;

@property (nonatomic, strong) NSMutableDictionary *contactsDic;

@property (nonatomic, strong) NSArray *allKeys;

@property (nonatomic, strong) NSMutableArray *contacts;

@property (nonatomic, strong) RCCCUIBarButtonItem *leftBtn;
@end

@implementation RCCCUserListViewController

#pragma mark - dataArr(模拟从服务器获取到的数据)

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(setExtendedLayoutIncludesOpaqueBars:)]) {
        [self setExtendedLayoutIncludesOpaqueBars:YES];
    }

    self.matchSearchList = [NSMutableArray new];
    [self getAllData];

    // configNav
    [self configNav];
    //布局View
    [self setUpView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(leftBarButtonItemPressed:)
                                                 name:RCCC_CardMessageSend
                                               object:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self layoutSubview:size];
    }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> context){

        }];
}

- (void)layoutSubview:(CGSize)size {
    self.searchBar.frame = CGRectMake(0, 0, size.width, 44);
    self.tableView.frame = CGRectMake(0.0, 0.0, size.width, size.height);
}

#pragma mark - 获取好友并且排序
/**
 *  initial data
 */
- (void)getAllData {
    _contactsDic = [NSMutableDictionary new];
    _allKeys = [NSMutableArray new];
    _contacts = [NSMutableArray new];
    if ([self canShowContacts]) {
        __weak typeof(self) weakSelf = self;
        [[RCContactCardKit shareInstance]
                .contactsDataSource getAllContacts:^(NSArray<RCCCUserInfo *> *contactsInfoList) {
            weakSelf.contacts = [contactsInfoList mutableCopy];
            [weakSelf dealWithContactsList];
        }];
    }
}

- (BOOL)canShowContacts {
    BOOL result = [RCContactCardKit shareInstance].contactsDataSource &&
                  [[RCContactCardKit shareInstance].contactsDataSource respondsToSelector:@selector(getAllContacts:)];
    if (!result) {
        NSLog(@"Error: Display contact card list must be implemented  RCCCContactsDataSource of RCContactCardKit");
    }
    return result;
}

- (void)dealWithContactsList {
    if (_contacts.count < 1) {
        //显示暂无好友
    } else {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSMutableDictionary *resultDic = [RCCCUtilities sortedArrayWithPinYinDic:_contacts];
            dispatch_async(dispatch_get_main_queue(), ^{
                _contactsDic = resultDic[@"infoDic"];
                _allKeys = resultDic[@"allKeys"];
                [self.tableView reloadData];
            });
        });
    }
}

- (void)configNav {
    self.navigationItem.title = RCLocalizedString(@"SelectContact");
    self.leftBtn =
        [[RCCCUIBarButtonItem alloc] initWithbuttonTitle:RCLocalizedString(@"Cancel")
                                              titleColor:RCKitConfigCenter.ui.globalNavigationBarTintColor
                                             buttonFrame:CGRectMake(0, 0, 50, 30)
                                                  target:self
                                                  action:@selector(leftBarButtonItemPressed:)];
    self.leftBtn.button.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.leftBtn buttonIsCanClick:YES
                       buttonColor:RCKitConfigCenter.ui.globalNavigationBarTintColor
                     barButtonItem:self.leftBtn];
    self.navigationItem.leftBarButtonItem = self.leftBtn;
}

- (void)leftBarButtonItemPressed:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - setUpView
- (void)setUpView {
    [self.view addSubview:self.tableView];
}
- (UISearchBar *)searchBar {
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        [_searchBar sizeToFit];
        [_searchBar setPlaceholder:RCLocalizedString(@"ToSearch")];
        [_searchBar setDelegate:self];
        [_searchBar setKeyboardType:UIKeyboardTypeDefault];
        if (@available(iOS 13.0, *)) {
            _searchBar.searchTextField.backgroundColor =
                [RCKitUtility generateDynamicColor:[UIColor whiteColor]
                                         darkColor:[UIColor colorWithHexString:@"262626" alpha:0.6]];
        }
        //设置顶部搜索栏的背景色
        _searchBar.barTintColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"f0f0f6" alpha:0.6]
                                                           darkColor:[UIColor blackColor]];
        _searchBar.layer.borderColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"f0f0f6" alpha:1]
                                                                darkColor:[UIColor blackColor]]
                                           .CGColor;
        _searchBar.layer.borderWidth = 1;
    }
    return _searchBar;
}
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc]
            initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height)
                    style:UITableViewStylePlain];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        _tableView.backgroundColor = [RCKitUtility generateDynamicColor:[UIColor colorWithHexString:@"f0f0f6" alpha:1] darkColor:[UIColor colorWithHexString:@"111111" alpha:1]];
        _tableView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
        _tableView.tableHeaderView = self.searchBar;
        // cell无数据时，不显示间隔线
        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        [_tableView setTableFooterView:v];
        _tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 59, 0, 0)];
        }
        if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [self.tableView setLayoutMargins:UIEdgeInsetsMake(0, 59, 0, 0)];
        }
    }
    return _tableView;
}

#pragma mark - UITableView delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.isSearchResult == NO) {
        return [_allKeys count];
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isSearchResult == NO) {
        NSString *key = [_allKeys objectAtIndex:section];
        NSArray *arr = [_contactsDic objectForKey:key];
        return [arr count];
    }
    return self.matchSearchList.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54.5;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.isSearchResult == NO) {
        return _allKeys;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index - 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.isSearchResult) {
        return 0;
    } else {
        return 22.0;
    }
}

#pragma mark - UITableView dataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableCellWithIdentifier = @"RCCCContactTableViewCell";
    RCCCContactTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reusableCellWithIdentifier];
    if (cell == nil) {
        cell = [[RCCCContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:reusableCellWithIdentifier];
    }
    RCCCUserInfo *userInfo;
    if (self.isSearchResult == NO) {
        NSString *letter = _allKeys[indexPath.section];
        NSArray *sectionUserInfoList = _contactsDic[letter];
        userInfo = sectionUserInfoList[indexPath.row];
    } else {
        userInfo = [self.matchSearchList objectAtIndex:indexPath.row];
    }
    if (userInfo) {
        if (userInfo.displayName.length > 0) {
            cell.nicknameLabel.text = userInfo.displayName;
        } else {
            cell.nicknameLabel.text = userInfo.name;
        }
        [cell.portraitView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.portraitView.contentMode = UIViewContentModeScaleAspectFill;
    cell.nicknameLabel.font = [UIFont systemFontOfSize:15.f];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.frame = CGRectMake(0, 0, self.view.frame.size.width, 22);
    view.backgroundColor = [UIColor clearColor];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.frame = CGRectMake(13, 3, 15, 15);
    title.font = [UIFont systemFontOfSize:15.f];
    title.textColor = RCDYCOLOR(0x999999, 0x878787);

    [view addSubview:title];

    if (self.isSearchResult == NO) {
        title.text = _allKeys[section];
    } else {
        title.text = @"";
    }

    return view;
}

#pragma mark searchBar delegate
// searchBar开始编辑时改变取消按钮的文字
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.matchSearchList removeAllObjects];
    if ([searchText isEqualToString:@""]) {
        self.isSearchResult = NO;
        [self.tableView reloadData];
        return;
    } else {
        for (RCUserInfo *userInfo in [_contacts copy]) {
            //忽略大小写去判断是否包含
            if ([userInfo.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [[RCCCUtilities hanZiToPinYinWithString:userInfo.name] rangeOfString:searchText
                                                                             options:NSCaseInsensitiveSearch]
                        .location != NSNotFound) {
                [self.matchSearchList addObject:userInfo];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isSearchResult = YES;
            [self.tableView reloadData];
        });
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    return YES;
}
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    //取消
    [searchBar resignFirstResponder];
    searchBar.showsCancelButton = NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCCCUserInfo *user;
    if (self.isSearchResult == NO) {
        NSString *key = [_allKeys objectAtIndex:indexPath.section];
        NSArray *arrayForKey = [_contactsDic objectForKey:key];
        user = arrayForKey[indexPath.row];
    } else {
        user = [self.matchSearchList objectAtIndex:indexPath.row];
    }
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    };
    RCSendCardMessageView *sendCardView = [[RCSendCardMessageView alloc] initWithFrame:[[UIScreen mainScreen] bounds] ConversationType:self.conversationType targetId:self.targetId];
    RCUserInfo *cardUserInfo = [RCUserInfo new];
    cardUserInfo.userId = user.userId;
    cardUserInfo.name = user.name;
    cardUserInfo.portraitUri = user.portraitUri;
    sendCardView.cardUserInfo = cardUserInfo;
    [[RCKitUtility getKeyWindow] addSubview:sendCardView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
