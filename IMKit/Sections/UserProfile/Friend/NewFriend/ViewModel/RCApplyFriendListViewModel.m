//
//  RCApplyFriendListViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCApplyFriendListViewModel.h"
#import "RCKitCommonDefine.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCApplyNaviItemsViewModel.h"

@interface RCApplyFriendSectionItem()
- (id)itemAtIndex:(NSInteger)index;
- (void)removeItemAtIndex:(NSInteger)index;
- (NSInteger)countOfItems;
- (void)clean;

- (void)appendItems:(NSArray *)items;
@end

NSInteger const RCFriendApplyListMaxCount = 100;

static void *__rc_friendApplyList_operation_queueTag = &__rc_friendApplyList_operation_queueTag;

@interface RCApplyFriendListViewModel()<RCApplyNaviItemsViewModelDelegate>
@property (nonatomic, strong) RCNavigationItemsViewModel *naviItemsVM;
// 全部cell
@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong)NSArray <RCApplyFriendSectionItem *>* sectionItems;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, weak) UIViewController <RCListViewModelResponder> *responder;
@property (nonatomic, strong) RCPagingQueryOption *option;
@property (nonatomic, strong) NSArray<NSNumber *> *types;
@property (nonatomic, strong) NSArray<NSNumber *> *status;
@end

@implementation RCApplyFriendListViewModel
@dynamic delegate;

- (instancetype)initWithSectionItems:(nullable NSArray <RCApplyFriendSectionItem *>*)items
                              option:(nullable RCPagingQueryOption *)option
                               types:(nullable NSArray<NSNumber *> *)types
                              status:(nullable NSArray<NSNumber *> *)status
{
    self = [super init];
    if (self) {
        [self ready];
        self.sectionItems = items;
        self.option = option;
        self.status = status;
        self.types = types;
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
    self.queue = dispatch_queue_create("rc_friendApplyList_operation_queue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(self.queue, __rc_friendApplyList_operation_queueTag, __rc_friendApplyList_operation_queueTag, NULL);
}

- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForApplyFriendListViewModel:)]) {
        self.naviItemsVM = [self.delegate willConfigureRightNavigationItemsForApplyFriendListViewModel:self];
    } else if(!self.naviItemsVM) {
        RCApplyNaviItemsViewModel *vm = [[RCApplyNaviItemsViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.naviItemsVM = vm;
    }
    return [self.naviItemsVM rightNavigationBarItems];
}

- (void)fetchData {
    if (self.types.count == 0) {
        self.types = @[@(RCFriendApplicationTypeSent),
                        @(RCFriendApplicationTypeReceived)];
    }
    if (self.status.count == 0) {
        self.status = @[@(RCFriendApplicationStatusUnHandled),
                       @(RCFriendApplicationStatusAccepted),
                       @(RCFriendApplicationStatusRefused),
                       @(RCFriendApplicationStatusExpired)];
    }
    if (!self.option) {
        RCPagingQueryOption *opt = [[RCPagingQueryOption alloc] init];
        opt.count = RCFriendApplyListMaxCount;
        self.option = opt;
    }
    [self.dataSource removeAllObjects];
    for (RCApplyFriendSectionItem *item in self.sectionItems) {
        [item clean];
    }
    self.option.pageToken=nil;
    [self reloadData:NO];
    [self fetchDataWithOption:self.option types:self.types status:self.status];;
}

- (void)fetchDataWithOption:(RCPagingQueryOption *)option
                      types:(nonnull NSArray<NSNumber *> *)types
                     status:(nonnull NSArray<NSNumber *> *)status {
    [self performOperationQueueBlock:^{
        [[RCCoreClient sharedCoreClient] getFriendApplications:option types:types status:status success:^(RCPagingQueryResult<RCFriendApplicationInfo *> * _Nonnull result) {
            if (result.pageToken.length != 0) {
                self.option.pageToken = result.pageToken;
            }
            NSArray *infos = result.data;
            NSMutableArray *array = [NSMutableArray array];
            NSArray *items = @[];
            if (infos.count) {
                for (RCFriendApplicationInfo *info in infos) {
                    RCApplyFriendCellViewModel *vm = [[RCApplyFriendCellViewModel alloc] initWithApplicationInfo:info];
                    [vm bindResponder:self.responder];
                    [array addObject:vm];
                }
                items = array;
                if ([self.delegate respondsToSelector:@selector(applyFriendListViewModel:willLoadItemsInDataSource:)]) {
                    items = [self.delegate applyFriendListViewModel:self willLoadItemsInDataSource:array];
                }
            }
            [self.dataSource addObjectsFromArray:items];
            [self groupApplications:items];
            [self refreshingFinished:YES withTips:nil];
        } error:^(RCErrorCode errorCode) {
            [self refreshingFinished:NO withTips:RCLocalizedString(@"FriendApplicationFailed")];
        }];
        
    }];
}

- (void)bindResponder:(UIViewController <RCListViewModelResponder>*)responder {
    self.responder = responder;
    for (RCApplyFriendCellViewModel *vm in self.dataSource) {
        [vm bindResponder:self.responder];
    }
}

- (void)loadMoreData {
    [self fetchDataWithOption:self.option types:self.types status:self.status];
}

#pragma mark - Private

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
    if (dispatch_get_specific(__rc_friendApplyList_operation_queueTag)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}

- (void)groupApplications:(NSArray <RCApplyFriendCellViewModel *>*)infos {
    if (self.sectionItems.count == 0) {
        RCApplyFriendSectionItem *item = [[RCApplyFriendSectionItem alloc] initWithFilterBlock:nil compareBlock:nil];
        item.timeEnd = [[NSDate date] timeIntervalSince1970] * 1000;
        item.title = @"";
        self.sectionItems = @[item];
    }
    [self groupApplications:infos withSectionItems:self.sectionItems];
}

- (void)groupApplications:(NSArray <RCApplyFriendCellViewModel *>*)infos
         withSectionItems:(NSArray <RCApplyFriendSectionItem *>*)items {
    NSInteger count = self.sectionItems.count;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    for (int i=0 ; i<count; i++) {
        RCApplyFriendSectionItem *item = self.sectionItems[i];
        NSArray *ret = [item filterAndSortItems:infos];
        if (!ret) {
            ret = @[];
        }
        [array addObject:ret];
    }
    // 数据源的变更放在主线程, 是为了和UI刷新同步
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int i=0 ; i<count; i++) {
            RCApplyFriendSectionItem *item = self.sectionItems[i];
            [item appendItems:array[i]];
        }
        [self reloadData:self.dataSource.count == 0];
    });
}


