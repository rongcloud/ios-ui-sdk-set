//
//  RCGroupRemoveMembersViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/27.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCRemoveGroupMembersViewModel.h"
#import "RCRemoveGroupMemberCellViewModel.h"
#import "RCGroupManager.h"
#import "RCAlertView.h"
#import "RCKitCommonDefine.h"
@interface RCRemoveGroupMembersViewModel ()<RCSearchBarViewModelDelegate>

@property (nonatomic, strong) NSMutableArray <RCRemoveGroupMemberCellViewModel *>*mutableMemberList;

@property (nonatomic, strong) NSMutableArray <RCRemoveGroupMemberCellViewModel *>*matchMemberList;

@property (nonatomic, strong) NSMutableArray <NSString *>*selectUserIds;

@property (nonatomic, strong) RCSearchBarViewModel *searchBarVM;

@property (nonatomic, strong) RCPagingQueryResult *queryResult;

@property (nonatomic, strong) RCPagingQueryResult *searchQueryResult;

@property (nonatomic, weak) id<RCListViewModelResponder> responder;

@property (nonatomic, assign) NSInteger pageCount;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, strong) RCGroupInfo *group;

@end

@implementation RCRemoveGroupMembersViewModel

@dynamic delegate;

+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    RCRemoveGroupMembersViewModel *viewModel = [[self.class alloc] init];
    viewModel.groupId = groupId;
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.pageCount = 100;
        self.maxSelectCount = 30;
    }
    return self;
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

#pragma mark - RCFriendListSearchBarViewModelDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchQueryResult = nil;
    [self.matchMemberList removeAllObjects];
    if (searchText.length == 0) {
        [self.responder reloadData:NO];
    } else {
        [self filterDataSourceWithQueryResult:nil];
    }
}

- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching {
    if (!inSearching) {
        [self endEditingState];
    }
    [self.responder reloadData:NO];
}

#pragma mark -- RCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [RCRemoveGroupMemberCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController *)viewController tableView:(UITableView *)tableView didSelectRow:(NSIndexPath *)indexPath {
    RCRemoveGroupMemberCellViewModel *vm = (RCRemoveGroupMemberCellViewModel *)self.memberList[indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(groupRemoveMembers:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate groupRemoveMembers:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:vm];
        if (intercept) {
            return;
        }
    }
    
    if (vm.selectState != RCSelectStateDisable){
        if ((vm.selectState == RCSelectStateUnselect) && self.selectUserIds.count >= self.maxSelectCount) {
            [RCAlertView showAlertController:nil message:[NSString stringWithFormat:RCLocalizedString(@"GroupMemberSelectMaxTip"), @(self.maxSelectCount)] hiddenAfterDelay:2];
            return;
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [vm updateCell:cell state:(vm.selectState ? RCSelectStateUnselect : RCSelectStateSelect)];
        if (vm.selectState == RCSelectStateSelect) {
            [self.selectUserIds addObject:vm.member.userId];
        } else {
            [self.selectUserIds removeObject:vm.member.userId];
        }
        if ([self.responder respondsToSelector:@selector(updateItem:)]) {
            [self.responder updateItem:indexPath];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCRemoveGroupMemberCellViewModel *cellVM = (RCRemoveGroupMemberCellViewModel *)self.memberList[indexPath.row];
    UITableViewCell *cell = [cellVM tableView:tableView cellForRowAtIndexPath:indexPath];
    [self updateCellViewModelSelectState:cellVM complete:^(RCSelectState state) {
        [cellVM updateCell:cell state:state];
    }];
    return cell;
}


#pragma mark -- private

- (void)filterDataSourceWithQueryResult:(RCPagingQueryResult *)result {
    if (self.searchQueryResult && self.searchQueryResult.pageToken.length == 0) {
        return;
    }
    RCPagingQueryOption *option = [RCPagingQueryOption new];
    option.pageToken = self.searchQueryResult.pageToken;
    option.count = self.pageCount;
    [[RCCoreClient sharedCoreClient] searchGroupMembers:self.groupId name:self.searchBarVM.searchBar.text option:option success:^(RCPagingQueryResult<RCGroupMemberInfo *> * _Nonnull result) {
        [RCGroupManager fetchFriendInfos:result.data complete:^(NSArray<RCFriendInfo *> * _Nullable friendInfos) {
            NSArray *list = [self getViewModelsWithMembers:result.data friendInfos:friendInfos];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.searchQueryResult = result;
                [self.matchMemberList addObjectsFromArray:list];
                [self.responder reloadData:self.matchMemberList.count == 0];
            });
        }];
    } error:^(RCErrorCode errorCode) {
        
    }];
}

