//
//  RCSelectUserViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSelectUserViewModel.h"
#import "RCUPinYinTools.h"
#import "RCKitCommonDefine.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCNavigationItemsViewModel.h"
#import "RCAlertView.h"
#import "RCGroupCreateViewController.h"
#import "NSMutableArray+RCOperation.h"

static void *__rc_userlist_operation_queueTag = &__rc_userlist_operation_queueTag;

@interface RCSelectUserViewModel ()<RCSearchBarViewModelDelegate>
@property (nonatomic, strong) RCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, strong) RCSearchBarViewModel *searchBarVM;

// 全部cell
@property (nonatomic, strong) NSArray *dataSource;
// 索引
@property (nonatomic, strong) NSArray *indexTitles;
// 分组cell
@property (nonatomic, strong) NSDictionary *dicInfo;
// 搜索匹配cell
@property (nonatomic, strong) NSArray *matchFriendList;

@property (nonatomic, weak) id<RCListViewModelResponder> responder;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) NSMutableArray <NSString *>*selectUserIds;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, assign) RCSelectUserType type;

@property (nonatomic, strong) NSArray <RCGroupMemberInfo *> *members;

@end

@implementation RCSelectUserViewModel
@dynamic delegate;

+ (instancetype)viewModelWithType:(RCSelectUserType)type groupId:(NSString *)groupId {
    RCSelectUserViewModel *viewModel = [self.class new];
    viewModel.type = type;
    viewModel.groupId = groupId;
    return viewModel;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.maxSelectCount = 30;
        self.queue = dispatch_queue_create("rc_selectuserlist_operation_queue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(self.queue, __rc_userlist_operation_queueTag, __rc_userlist_operation_queueTag, NULL);
    }
    return self;
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [RCSelectUserCellViewModel registerCellForTableView:tableView];
}

#pragma mark -- RCListViewModelProtocol

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    RCSelectUserCellViewModel *vm;
    if ([self.searchBarVM isCurrentFirstResponder]) {// 搜索状态或非第一个section
        NSString *key = [self.indexTitles objectAtIndex:indexPath.section];
        NSArray *array = [self.dicInfo objectForKey:key];
        vm = [array objectAtIndex:indexPath.row];
    } else {
        NSString *key = [self.indexTitles objectAtIndex:indexPath.section];
        NSArray *array = [self.dicInfo objectForKey:key];
        vm = [array objectAtIndex:indexPath.row];
    }
    
    if ([self.delegate respondsToSelector:@selector(selectUserViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate selectUserViewModel:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:vm];
        if (intercept) {
            return;
        }
    }
    
    if (vm.selectState != RCSelectStateDisable){
        if (vm.selectState == RCSelectStateUnselect && self.selectUserIds.count >= self.maxSelectCount) {
            [RCAlertView showAlertController:nil message:[NSString stringWithFormat:RCLocalizedString(@"GroupMemberSelectMaxTip"), @(self.maxSelectCount)] hiddenAfterDelay:2];
            return;
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [vm updateCell:cell state:(vm.selectState == RCSelectStateSelect) ? RCSelectStateUnselect : RCSelectStateSelect];
        if (vm.selectState == RCSelectStateSelect) {
            [self.selectUserIds addObject:vm.friendInfo.userId];
        } else {
            [self.selectUserIds removeObject:vm.friendInfo.userId];
        }
        if ([self.responder respondsToSelector:@selector(updateItem:)]) {
            [self.responder updateItem:indexPath];
        }
    }
}

- (NSInteger)numberOfSections {
    NSInteger count = self.indexTitles.count;
    return count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    if ([self.searchBarVM isCurrentFirstResponder]) {// 搜索状态
        NSString *key = [self.indexTitles objectAtIndex:section];
        NSArray *array = [self.dicInfo objectForKey:key];
        return array.count;
    }
    
    NSString *key = [self.indexTitles objectAtIndex:section];
    NSArray *array = [self.dicInfo objectForKey:key];
    return array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    NSString *key = [self.indexTitles objectAtIndex:indexPath.section];
    NSArray *array = [self.dicInfo objectForKey:key];
    RCSelectUserCellViewModel *vm = [array objectAtIndex:indexPath.row];
    cell = [vm tableView:tableView cellForRowAtIndexPath:indexPath];
    [vm updateCell:cell state:[self cellSelectState:vm.friendInfo.userId members:self.members]];
    return cell;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
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
    title.text = self.indexTitles[section];
    [title sizeToFit];
    title.center = CGPointMake(13+title.bounds.size.width/2, 16);
    return view;
}

#pragma mark - SearchBar
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        [self restoreData];
    } else {
        [self filterDataSourceWithKeyword:searchText];
    }
}

- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching {
    if (inSearching) {
        [self reloadData];
    } else {
        [self restoreData];
    }
}

#pragma mark - Public

- (NSArray *)sectionIndexTitles {
    return self.indexTitles;
}

- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    RCSearchBarViewModel *vm = [[RCSearchBarViewModel alloc] init];
    vm.delegate = self;
    if ([self.delegate respondsToSelector:@selector(selectUserViewModel:willLoadSearchBarViewModel:)]) {
        self.searchBarVM = [self.delegate selectUserViewModel:self willLoadSearchBarViewModel:vm];
    } else {
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (void)endEditingState {
    [self.searchBarVM endEditingState];
    [self restoreData];
}

- (void)fetchData {
    [[RCCoreClient sharedCoreClient] getFriends:RCQueryFriendsDirectionTypeBoth
                                        success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
        [self configureDataSourceWithArray:friendInfos];
    } error:^(RCErrorCode errorCode) {
        [self reloadData];
    }];
}

- (void)configureDataSourceWithArray:(NSArray *)friendInfos {
    [self fetchGroupMember:friendInfos groupId:self.groupId complete:^(NSArray<RCGroupMemberInfo *> * _Nullable members) {
        self.members = members;
        NSArray *array = nil;
        NSMutableArray *tmp = [NSMutableArray array];
        for (RCFriendInfo *friend in friendInfos) {
            RCSelectUserCellViewModel *vm = [[RCSelectUserCellViewModel alloc] initWithFriend:friend groupId:self.groupId];
            vm.selectState = [self cellSelectState:friend.userId members:members];
            [tmp addObject:vm];
        }
        array = tmp;
        // 通知用户修改数据源
        if ([self.delegate respondsToSelector:@selector(selectUserViewModel:willLoadItemsInDataSource:)]) {
            array = [self.delegate selectUserViewModel:self willLoadItemsInDataSource:tmp];
        }
        self.dataSource = array;
        [self groupAndReloadItemsInArray:self.dataSource];
    }];
}

- (RCSelectState)cellSelectState:(NSString *)userId
                         members:(NSArray<RCGroupMemberInfo *> *)members {
    if ([userId isEqualToString:[RCCoreClient sharedCoreClient].currentUserInfo.userId]) {
        return RCSelectStateDisable;
    }
    
    if ([self.selectUserIds containsObject:userId]) {
        return RCSelectStateSelect;
    }
    
    if (self.type == RCSelectUserTypeCreateGroup) {
        return RCSelectStateUnselect;
    }
    
    if ([self inGroupWithUser:userId members:members]) {
        return RCSelectStateDisable;
    }
    
    return RCSelectStateUnselect;
}

- (void)selectionDidDone {
    if ([self.delegate respondsToSelector:@selector(selectUserDidSelectComplete:selectUserIds:viewController:)]) {
        BOOL intercept = [self.delegate selectUserDidSelectComplete:self selectUserIds:self.selectUserIds viewController:[self.responder currentViewController]];
        if (intercept) {
            return;
        }
    }
    
    if (self.selectionDidCompelteBlock) {
        self.selectionDidCompelteBlock(self.selectUserIds, [self.responder currentViewController]);
    }
    if (self.type == RCSelectUserTypeCreateGroup){
        [self showCreateGroupVC];
    }
}