#pragma mark - Protocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [RCApplyFriendCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    RCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:indexPath.section];
    RCApplyFriendCellViewModel *vm = [item itemAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(applyFriendListViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate applyFriendListViewModel:self
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
    return self.sectionItems.count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    RCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:section];
    return [item countOfItems];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:indexPath.section];
    RCApplyFriendCellViewModel *vm = [item itemAtIndex:indexPath.row];
    return [vm tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
    RCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:section];
    if (![item isValidSectionItem]) {
        return 0.01;
    }
    return 34;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    RCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:section];
    if (![item isValidSectionItem] || item.title.length == 0) {
        return nil;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.frame = CGRectMake(0, 0, tableView.frame.size.width, 32);
    view.backgroundColor = RCDYCOLOR(0xf0f0f6, 0x000000);
    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectZero];
    lab.font = [UIFont systemFontOfSize:14.f];
    lab.textColor = RCDYCOLOR(0x3b3b3b, 0xA7a7a7);
    lab.text = item.title;
    [view addSubview:lab];

    [lab sizeToFit];
    lab.center = CGPointMake(13+lab.bounds.size.width/2, 16);
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:indexPath.section];
    RCApplyFriendCellViewModel *vm = [item itemAtIndex:indexPath.row];    return [vm cellHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    RCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:section];
    if (![item isValidSectionItem] || item.title.length == 0) {
        return 0;
    }
    return 34;
}

- (void)removeItem:(RCApplyFriendSectionItem *)item 
         tableView:(UITableView *)tableView
       atIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath || !item) {
        return;
    }
    [self performOperationQueueBlock:^{
        [item removeItemAtIndex:indexPath.row];
        dispatch_async(dispatch_get_main_queue(), ^{
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        });
    }];
 

}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:indexPath.section];
    RCApplyFriendCellViewModel *vm = [item itemAtIndex:indexPath.row]; 
    NSArray *array = [vm tableView:tableView editActionsForRowAtIndexPath:indexPath completion:^(RCErrorCode errorCode) {
        if (errorCode == RC_SUCCESS) {
            [self removeItem:item tableView:tableView atIndexPath:indexPath];
        } else {
            [self showTips:RCLocalizedString(@"FriendApplicationDeleteFailed")];
        }
    }];
    return array;
}


#pragma mark - RCApplyNaviItemsViewModelDelegate
- (void)userDidSelectCategory:(RCApplicationCategory)category {
    switch (category) {
        case RCApplicationCategoryReceived:
            self.types = @[@(RCFriendApplicationTypeReceived)];
            break;
        case RCApplicationCategorySent:
            self.types = @[@(RCFriendApplicationTypeSent)];
            break;
        default:
            self.types = @[@(RCFriendApplicationTypeSent),
                            @(RCFriendApplicationTypeReceived)];
            break;
    }
    [self fetchData];
}
@end