- (void)fetchGroupMembers {
    if (self.queryResult && self.queryResult.pageToken.length == 0) {
        return;
    }
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
            return;
        }
        [RCGroupManager fetchFriendInfos:result.data complete:^(NSArray<RCFriendInfo *> * _Nullable friendInfos) {
            NSArray *list = [self getViewModelsWithMembers:result.data friendInfos:friendInfos];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.queryResult = result;
                [self.mutableMemberList addObjectsFromArray:list];
                [self.responder reloadData:NO];
            });
        }];
    }];
}

#pragma mark -- public

- (UISearchBar *)configureSearchBar {
    RCSearchBarViewModel *vm = [[RCSearchBarViewModel alloc] init];
    vm.delegate = self;
    if ([self.delegate respondsToSelector:@selector(groupRemoveMembers:willLoadSearchBarViewModel:)]) {
        self.searchBarVM = [self.delegate groupRemoveMembers:self willLoadSearchBarViewModel:vm];
    } else {
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (void)selectionDidDone {
    if ([self.delegate respondsToSelector:@selector(groupRemoveMembersDidSelectComplete:selectUserIds:viewController:)]) {
        BOOL intercept = [self.delegate groupRemoveMembersDidSelectComplete:self selectUserIds:self.selectUserIds viewController:[self.responder currentViewController]];
        if (intercept) {
            return;
        }
    }
    [[RCCoreClient sharedCoreClient] kickGroupMembers:self.groupId userIds:self.selectUserIds config:nil success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self.responder currentViewController].navigationController popViewControllerAnimated:YES];
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupMembersKickSuccess") hiddenAfterDelay:2];
        });
    } error:^(RCErrorCode errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupMembersKickFailed") hiddenAfterDelay:2];
        });
    }];
}


#pragma mark -- private

- (NSArray<RCRemoveGroupMemberCellViewModel *> *)getViewModelsWithMembers:(NSArray<RCGroupMemberInfo *> *)members friendInfos:(NSArray<RCFriendInfo *> *)friendInfos {
    NSMutableArray *list = [NSMutableArray array];
    for (RCGroupMemberInfo *member in members) {
        RCRemoveGroupMemberCellViewModel *cellVM = [[RCRemoveGroupMemberCellViewModel alloc] initWithMember:member];
        if (friendInfos.count > 0) {
            cellVM.remark = [RCGroupManager friendWithUserId:member.userId inFriendInfos:friendInfos].remark;
        }
        [list addObject:cellVM];
    }
    if ([self.delegate respondsToSelector:@selector(groupRemoveMembers:willLoadItemsInDataSource:)]) {
        list = [self.delegate groupRemoveMembers:self willLoadItemsInDataSource:list].mutableCopy;
    }
    return list;
}

- (void)updateCellViewModelSelectState:(RCRemoveGroupMemberCellViewModel *)cellVM complete:(void(^)(RCSelectState state))complete {
    if ([cellVM.member.userId isEqualToString:[RCCoreClient sharedCoreClient].currentUserInfo.userId]) {
        complete(RCSelectStateDisable);
        return;
    }
    
    if ([self.selectUserIds containsObject:cellVM.member.userId]) {
        complete(RCSelectStateSelect);
        return;
    }

    [self getMyGroupRole:^(RCGroupMemberRole role) {
        if (role != RCGroupMemberRoleOwner) {
            if (cellVM.member.role != RCGroupMemberRoleNormal) {
                complete(RCSelectStateDisable);
                return;
            }
        }
        complete(RCSelectStateUnselect);
        return;
    }];
}

- (void)getMyGroupRole:(void (^)(RCGroupMemberRole role))successBlock {
    if (self.group) {
        successBlock(self.group.role);
        return;
    }
    [[RCCoreClient sharedCoreClient] getGroupsInfo:@[self.groupId ? : @""] success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.group = groupInfos.firstObject;
            successBlock(self.group.role);
        });
    } error:^(RCErrorCode errorCode) {

    }];
}

#pragma mark -- setter

- (void)setMaxSelectCount:(NSInteger)maxSelectCount {
    if (maxSelectCount <= 0) {
        return;
    }
    if (maxSelectCount > 100) {
        maxSelectCount = 100;
    }
    _maxSelectCount = maxSelectCount;
}

#pragma mark -- getter

- (NSMutableArray<NSString *> *)selectUserIds {
    if (!_selectUserIds) {
        _selectUserIds = [NSMutableArray array];
    }
    return _selectUserIds;
}

- (NSArray<RCRemoveGroupMemberCellViewModel *> *)memberList {
    if ([self.searchBarVM isCurrentFirstResponder]) {
        return self.matchMemberList;
    }
    return self.mutableMemberList;
}

- (NSMutableArray<RCRemoveGroupMemberCellViewModel *> *)matchMemberList {
    if (!_matchMemberList) {
        _matchMemberList = [NSMutableArray array];
    }
    return _matchMemberList;
}

- (NSMutableArray<RCRemoveGroupMemberCellViewModel *> *)mutableMemberList {
    if (!_mutableMemberList) {
        _mutableMemberList = [NSMutableArray array];
    }
    return _mutableMemberList;
}

@end
