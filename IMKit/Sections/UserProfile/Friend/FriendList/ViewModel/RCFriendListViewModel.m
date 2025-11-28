//
//  RCFriendListViewModel.m
//  RongUserProfile
//
//  Created by RobinCui on 2024/8/16.
//

#import "RCFriendListViewModel.h"
#import "RCUPinYinTools.h"
#import "RCKitCommonDefine.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCApplyFriendListViewController.h"
#import "RCSearchFriendsViewController.h"
#import "RCUserOnlineStatusManager.h"
#import "RCUserOnlineStatusUtil.h"
#import "RCIM.h"

static void *__rc_friendlist_operation_queueTag = &__rc_friendlist_operation_queueTag;

@interface RCFriendListViewModel()<RCSearchBarViewModelDelegate>
@property (nonatomic, strong) RCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, strong) RCSearchBarViewModel *searchBarVM;
// 全部cell
@property (nonatomic, strong) NSArray *dataSource;
// 索引
@property (nonatomic, strong) NSArray *indexTitles;
// 分组cell
@property (nonatomic, strong) NSDictionary *dicInfo;
// 常熟cell
@property (nonatomic, strong) NSArray *permanentViewModels;
// 搜索匹配cell
@property (nonatomic, strong) NSArray *matchFriendList;

// userID:cellviewmodel
@property (nonatomic, strong) NSMutableDictionary *userIDToCellViewModelMap;

@property (nonatomic, weak) UIViewController <RCListViewModelResponder> *responder;

@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation RCFriendListViewModel
@dynamic delegate;


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.queue = dispatch_queue_create("rc_friendlist_operation_queue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(self.queue, __rc_friendlist_operation_queueTag, __rc_friendlist_operation_queueTag, NULL);
        self.userIDToCellViewModelMap = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserOnlineStatusChanged:) name:RCKitUserOnlineStatusChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [RCFriendListPermanentCellViewModel registerCellForTableView:tableView];
    [RCFriendListCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
  
    id<RCCellViewModelProtocol> vm = nil;
    
    // 常规状态
    if (indexPath.section != 0) {
        NSString *key = [self.indexTitles objectAtIndex:indexPath.section-1];
        NSArray *array = [self.dicInfo objectForKey:key];
        vm = [array objectAtIndex:indexPath.row];
    } else {
        vm = [self.permanentViewModels objectAtIndex:indexPath.row];
    }
    if ([self.delegate respondsToSelector:@selector(friendListViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate friendListViewModel:self
                                       viewController:viewController
                                            tableView:tableView
                                         didSelectRow:indexPath
                                        cellViewModel:vm];
        if (ret) {
            return;
        }
    }
    [vm itemDidSelectedByViewController:viewController];
}

- (NSInteger)numberOfSections {
    NSInteger count = self.indexTitles.count;
    return count+1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    // 常规状态
    if (section == 0) {
        return self.permanentViewModels.count;
    } else {
        NSString *key = [self.indexTitles objectAtIndex:section-1];
        NSArray *array = [self.dicInfo objectForKey:key];
        return array.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    id<RCCellViewModelProtocol> vm = nil;
    // 常规状态
    if (indexPath.section != 0) {
        NSString *key = [self.indexTitles objectAtIndex:indexPath.section-1];
        NSArray *array = [self.dicInfo objectForKey:key];
        vm = [array objectAtIndex:indexPath.row];
    } else {
        vm = [self.permanentViewModels objectAtIndex:indexPath.row];
    }
    cell = [vm tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
    // 非搜索状态下的首个section高度为0
    if (section == 0 ) {
        return CGFLOAT_MIN;
    }
    return 32;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.frame = CGRectMake(0, 0, tableView.frame.size.width, 32);
    view.backgroundColor = RCDYCOLOR(0xf0f0f6, 0x000000);

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.font = [UIFont systemFontOfSize:14.f];
    title.textColor = RCDYCOLOR(0x3b3b3b, 0xA7a7a7);
    [view addSubview:title];
    
    NSString *text = nil;
    if (section != 0) {
        text = self.indexTitles[section-1];
    }
    title.text = text;
    [title sizeToFit];
    title.center = CGPointMake(13+title.bounds.size.width/2, 16);
    return view;
}

#pragma mark - SearchBar
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self showSearchFriends];
    return NO;
}

- (void)showSearchFriends {
    RCSearchFriendsViewModel *viewModel = [[RCSearchFriendsViewModel alloc] init];
    RCSearchFriendsViewController *vc = [[RCSearchFriendsViewController alloc] initWithViewModel:viewModel];
    [self.responder.navigationController pushViewController:vc animated:YES];
}
#pragma mark - Public

- (NSArray *)sectionIndexTitles {
    return self.indexTitles;
}

- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureSearchBarViewModelForFriendListViewModel:)]) {
        self.searchBarVM = [self.delegate willConfigureSearchBarViewModelForFriendListViewModel:self];
    } else if(!self.searchBarVM) {
        RCSearchBarViewModel *vm = [[RCSearchBarViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForFriendListViewModel:)]) {
        self.naviItemsVM = [self.delegate willConfigureRightNavigationItemsForFriendListViewModel:self];
    } else if(!self.naviItemsVM) {
        RCNavigationItemsViewModel *vm = [[RCNavigationItemsViewModel alloc] initWithResponder:viewController];
        self.naviItemsVM = vm;
    }

    return [self.naviItemsVM rightNavigationBarItems];
}



