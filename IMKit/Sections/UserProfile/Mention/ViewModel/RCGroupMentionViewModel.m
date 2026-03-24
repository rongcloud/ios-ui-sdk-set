//
//  RCGroupMentionViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2025/11/19.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCGroupMentionViewModel.h"
#import "RCGroupMemberCell.h"
#import "RCGroupManager.h"
#import "RCKitCommonDefine.h"

NSString  * const RCMentionAllUsersID = @"All";

@interface RCGroupMentionViewModel ()<RCSearchBarViewModelDelegate>


@property (nonatomic, strong) NSMutableArray <RCGroupMemberCellViewModel *>*mutableMemberList;

@property (nonatomic, strong) NSMutableArray <RCGroupMemberCellViewModel *>*matchMemberList;

@property (nonatomic, strong) NSMutableArray <NSMutableArray *>*mutableMemberDataSource;
@property (nonatomic, strong) NSMutableArray <NSMutableArray *>*matchMemberDataSource;
@property (nonatomic, strong) NSMutableArray <NSMutableArray *>*dataSource;

@property (nonatomic, strong) RCSearchBarViewModel *searchBarVM;

@property (nonatomic, strong) RCPagingQueryResult *queryResult;

@property (nonatomic, strong) RCPagingQueryResult *searchQueryResult;

@property (nonatomic, weak) id<RCListViewModelResponder> responder;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, assign) BOOL isLoadingMembers;

@property (nonatomic, assign) BOOL isLoadingSearchMembers;

@property (nonatomic, weak) RCBaseCellViewModel *lastBottomCellVM;

@property (nonatomic, strong) RCGroupMemberCellViewModel *mentionAllCellVM;

@property (nonatomic, copy) void (^selectedBlock)(RCUserInfo *selectedUserInfo);
@property (nonatomic, copy) void (^cancelBlock)(void);
@end

@implementation RCGroupMentionViewModel
@dynamic delegate;

+ (instancetype)viewModelWithGroupId:(NSString *)groupId
                       selectedBlock:(void (^)(RCUserInfo *selectedUserInfo))selectedBlock
                              cancel:(void (^)(void))cancelBlock{
    RCGroupMentionViewModel *viewModel = [[self.class alloc] init];
    viewModel.groupId = groupId;
    viewModel.selectedBlock = selectedBlock;
    viewModel.cancelBlock = cancelBlock;
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.pageCount = 50;
    }
    return self;
}

- (UISearchBar *)configureSearchBar {
    return self.searchBarVM.searchBar;
}

- (RCSearchBarViewModel *)searchBarVM {
    if (!_searchBarVM) {
        _searchBarVM =  [[RCSearchBarViewModel alloc] init];
        _searchBarVM.delegate = self;
    }
    return _searchBarVM;
}

- (void)fetchGroupMembersByPage {
    if ([self.searchBarVM isCurrentFirstResponder]) {
        [self filterDataSourceWithQueryResult:self.searchQueryResult];
    } else {
        [self fetchGroupMembers];
    }
}

- (void)endEditingState {
    self.searchQueryResult = nil;
    [self.matchMemberList removeAllObjects];
    [self.searchBarVM endEditingState];
}

- (void)bindResponder:(id<RCListViewModelResponder>)responder {
    self.responder = responder;
}

- (void)selectionCanceled {
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

#pragma mark - RCFriendListSearchBarViewModelDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchQueryResult = nil;
    [self.matchMemberList removeAllObjects];
    if (searchText.length == 0) {
        [self removeSeparatorWithArray:self.memberList];
        [self reloadData:NO];
    } else {
        [self filterDataSourceWithQueryResult:nil];
    }
}

- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching {
    if (!inSearching) {
        [self endEditingState];
        [self reloadData:NO];
    }
}