- (NSString *)emptyTip {
    if ([self.searchBarVM isCurrentFirstResponder] && self.searchBarVM.searchBar.text.length > 0) {
        return RCLocalizedString(@"NotUserFound");
    } else {
        return RCLocalizedString(@"NoAddFriends");
    }
}

- (void)bindResponder:(id<RCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark - Private

- (void)showCreateGroupVC {
    RCGroupCreateViewModel *viewModel = [RCGroupCreateViewModel viewModelWithInviteeUserIds:self.selectUserIds];
    RCGroupCreateViewController *vc = [[RCGroupCreateViewController alloc] initWithViewModel:viewModel];
    [[self.responder currentViewController].navigationController pushViewController:vc animated:YES];
}

- (void)groupAndReloadItemsInArray:(NSArray *)array {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 数据源分组
        self.dicInfo = [RCUPinYinTools sortedWithPinYinArray:array
                                                  usingBlock:^NSString * _Nonnull(RCSelectUserCellViewModel * obj, NSUInteger idx) {
            return obj.friendInfo.remark.length > 0 ? obj.friendInfo.remark : obj.friendInfo.name;
        }];
        // 索引排序
        self.indexTitles = [[self.dicInfo allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
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
        
        // 通知vc 刷新列表
        [self reloadData];
    });
}

- (void)filterDataSourceWithKeyword:(NSString *)keyword {
    [[RCCoreClient sharedCoreClient] searchFriendsInfo:keyword success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
        NSMutableArray *tmp = [NSMutableArray array];
        [self fetchGroupMember:friendInfos groupId:self.groupId complete:^(NSArray<RCGroupMemberInfo *> * _Nullable members) {
            for (RCFriendInfo *friend in friendInfos) {
                RCSelectUserCellViewModel *vm = [[RCSelectUserCellViewModel alloc] initWithFriend:friend groupId:self.groupId];
                vm.selectState = [self cellSelectState:friend.userId members:members];
                [tmp addObject:vm];
            }
            self.matchFriendList = tmp.copy;
            [self groupAndReloadItemsInArray:self.matchFriendList];
        }];
    } error:^(RCErrorCode errorCode) {
        
    }];
}

- (void)restoreData {
    self.matchFriendList = @[];
    [self groupAndReloadItemsInArray:self.dataSource];
}

- (void)reloadData {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder reloadData:self.indexTitles.count == 0];
        });
    }
}

- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(__rc_userlist_operation_queueTag)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}

- (void)fetchGroupMember:(NSArray <RCFriendInfo *> *)friendInfos
                 groupId:(NSString *)groupId
                complete:(void (^)(NSArray<RCGroupMemberInfo *> * _Nullable members))complete {
    if (groupId.length <= 0) {
        return complete(nil);
    }
    NSMutableArray *userIdList = [NSMutableArray array];
    for (RCFriendInfo *info in friendInfos) {
        [userIdList rclib_addObject:info.userId];
    }
    if (userIdList.count == 0) {
        return complete(nil);
    }
    [[RCCoreClient sharedCoreClient] getGroupMembers:groupId userIds:userIdList success:^(NSArray<RCGroupMemberInfo *> * _Nonnull groupMembers) {
        [self performOperationQueueBlock:^{
            complete(groupMembers);
        }];
    } error:^(RCErrorCode errorCode) {
        complete(nil);
    }];
}

- (BOOL)inGroupWithUser:(NSString *)userId
                members:(NSArray<RCGroupMemberInfo *> *)members {
    for (RCGroupMemberInfo *info in members) {
        if ([info.userId isEqualToString:userId]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark -- setter & getter

- (void)setMaxSelectCount:(NSInteger)maxSelectCount {
    if (maxSelectCount <= 0) {
        return;
    }
    if (maxSelectCount > 100) {
        maxSelectCount = 100;
    }
    _maxSelectCount = maxSelectCount;
}

- (NSMutableArray<NSString *> *)selectUserIds {
    if (!_selectUserIds) {
        _selectUserIds = [NSMutableArray array];
    }
    return _selectUserIds;
}
@end