- (void)fetchData {
    NSMutableArray *permanents = [NSMutableArray array];    
    // 通知用户添加 常驻cell 数据
    if ([self.delegate respondsToSelector:@selector(appendPermanentCellViewModelsForFriendListViewModel:)]) {
        NSArray *vms = [self.delegate appendPermanentCellViewModelsForFriendListViewModel:self];
        if (vms.count) {
            [permanents addObjectsFromArray:vms];
        }
    }
    self.permanentViewModels = permanents;
    
    [[RCCoreClient sharedCoreClient] getFriends:RCQueryFriendsDirectionTypeBoth
                                        success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
        [self configureDataSourceWithArray:friendInfos];
        
    }
                                          error:^(RCErrorCode errorCode) {
        [self showErrorByCode:errorCode];
        [self reloadData];
    }];
}

- (BOOL)isDisplayOnlineStatus:(RCFriendListCellViewModel *)viewModel {
    if (![RCUserOnlineStatusUtil shouldDisplayOnlineStatus]) {
        return NO;
    }
    NSString *currentUserId = [RCCoreClient sharedCoreClient].currentUserInfo.userId;
    if ([currentUserId isEqualToString:viewModel.friendInfo.userId]) {
        return NO;
    }
    return YES;
}

- (void)configureDataSourceWithArray:(NSArray *)friendInfos {
    [self performOperationQueueBlock:^{
            NSArray *array = nil;
            NSMutableArray *tmp = [NSMutableArray array];
            NSMutableArray *needFetchOnlineStatusUserIds = [NSMutableArray array];
            for (RCFriendInfo *friend in friendInfos) {
                RCFriendListCellViewModel *vm = [[RCFriendListCellViewModel alloc] initWithFriend:friend];
                
                if (friend.userId.length > 0 && [self isDisplayOnlineStatus:vm]) {
                    RCSubscribeUserOnlineStatus *onlineStatus = [RCUserOnlineStatusManager.sharedManager getCachedOnlineStatus:friend.userId];
                    vm.displayOnlineStatus = YES;
                    vm.onlineStatus = onlineStatus;
                    if (!onlineStatus) {
                        [needFetchOnlineStatusUserIds addObject:friend.userId];
                    }
                }
                [tmp addObject:vm];
                if (friend.userId.length > 0) {
                    [self.userIDToCellViewModelMap setObject:vm forKey:friend.userId];
                }
            }
            array = tmp;
            if (needFetchOnlineStatusUserIds.count > 0) {
                [RCUserOnlineStatusManager.sharedManager fetchFriendOnlineStatus:needFetchOnlineStatusUserIds];
            }
            // 通知用户修改数据源
        if ([self.delegate respondsToSelector:@selector(friendListViewModel:willLoadItemsInDataSource:)]) {
                array = [self.delegate friendListViewModel:self
                                 willLoadItemsInDataSource:tmp];
            }
            [self groupAndReloadItemsInArray:array];
    }];
}

- (void)bindResponder:(UIViewController <RCListViewModelResponder>*)responder {
    self.responder = responder;
}

- (void)onUserOnlineStatusChanged:(NSNotification *)notification {
    NSArray<NSString *> *changedUserIds = notification.userInfo[RCKitUserOnlineStatusChangedUserIdsKey];
    for (NSString *userId in changedUserIds) {
        RCFriendListCellViewModel *vm = [self.userIDToCellViewModelMap objectForKey:userId];
        if (![self isDisplayOnlineStatus:vm]) {
            return;
        }
        // 匹配好友ID
        if ([vm.friendInfo.userId isEqualToString:userId]) {
            RCSubscribeUserOnlineStatus *onlineStatus = [RCUserOnlineStatusManager.sharedManager getCachedOnlineStatus:userId];
            [vm refreshOnlineStatus:onlineStatus];
        }
    }
}

#pragma mark - Private

- (void)groupAndReloadItemsInArray:(NSArray *)array {
    [self performOperationQueueBlock:^{
        // 数据源分组
        NSDictionary *dicInfo = [RCUPinYinTools sortedWithPinYinArray:array
                                                  usingBlock:^NSString * _Nonnull(RCFriendListCellViewModel * obj, NSUInteger idx) {
            return obj.friendInfo.remark.length > 0 ? obj.friendInfo.remark : obj.friendInfo.name;
        }];
        // 索引排序
        NSArray *indexTitles = [[dicInfo allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([obj1 isKindOfClass:[NSString class]]&&[obj2 isKindOfClass:[NSString class]]) {
                NSString *key1 = (NSString *)obj1;
                NSString *key2 = (NSString *)obj2;
                if ([key1 isEqualToString:@"#"]) {
                    if ([key2 isEqualToString:@"#"]) {
                        return NSOrderedSame;
                    }
                    return NSOrderedDescending;
                } else if ([key2 isEqualToString:@"#"]) {
                    return NSOrderedAscending;
                }
            }
            return [obj1 compare:obj2 options:NSNumericSearch];
        }];
       
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSource = array;
            // 都在主线程切换数据源, 避免多线程操作引起crash
            self.dicInfo = dicInfo;
            self.indexTitles = indexTitles;
            // 通知vc 刷新列表
            [self reloadData];
        });
    }];
}

- (void)reloadData {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL empty = self.dataSource.count == 0;;
            [self.responder reloadData:empty];
        });
    }
}

- (void)showErrorByCode:(RCErrorCode)code {
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder showTips:RCLocalizedString(@"FriendListFailed")];
        });
    }
}

- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(__rc_friendlist_operation_queueTag)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}
@end
