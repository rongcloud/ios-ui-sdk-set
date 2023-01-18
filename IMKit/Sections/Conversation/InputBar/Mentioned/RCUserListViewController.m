//
//  RCUserListViewController.m
//  RongExtensionKit
//
//  Created by 杜立召 on 16/7/14.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCUserListViewController.h"
#import "RCKitCommonDefine.h"
#import "RCExtensionService.h"
#import "RCUserListTableViewCell.h"
#import "RCKitConfig.h"
#import "RCloudImageView.h"

@interface RCUserListViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate,
                                        UISearchControllerDelegate, UISearchResultsUpdating> {
    NSMutableArray *_tempOtherArr;
    NSMutableDictionary *allUsers;
    NSArray *allKeys;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, strong) UISearchController *searchController; //搜索VC
@property (nonatomic, strong) dispatch_queue_t sortDataQueue;

@end

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@implementation RCUserListViewController {
    NSMutableArray *_searchResultArr; //搜索结果Arr
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.definesPresentationContext = YES;
    self.tableView.backgroundColor = RCDYCOLOR(0xffffff, 0x000000);
    [self registerUserInfoObserver];
    if ([self respondsToSelector:@selector(setExtendedLayoutIncludesOpaqueBars:)]) {
        [self setExtendedLayoutIncludesOpaqueBars:YES];
    }
    self.sortDataQueue = dispatch_queue_create("com.rongcloud.selectingSortDataQueue", NULL);

    allUsers = [NSMutableDictionary new];
    allKeys = [NSMutableArray new];
    self.dataArr = [NSMutableArray array];
    allUsers = nil; //[self sortedArrayWithPinYinDic:self.dataArr];
    [self.tableView reloadData];

    [self.dataSource getSelectingUserIdList:^(NSArray<NSString *> *userIdList) {
        [self loadAllUserInfoList:userIdList];
    }];

    // configNav
    [self configNav];
    //布局View
    [self setUpView];
    _searchResultArr = [NSMutableArray array];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // section
    if (self.searchController.active) {
        return 1;
    } else {
        return allKeys.count;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // row
    if (self.searchController.active) {
        return _searchResultArr.count;
    } else {
        NSString *key = [allKeys objectAtIndex:section];
        NSArray *arr = [allUsers objectForKey:key];
        return [arr count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCKitConfigCenter.ui.globalMessagePortraitSize.height + 5 + 5;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.searchController.active) {
        return allKeys;
    } else {
        return nil;
    }
}
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIde = @"cellIde";
    RCUserListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIde];
    if (cell == nil) {
        cell = [[RCUserListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIde];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    RCUserInfo *user = nil;
    if (self.searchController.active) {
        user = _searchResultArr[indexPath.row];
    } else {
        NSString *key = [allKeys objectAtIndex:indexPath.section];
        NSArray *arrayForKey = [allUsers objectForKey:key];
        user = arrayForKey[indexPath.row];
    }

    [cell.nameLabel setText:[RCKitUtility getDisplayName:user]];
    cell.headImageView = [self portraitView:[NSURL URLWithString:user.portraitUri]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCUserInfo *user;
    if (self.searchController.active) {
        user = _searchResultArr[indexPath.row];
    } else {
        NSString *key = [allKeys objectAtIndex:indexPath.section];
        NSArray *arrayForKey = [allUsers objectForKey:key];
        user = arrayForKey[indexPath.row];
    }
    if (self.selectedBlock) {
        self.selectedBlock(user);
    }
    [self.searchController.searchBar resignFirstResponder];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - searchController delegate

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self filterContentForSearchText:self.searchController.searchBar.text scope:nil];
}

#pragma mark - Notification
- (void)registerUserInfoObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserInfoUpdate:)
                                                 name:@"RCKitDispatchUserInfoUpdateNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserInfoUpdate:)
                                                 name:@"RCKitDispatchGroupUserInfoUpdateNotification"
                                               object:nil];
}

