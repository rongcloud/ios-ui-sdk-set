//
//  RCGroupMembersViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupTransferViewModel.h"
#import "RCGroupMemberCellViewModel.h"
#import "RCGroupMemberCell.h"
#import "RCGroupManager.h"
#import "RCProfileViewController.h"
#import "RCUserProfileViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCRemoveGroupMemberCellViewModel.h"
#import "RCAlertView.h"
@interface RCGroupTransferViewModel ()<RCSearchBarViewModelDelegate>


@property (nonatomic, strong) NSMutableArray <RCGroupMemberCellViewModel *>*mutableMemberList;

@property (nonatomic, strong) NSMutableArray <RCGroupMemberCellViewModel *>*matchMemberList;

@property (nonatomic, strong) RCSearchBarViewModel *searchBarVM;

@property (nonatomic, strong) RCPagingQueryResult *queryResult;

@property (nonatomic, strong) RCPagingQueryResult *searchQueryResult;

@property (nonatomic, weak) id<RCListViewModelResponder> responder;

@property (nonatomic, copy) NSString *groupId;

@end

@implementation RCGroupTransferViewModel
@dynamic delegate;

+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    RCGroupTransferViewModel *viewModel = [[self.class alloc] init];
    viewModel.groupId = groupId;
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
    RCSearchBarViewModel *vm = [[RCSearchBarViewModel alloc] init];
    vm.delegate = self;
    if ([self.delegate respondsToSelector:@selector(groupMemberList:willLoadSearchBarViewModel:)]) {
        self.searchBarVM = [self.delegate groupMemberList:self willLoadSearchBarViewModel:vm];
    } else {
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
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
    [tableView registerClass:[RCGroupMemberCell class]
      forCellReuseIdentifier:RCGroupMemberCellIdentifier];
}

- (void)viewController:(UIViewController *)viewController tableView:(UITableView *)tableView didSelectRow:(NSIndexPath *)indexPath {
    RCGroupMemberCellViewModel *cellViewModel = self.memberList[indexPath.row];
    if ([self.delegate respondsToSelector:@selector(groupMemberList:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate groupMemberList:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    if ([[RCCoreClient sharedCoreClient].currentUserInfo.userId isEqualToString:cellViewModel.memberInfo.userId]) {
        return;
    }
    NSString *name;
    if (cellViewModel.remark.length > 0) {
        name = cellViewModel.remark;
    } else if (cellViewModel.memberInfo.nickname.length > 0) {
        name = cellViewModel.memberInfo.nickname;
    } else {
        name = cellViewModel.memberInfo.name;
    }
    NSString *message = [NSString stringWithFormat:RCLocalizedString(@"GroupTransferAlert"), name];
    [RCAlertView showAlertController:nil message:message actionTitles:nil cancelTitle:RCLocalizedString(@"Cancel") confirmTitle:RCLocalizedString(@"Confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
        [self groupTranfer:cellViewModel.memberInfo.userId];
    } inViewController:viewController];
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

- (NSArray<RCRemoveGroupMemberCellViewModel *> *)getViewModelsWithMembers:(NSArray<RCGroupMemberInfo *> *)members friendInfos:(NSArray<RCFriendInfo *> *)friendInfos {
    NSMutableArray *list = [NSMutableArray array];
    for (RCGroupMemberInfo *member in members) {
        if ([member.userId isEqualToString:[RCCoreClient sharedCoreClient].currentUserInfo.userId]) {
            continue;
        }
        RCGroupMemberCellViewModel *cellVM = [[RCGroupMemberCellViewModel alloc] initWithMember:member];
        if (friendInfos.count > 0) {
            cellVM.remark = [RCGroupManager friendWithUserId:member.userId inFriendInfos:friendInfos].remark;
        }
        cellVM.hiddenArrow = YES;
        [list addObject:cellVM];
    }
    if ([self.delegate respondsToSelector:@selector(groupMemberList:willLoadItemsInDataSource:)]) {
        list = [self.delegate groupMemberList:self willLoadItemsInDataSource:list].mutableCopy;
    }
    return list;
}

- (void)groupTranfer:(NSString *)userId {
    [[RCCoreClient sharedCoreClient] transferGroupOwner:self.groupId newOwnerId:userId quitGroup:NO config:nil success:^{
        if ([self.delegate respondsToSelector:@selector(groupOwnerDidTransfer:newOwnerId:viewController:)]) {
            BOOL intercept = [self.delegate groupOwnerDidTransfer:self.groupId newOwnerId:userId viewController:[self.responder currentViewController]];
            if (intercept) {
                return;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *viewControllers = [self.responder currentViewController].navigationController.viewControllers;
            if (viewControllers.count > 2) {
                [[self.responder currentViewController].navigationController popToViewController:viewControllers[viewControllers.count - 3] animated:YES];
            }
            
            
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupTransferSuccess") hiddenAfterDelay:1];
        });
    } error:^(RCErrorCode errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupTransferFailed") hiddenAfterDelay:1];
        });
    }];
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
    if ([self.searchBarVM isCurrentFirstResponder]) {
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
@end
