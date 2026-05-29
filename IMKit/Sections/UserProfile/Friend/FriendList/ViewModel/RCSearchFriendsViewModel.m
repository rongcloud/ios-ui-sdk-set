//
//  RCSearchFriendsViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/9/4.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSearchFriendsViewModel.h"
#import "RCUPinYinTools.h"
#import "RCKitCommonDefine.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCApplyFriendListViewController.h"

static void *__rc_friendlist_search_operation_queueTag = &__rc_friendlist_search_operation_queueTag;

@interface RCSearchFriendsViewModel()<RCSearchBarViewModelDelegate>
@property (nonatomic, strong) RCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, strong) RCSearchBarViewModel *searchBarVM;
// 全部cell
@property (nonatomic, strong) NSArray *dataSource;

@property (nonatomic, weak) id<RCListViewModelResponder> responder;

@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation RCSearchFriendsViewModel
@dynamic delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.queue = dispatch_queue_create("__rc_friendlist_search_operation_queueTag", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(self.queue, __rc_friendlist_search_operation_queueTag, __rc_friendlist_search_operation_queueTag, NULL);
    }
    return self;
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [RCFriendListCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    id<RCCellViewModelProtocol> vm = [self.dataSource objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(searchFriendsViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate searchFriendsViewModel:self
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
    if (searchText.length == 0) {
        [self restoreData];
    } else {
        [self fetchDataWithKeyword:searchText];
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

- (NSArray *)sectionIndexTitles {
    return @[];
}

- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureSearchBarViewModelForSearchFriendsViewModel:)]) {
        self.searchBarVM = [self.delegate willConfigureSearchBarViewModelForSearchFriendsViewModel:self];
    } else if(!self.searchBarVM) {
        RCSearchBarViewModel *vm = [[RCSearchBarViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForSearchFriendsViewModel:)]) {
        self.naviItemsVM = [self.delegate willConfigureRightNavigationItemsForSearchFriendsViewModel:self];
    }
    return [self.naviItemsVM rightNavigationBarItems];
}

- (void)endEditingState {
    [self.searchBarVM endEditingState];
    [self restoreData];
}

- (void)fetchDataWithKeyword:(NSString *)keyword {
    [[RCCoreClient sharedCoreClient] searchFriendsInfo:keyword success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
        [self configureDataSourceWithArray:friendInfos];
    } error:^(RCErrorCode errorCode) {
        [self showErrorByCode:errorCode];
        [self reloadData:NO];
    }];
    
}

- (void)configureDataSourceWithArray:(NSArray *)friendInfos {
    [self performOperationQueueBlock:^{
            NSArray *array = nil;
            NSMutableArray *tmp = [NSMutableArray array];
            
            for (RCFriendInfo *friend in friendInfos) {
                RCFriendListCellViewModel *vm = [[RCFriendListCellViewModel alloc] initWithFriend:friend];
                [tmp addObject:vm];
            }
            array = tmp;
            // 通知用户修改数据源
        if ([self.delegate respondsToSelector:@selector(searchFriendsViewModel:willLoadItemsInDataSource:)]) {
            array = [self.delegate searchFriendsViewModel:self
                                willLoadItemsInDataSource:tmp];
            }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSource = array;
            // 通知vc 刷新列表
            [self reloadData:array.count==0];
        });
    }];
}

- (void)bindResponder:(id<RCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark - Private

- (void)restoreData {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataSource = @[];
        // 通知vc 刷新列表
        [self reloadData:NO];
    });}

- (void)reloadData:(BOOL)isEmpty {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{

            [self.responder reloadData:isEmpty];
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
    if (dispatch_get_specific(__rc_friendlist_search_operation_queueTag)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}
@end