- (void)onUserInfoUpdate:(NSNotification *)notification {
    NSString *userId = notification.object[@"userId"];
    __block RCUserInfo *needUpdateUserInfo = nil;
    NSArray *safeArray = [self.dataArr copy];
    for (RCUserInfo *userInfo in safeArray) {
        if ([userInfo.userId isEqualToString:userId]) {
            needUpdateUserInfo = userInfo;
            break;
        }
    }
    if (needUpdateUserInfo) {
        dispatch_async(self.sortDataQueue, ^{
            RCUserInfo *userInfo = [self.dataSource getSelectingUserInfo:needUpdateUserInfo.userId];
            needUpdateUserInfo.name = [RCKitUtility getDisplayName:userInfo];
            needUpdateUserInfo.portraitUri = userInfo.portraitUri;
            NSMutableDictionary *tmpDict = [self sortedArrayWithPinYinDic:self.dataArr];
            dispatch_async(dispatch_get_main_queue(), ^{
                allUsers = tmpDict;
                allKeys = [[tmpDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {

                    return [obj1 compare:obj2 options:NSNumericSearch];
                }];
                [self.tableView reloadData];
            });
        });
    }
}

#pragma mark - Private Methods
- (void)setUpView {
    [self.view addSubview:self.tableView];
}

- (void)loadAllUserInfoList:(NSArray *)userIdList {
    dispatch_async(self.sortDataQueue, ^{
        [self.dataArr removeAllObjects];
        for (NSString *userId in userIdList) {
            if (![userId isEqualToString:[RCIMClient sharedRCIMClient].currentUserInfo.userId]) {
                RCUserInfo *userInfo = [self.dataSource getSelectingUserInfo:userId];
                if (userInfo) {
                    [self.dataArr addObject:userInfo];
                } else {
                    [self.dataArr addObject:[[RCUserInfo alloc] initWithUserId:userId name:nil portrait:nil]];
                }
            }
        }

        NSMutableDictionary *tmpDict = [self sortedArrayWithPinYinDic:self.dataArr];
        dispatch_async(dispatch_get_main_queue(), ^{
            allUsers = tmpDict;
            allKeys = [[tmpDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {

                return [obj1 compare:obj2 options:NSNumericSearch];
            }];

            [self.tableView reloadData];
        });
    });
}

- (void)configNav {
    self.navigationItem.title = self.navigationTitle;
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:RCLocalizedString(@"Cancel")
                                                                   style:(UIBarButtonItemStylePlain)
                                                                  target:self
                                                                  action:@selector(leftBarButtonItemPressed:)];
    [self.navigationItem setLeftBarButtonItem:leftButton];
}

- (void)leftBarButtonItemPressed:(id)sender {
    if (_cancelBlock) {
        _cancelBlock();
    }
    [self.searchController.searchBar resignFirstResponder];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// 源字符串内容是否包含或等于要搜索的字符串内容
- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope {
    NSMutableArray *tempResults = [NSMutableArray array];
    NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    NSArray *safeArray = [self.dataArr copy];
    for (int i = 0; i < safeArray.count; i++) {
        NSString *storeString = [(RCUserInfo *)safeArray[i] name];
        NSRange storeRange = NSMakeRange(0, storeString.length);

        NSRange foundRange = [storeString rangeOfString:searchText options:searchOptions range:storeRange];
        if (foundRange.length) {
            [tempResults addObject:safeArray[i]];
        }
    }
    [_searchResultArr removeAllObjects];
    [_searchResultArr addObjectsFromArray:tempResults];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)friends {
    if (!friends)
        return nil;
    NSArray *_keys = @[
        @"A",
        @"B",
        @"C",
        @"D",
        @"E",
        @"F",
        @"G",
        @"H",
        @"I",
        @"J",
        @"K",
        @"L",
        @"M",
        @"N",
        @"O",
        @"P",
        @"Q",
        @"R",
        @"S",
        @"T",
        @"U",
        @"V",
        @"W",
        @"X",
        @"Y",
        @"Z",
    ];

    NSMutableDictionary *returnDic = [NSMutableDictionary new];
    _tempOtherArr = [NSMutableArray new];
    BOOL isReturn = NO;

    for (NSString *key in _keys) {

        if ([_tempOtherArr count]) {
            isReturn = YES;
        }

        NSMutableArray *tempArr = [NSMutableArray new];
        for (RCUserInfo *user in friends) {
            NSString *pyResult = [RCKitUtility getPinYinUpperFirstLetters:[RCKitUtility getDisplayName:user]];
            if (pyResult.length <= 0) {
                if (!isReturn) {
                    [_tempOtherArr addObject:user];
                }
                continue;
            }

            NSString *firstLetter = [pyResult substringToIndex:1];
            if ([firstLetter isEqualToString:key]) {
                [tempArr addObject:user];
            }

            if (isReturn)
                continue;
            char c = [pyResult characterAtIndex:0];
            if (isalpha(c) == 0) {
                [_tempOtherArr addObject:user];
            }
        }
        if (![tempArr count])
            continue;
        [returnDic setObject:tempArr forKey:key];
    }
    if ([_tempOtherArr count])
        [returnDic setObject:_tempOtherArr forKey:@"#"];

    return returnDic;
}


- (UIImageView *)portraitView:(NSURL *)portraitURL {
    RCloudImageView *portraitView = [[RCloudImageView alloc] init];
    portraitView.frame = CGRectMake(10.0, 5.0, RCKitConfigCenter.ui.globalMessagePortraitSize.width,
                                    RCKitConfigCenter.ui.globalMessagePortraitSize.height);

    [portraitView setPlaceholderImage:RCResourceImage(@"default_portrait_msg")];
    [portraitView setImageURL:portraitURL];

    if (RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_RECTANGLE) {
        portraitView.layer.cornerRadius = RCKitConfigCenter.ui.portraitImageViewCornerRadius;
    } else if (RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
        portraitView.layer.cornerRadius = RCKitConfigCenter.ui.globalMessagePortraitSize.height / 2;
    }
    portraitView.layer.masksToBounds = YES;
    portraitView.contentMode = UIViewContentModeScaleAspectFill;

    return portraitView;
}

#pragma mark - Getters and Setters
- (UISearchController *)searchController {
    if (!_searchController) {
        _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        _searchController.delegate = self;
        [_searchController.searchBar sizeToFit];
        _searchController.searchResultsUpdater = self;
        //提醒字眼
        _searchController.searchBar.placeholder = RCLocalizedString(@"ToSearch");
        [_searchController.searchBar setKeyboardType:UIKeyboardTypeDefault];
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

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, kScreenWidth, kScreenHeight)
                                                  style:UITableViewStyleGrouped];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
        [_tableView setSectionIndexColor:[UIColor darkGrayColor]];
        [_tableView setBackgroundColor:[UIColor colorWithRed:240.0 / 255 green:240.0 / 255 blue:240.0 / 255 alpha:1]];
        // cell无数据时，不显示间隔线
        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        [_tableView setTableFooterView:v];
        _tableView.tableHeaderView = self.searchController.searchBar;
    }
    return _tableView;
}

@end
