//
//  RCSearchGroupsViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSearchGroupsViewModel.h"
#import "RCGroupInfoCellViewModel.h"
#import "RCKitCommonDefine.h"

NSInteger const RCSearchGroupInfoMaxCount = 50;

static void *__rc_searchgroups_operation_queueTag = &__rc_searchgroups_operation_queueTag;



@interface RCSearchGroupsViewModel()<RCSearchBarViewModelDelegate>
@property (nonatomic, strong) RCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, strong) RCSearchBarViewModel *searchBarVM;
// 全部cell
@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, weak) UIViewController<RCListViewModelResponder>* responder;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) RCPagingQueryOption *option;
@property (nonatomic, copy) NSString *keyword;
@end

@implementation RCSearchGroupsViewModel
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
    self.queue = dispatch_queue_create("__rc_searchgroups_operation_queueTag", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(self.queue, __rc_searchgroups_operation_queueTag, __rc_searchgroups_operation_queueTag, NULL);
    self.dataSource = [NSMutableArray array];
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [RCGroupInfoCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    id<RCCellViewModelProtocol> vm = [self.dataSource objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(searchGroupsViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate searchGroupsViewModel:self
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
    return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<RCCellViewModelProtocol> vm = [self.dataSource objectAtIndex:indexPath.row];
    UITableViewCell *cell = [vm tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell;
}


#pragma mark - SearchBar
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText isEqualToString:self.keyword]) {
        return;
    }
    self.option.pageToken = nil;
    self.keyword = searchText;
    if (searchText.length == 0) {
        [self restoreData];
    } else {
        [self.dataSource removeAllObjects];
        [self reloadData:NO];
        [self fetchDataWithKeyword:searchText];
    }
}
- (void)setKeyword:(NSString *)keyword {
    if (![_keyword isEqualToString:keyword]) {
        _keyword = keyword;
    }
}

- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching {
    if (inSearching && searchBar.text.length > 0) {
        BOOL empty = self.dataSource.count == 0;
        [self reloadData:empty];
    } else {
        [self restoreData];
    }
}

#pragma mark - Public

- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureSearchBarViewModelForSearchGroupsViewModel:)]) {
        RCSearchBarViewModel *searchBarVM = [self.delegate willConfigureSearchBarViewModelForSearchGroupsViewModel:self];
        searchBarVM.delegate = self;
        self.searchBarVM = searchBarVM;
    } else if(!self.searchBarVM) {
        RCSearchBarViewModel *vm = [[RCSearchBarViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForSearchGroupsViewModel:)]) {
        self.naviItemsVM = [self.delegate willConfigureRightNavigationItemsForSearchGroupsViewModel:self];
    }
    return [self.naviItemsVM rightNavigationBarItems];
}

- (void)endEditingState {
    [self.searchBarVM endEditingState];
    [self restoreData];
}

- (void)fetchDataWithKeyword:(NSString *)keyword {
    if (keyword == nil) {
        [self refreshingFinished:YES withTips:nil];
        return;
    }
    if (self.option == nil) {
        self.option = [RCPagingQueryOption new];
        self.option.count = RCSearchGroupInfoMaxCount;
    }
    [self performOperationQueueBlock:^{
        [[RCCoreClient sharedCoreClient] searchJoinedGroups:keyword option:self.option success:^(RCPagingQueryResult<RCGroupInfo *> * _Nonnull result) {
            if (result.pageToken.length != 0) {
                self.option.pageToken = result.pageToken;
            }
            NSArray *infos = result.data;
            NSMutableArray *array = [NSMutableArray array];
            NSArray *items = @[];
            if (infos.count) {
                for (RCGroupInfo *info in infos) {
                    RCGroupInfoCellViewModel *vm = [[RCGroupInfoCellViewModel alloc] initWithGroupInfo:info keyword:keyword];
                    [array addObject:vm];
                }
                items = array;
                if ([self.delegate respondsToSelector:@selector(searchGroupsViewModel:willLoadItemsInDataSource:)]) {
                    items = [self.delegate searchGroupsViewModel:self willLoadItemsInDataSource:array];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dataSource addObjectsFromArray:items];
                [self reloadData:self.dataSource.count == 0];
            });
        
            [self refreshingFinished:YES withTips:nil];
        } error:^(RCErrorCode errorCode) {
            [self refreshingFinished:YES withTips:RCLocalizedString(@"GroupListFailed")];

        }];
    }];
}

- (void)bindResponder:(UIViewController<RCListViewModelResponder> *)responder {
    self.responder = responder;
}

- (void)loadMoreData {
    [self fetchDataWithKeyword:self.keyword];
}
#pragma mark - Private

- (void)restoreData {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.option.pageToken = nil;
        self.keyword = nil;
        [self.dataSource removeAllObjects];
        // 通知vc 刷新列表
        [self reloadData:NO];
    });}


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

- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(__rc_searchgroups_operation_queueTag)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}
@end