- (void)reloadData:(BOOL)empty {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        [self.responder reloadData:empty];
    }

}
#pragma mark -- RCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCGroupMemberCell class]
      forCellReuseIdentifier:RCGroupMemberCellIdentifier];
}

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    RCGroupMemberCellViewModel *cellViewModel = [self memberAtIndexPath:indexPath];
    if (self.selectedBlock) {
        RCUserInfo *info = [RCUserInfo new];
        info.userType = RCUserTypeNormal;
        info.userId = cellViewModel.memberInfo.userId;
        
        info.name = cellViewModel.memberInfo.nickname.length>0 ?cellViewModel.memberInfo.nickname : cellViewModel.memberInfo.name;
        info.portraitUri = cellViewModel.memberInfo.portraitUri;
        self.selectedBlock(info);
    }
}

- (NSInteger)numberOfSections {
    return self.dataSource.count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    if (self.dataSource.count > section) {
        NSArray *array = self.dataSource[section];
        return array.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupMemberCellViewModel *vm = [self memberAtIndexPath:indexPath];
    return [vm tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupMemberCellViewModel *vm = [self memberAtIndexPath:indexPath];
    return [vm tableView:tableView heightForRowAtIndexPath:indexPath];;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
    return section == 0 ? 0.01: 20;
}
#pragma mark -- private
- (RCGroupMemberCellViewModel *)memberAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *array = self.dataSource[indexPath.section];
    if (array.count> indexPath.row) {
        RCGroupMemberCellViewModel *vm = array[indexPath.row];
        return vm;
    }
    return nil;
}

- (void)removeSeparatorWithArray:(NSArray *)array {
    if (array.count) {
        if ([self.lastBottomCellVM isKindOfClass:[RCBaseCellViewModel class]]) {// 上一屏的最后一个cell
            self.lastBottomCellVM.hideSeparatorLine = NO;
        }
        [self removeSeparatorLineIfNeed:@[array]];
        self.lastBottomCellVM = array.lastObject;
    }
}

- (void)filterDataSourceWithQueryResult:(RCPagingQueryResult *)result {
    // 添加搜索加载状态检查，防止并发请求
    if (self.isLoadingSearchMembers) {
        return;
    }
    
    if (self.searchQueryResult && self.searchQueryResult.pageToken.length == 0) {
        return;
    }
    
    // 设置搜索加载状态
    self.isLoadingSearchMembers = YES;
    
    RCPagingQueryOption *option = [RCPagingQueryOption new];
    option.pageToken = self.searchQueryResult.pageToken;
    option.count = self.pageCount;
    [[RCCoreClient sharedCoreClient] searchGroupMembers:self.groupId name:self.searchBarVM.searchBar.text option:option success:^(RCPagingQueryResult<RCGroupMemberInfo *> * _Nonnull result) {
        NSArray *list = [self getViewModelsWithMembers:result.data];
        dispatch_async(dispatch_get_main_queue(), ^{
            // 重置搜索加载状态并更新数据
            self.isLoadingSearchMembers = NO;
            self.searchQueryResult = result;
            [self.matchMemberList addObjectsFromArray:list];
            [self removeSeparatorWithArray:list];
            [self reloadData:self.matchMemberList.count == 0];
        });
    } error:^(RCErrorCode errorCode) {
        // 重置搜索加载状态
        self.isLoadingSearchMembers = NO;
    }];
}

- (void)fetchGroupMembers {
    // 添加加载状态检查，防止并发请求
    if (self.isLoadingMembers) {
        return;
    }
    
    if (self.queryResult && self.queryResult.pageToken.length == 0) {
        return;
    }
    
    // 设置加载状态
    self.isLoadingMembers = YES;
    
    RCPagingQueryOption *option = [RCPagingQueryOption new];
    option.pageToken = self.queryResult.pageToken;
    option.count = self.pageCount;
    RCGroupMemberRole role;
    // 第一页要先拉取群主，管理员，queryResult 存在证明已经拉取过第一页，分页拉取只需拉取普通成员
    if (self.queryResult) {
        role = RCGroupMemberRoleNormal;
    } else {
        role = RCGroupMemberRoleUndef;
    }
    option.order = YES;
    [RCGroupManager getGroupMembers:self.groupId option:option role:role complete:^(RCPagingQueryResult<RCGroupMemberInfo *> * _Nonnull result) {
        if (result.data.count == 0) {
            // 重置加载状态
            self.isLoadingMembers = NO;
            return;
        }
        
        NSArray *list = [self getViewModelsWithMembers:result.data];
        dispatch_async(dispatch_get_main_queue(), ^{
            // 重置加载状态并更新数据
            self.isLoadingMembers = NO;
            self.queryResult = result;
            [self.mutableMemberList addObjectsFromArray:list];
            [self removeSeparatorWithArray:list];
            [self.responder reloadData:NO];
        });
    }];
}

- (NSArray<RCGroupMemberCellViewModel *> *)getViewModelsWithMembers:(NSArray<RCGroupMemberInfo *> *)members {
    NSMutableArray *list = [NSMutableArray array];
    for (RCGroupMemberInfo *member in members) {
        member.role = RCGroupMemberRoleUndef;
        RCGroupMemberCellViewModel *cellVM = [[RCGroupMemberCellViewModel alloc] initWithMember:member];
        cellVM.hiddenArrow = YES;
        [list addObject:cellVM];
    }

    return list;
}

#pragma mark -- setter

- (void)setPageCount:(NSInteger)pageCount {
    if (pageCount <= 0) {
        return;
    } else if (pageCount > 100) {
        pageCount = 100;
    }
    _pageCount = pageCount;
}

#pragma mark -- getter

- (NSArray<RCGroupMemberCellViewModel *> *)memberList {
    if (self.searchBarVM.searchBar.text.length > 0) {
        return self.matchMemberList;
    }
    return self.mutableMemberList;
}

- (NSMutableArray<RCGroupMemberCellViewModel *> *)matchMemberList {
    if (!_matchMemberList) {
        _matchMemberList = [NSMutableArray array];
    }
    return _matchMemberList;
}

- (NSMutableArray<RCGroupMemberCellViewModel *> *)mutableMemberList {
    if (!_mutableMemberList) {
        _mutableMemberList = [NSMutableArray array];
    }
    return _mutableMemberList;
}

- (NSMutableArray<NSMutableArray *> *)mutableMemberDataSource {
    if (!_mutableMemberDataSource) {
        _mutableMemberDataSource = [NSMutableArray array];
        if (self.mentionAllCellVM) {
            NSMutableArray *array = [NSMutableArray array];
            [array addObject:self.mentionAllCellVM];
            [_mutableMemberDataSource addObject:array];
        }
        if (self.mutableMemberList) {
            [_mutableMemberDataSource addObject:self.mutableMemberList];
        }
    }
    return _mutableMemberDataSource;
}

- (NSMutableArray<NSMutableArray *> *)matchMemberDataSource {
    if (!_matchMemberDataSource) {
        _matchMemberDataSource = [NSMutableArray array];
       
        if (self.matchMemberList) {
            [_matchMemberDataSource addObject:self.matchMemberList];
        }
    }
    return _matchMemberDataSource;
}

- (NSMutableArray<NSMutableArray *> *)dataSource {
    if (self.searchBarVM.searchBar.text.length > 0) {
        return self.matchMemberDataSource;
    }
    return self.mutableMemberDataSource;
}

- (RCGroupMemberCellViewModel *)mentionAllCellVM {
    if (!_mentionAllCellVM) {
        RCGroupMemberInfo *all = [[RCGroupMemberInfo alloc] init];
        all.userId = RCMentionAllUsersID;
        all.name = RCLocalizedString(@"GroupMentionAll");
        all.role = RCGroupMemberRoleUndef;
        _mentionAllCellVM = [[RCGroupMemberCellViewModel alloc] initWithMember:all];
        _mentionAllCellVM.hiddenArrow = YES;
        _mentionAllCellVM.hideSeparatorLine = YES;
        _mentionAllCellVM.cellPortraitImage = RCDynamicImage(@"group_mention_all_img", @"group_mention_all");
        _mentionAllCellVM.remark = RCLocalizedString(@"GroupMentionAll");
    }
    return _mentionAllCellVM;
}

@end
