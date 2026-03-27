//
//  RCMyGroupsViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCMyGroupsViewModel.h"
#import "RCGroupInfoCellViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCSearchGroupsViewController.h"

NSInteger const RCGroupInfoMaxCount = 50;

static void *__rc_mygroups_operation_queueTag = &__rc_mygroups_operation_queueTag;

@interface RCMyGroupsViewModel()<RCSearchBarViewModelDelegate>

@property (nonatomic, strong) RCSearchBarViewModel *searchBarVM;
// 全部cell
@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, weak) UIViewController <RCListViewModelResponder> *responder;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) RCPagingQueryOption *option;
@end

@implementation RCMyGroupsViewModel
@dynamic delegate;

- (instancetype)initWithOption:(nullable RCPagingQueryOption *)option {
    self = [super init];
    if (self) {
        [self ready];
        self.option = option;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self ready];
    }
    return self;
}
- (void)ready {
    self.dataSource = [NSMutableArray array];
    self.queue = dispatch_queue_create("rc_mygroups_operation_queueTag", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(self.queue, __rc_mygroups_operation_queueTag, __rc_mygroups_operation_queueTag, NULL);
}

/// 配置导航
- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForMyGroupsViewModel:)]) {
        RCNavigationItemsViewModel *naviItemsVM = [self.delegate willConfigureRightNavigationItemsForMyGroupsViewModel:self];
        return [naviItemsVM rightNavigationBarItems];

    }
    return nil;
}

/// 配置 searchBar
- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureSearchBarViewModelForMyGroupsViewModel:)]) {
        self.searchBarVM = [self.delegate willConfigureSearchBarViewModelForMyGroupsViewModel:self];
    } else if(!self.searchBarVM) {
        RCSearchBarViewModel *vm = [[RCSearchBarViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

/// 获取数据
- (void)fetchData {
    if (!self.option) {
        RCPagingQueryOption *opt = [[RCPagingQueryOption alloc] init];
        opt.count = RCGroupInfoMaxCount;
        self.option = opt;
    }
    [self.dataSource removeAllObjects];
    [self fetchDataWithOption:self.option];
}

/// 绑定响应器
- (void)bindResponder:(UIViewController <RCListViewModelResponder>*)responder {
    self.responder = responder;
}

/// cell 高度
/// - Parameters:
///   - tableView: tableView
///   - indexPath: indexPath
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

/// 加载更多
- (void)loadMoreData {
    [self fetchDataWithOption:self.option];
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupInfoCellViewModel *vm = [self.dataSource objectAtIndex:indexPath.row];
    return [vm tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    RCGroupInfoCellViewModel *vm = [self.dataSource objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(myGroupsViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate myGroupsViewModel:self
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

#pragma mark - Protocol
- (void)registerCellForTableView:(UITableView *)tableView {
    [RCGroupInfoCellViewModel registerCellForTableView:tableView];
}

- (NSInteger)numberOfSections {
    return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

#pragma mark - SearchBar
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self showSearchGroups];
    return NO;
}

- (void)showSearchGroups {
    RCSearchGroupsViewModel *viewModel = [[RCSearchGroupsViewModel alloc] init];
    RCSearchGroupsViewController *vc = [[RCSearchGroupsViewController alloc] initWithViewModel:viewModel];
    [self.responder.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Private

- (void)fetchDataWithOption:(RCPagingQueryOption *)option {
    self.option = option;
    [self performOperationQueueBlock:^{
        [[RCCoreClient sharedCoreClient] getJoinedGroupsByRole:RCGroupMemberRoleUndef option:option success:^(RCPagingQueryResult<RCGroupInfo *> * _Nonnull result) {
            if (result.pageToken.length != 0) {
                self.option.pageToken = result.pageToken;
            }
            NSArray *infos = result.data;
            NSMutableArray *array = [NSMutableArray array];
            NSArray *items = @[];
            if (infos.count) {
                for (RCGroupInfo *info in infos) {
                    RCGroupInfoCellViewModel *vm = [[RCGroupInfoCellViewModel alloc] initWithGroupInfo:info keyword:@""];
                    [array addObject:vm];
                }
                items = array;
                if ([self.delegate respondsToSelector:@selector(myGroupsViewModel:willLoadItemsInDataSource:)]) {
                    items = [self.delegate myGroupsViewModel:self willLoadItemsInDataSource:array];
                }
            }
            [self.dataSource addObjectsFromArray:items];
            [self reloadData:self.dataSource.count == 0];
            [self refreshingFinished:YES withTips:nil];
            } error:^(RCErrorCode errorCode) {
                [self refreshingFinished:NO
                                withTips:RCLocalizedString(@"GroupListFailed")];

            }];
    }];
  
}

- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(__rc_mygroups_operation_queueTag)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}


- (void)reloadData:(BOOL)showEmpty {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder reloadData:showEmpty];
        });
    }
}

- (void)showTips:(NSString *)tips {
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder showTips:tips];
        });
    }
}

- (void)refreshingFinished:(BOOL)success withTips:(NSString *)tips {
    if ([self.responder respondsToSelector:@selector(refreshingFinished:withTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder refreshingFinished:success withTips:tips];
        });
    }
}
#pragma mark - Setter
- (void)setOption:(RCPagingQueryOption *)option {
    if (_option != option) {
        _option = option;
    }
}

@end
