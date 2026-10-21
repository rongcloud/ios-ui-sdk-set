//
//  RCGroupNotificationViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/14.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNotificationViewModel.h"
#import "RCGroupNotificationNaviItemsViewModel.h"
#import "RCGroupNotificationCellViewModel.h"
#import "RCKitCommonDefine.h"

NSInteger const RCGroupNotificationMaxCount = 50;

static void *__rc_group_notification_operation_queueTag = &__rc_group_notification_operation_queueTag;

@interface RCGroupNotificationViewModel()<RCGroupNotificationNaviItemsViewModelDelegate>
@property (nonatomic, strong) RCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, weak) UIViewController <RCListViewModelResponder> *responder;

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSArray<NSNumber *> *types;
@property (nonatomic, strong) NSArray<NSNumber *> *status;
@end

@implementation RCGroupNotificationViewModel
@dynamic delegate;

#pragma mark - Public

- (instancetype)initWithOption:(nullable RCPagingQueryOption *)option
                         types:(nullable NSArray<NSNumber *> *)types
                        status:(nullable NSArray<NSNumber *> *)status
{
    self = [super init];
    if (self) {
        [self ready];
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
    self.queue = dispatch_queue_create("__rc_group_notification_operation_queueTag", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(self.queue, __rc_group_notification_operation_queueTag, __rc_group_notification_operation_queueTag, NULL);
}

/// 配置导航
- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForGroupNotificationViewModel:)]) {
        self.naviItemsVM = [self.delegate willConfigureRightNavigationItemsForGroupNotificationViewModel:self];
    } else if(!self.naviItemsVM) {
        RCGroupNotificationNaviItemsViewModel *vm = [[RCGroupNotificationNaviItemsViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.naviItemsVM = vm;
    }
    return [self.naviItemsVM rightNavigationBarItems];
}

/// 获取数据
- (void)fetchData {
    if (self.types.count == 0) {
        self.types = [self applicationDirectionByCategory:RCGroupNotificationCategoryAll];
    }
    if (self.status.count == 0) {
        self.status =  [self applicationStatusByCategory:RCGroupNotificationCategoryAll];
    }
    if (!self.option) {
        RCPagingQueryOption *opt = [[RCPagingQueryOption alloc] init];
        opt.count = RCGroupNotificationMaxCount;
        self.option = opt;
    }
    [self.dataSource removeAllObjects];
    [self fetchDataWithOption:self.option
                        types:self.types
                       status:self.status];
}

- (void)fetchDataWithOption:(RCPagingQueryOption *)option
                      types:(nonnull NSArray<NSNumber *> *)types
                     status:(nonnull NSArray<NSNumber *> *)status {
    self.types = types;
    self.status = status;
    self.option = option;
    
    [self performOperationQueueBlock:^{
        [[RCCoreClient sharedCoreClient] getGroupApplications:option
                                                   directions:types
                                                       status:status
                                                      success:^(RCPagingQueryResult<RCGroupApplicationInfo *> * _Nonnull result) {
            if (result.pageToken.length != 0) {
                self.option.pageToken = result.pageToken;
            }
            NSArray *infos = result.data;
            NSMutableArray *array = [NSMutableArray array];
            NSArray *items = @[];
            if (infos.count) {
                for (RCGroupApplicationInfo *info in infos) {
                    RCGroupNotificationCellViewModel *vm = [[RCGroupNotificationCellViewModel alloc] initWithApplicationInfo:info];
                    [vm bindResponder:self.responder];
                    [array addObject:vm];
                }
                items = array;
                if ([self.delegate respondsToSelector:@selector(groupNotificationViewModel:willLoadItemsInDataSource:)]) {
                    items = [self.delegate groupNotificationViewModel:self willLoadItemsInDataSource:array];
                }
            }
            [self.dataSource addObjectsFromArray:items];
            [self reloadData:self.dataSource.count == 0];
            [self refreshingFinished:YES withTips:nil];
            } error:^(RCErrorCode errorCode) {
                [self refreshingFinished:NO withTips:RCLocalizedString(@"GroupNotificationFailed")];

            }];
    }];
  
}

- (void)bindResponder:(UIViewController<RCListViewModelResponder> *)responder {
    self.responder = responder;
}

/// cell 高度
/// - Parameters:
///   - tableView: tableView
///   - indexPath: indexPath
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupNotificationCellViewModel *vm = [self.dataSource objectAtIndex:indexPath.row];
    return [vm tableView:tableView heightForRowAtIndexPath:indexPath];
}

/// 加载更多
- (void)loadMoreData {
    [self fetchDataWithOption:self.option
                        types:self.types
                       status:self.status];
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupNotificationCellViewModel *vm = [self.dataSource objectAtIndex:indexPath.row];
    return [vm tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    RCGroupNotificationCellViewModel *vm = [self.dataSource objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(groupNotificationViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate groupNotificationViewModel:self
                                              viewController:viewController
                                                   tableView:tableView
                                                didSelectRow:indexPath
                                               cellViewModel:vm];
        if (ret) {
            return;
        }
    }
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [RCGroupNotificationCellViewModel registerCellForTableView:tableView];
}

- (NSInteger)numberOfSections {
    return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}
#pragma  mark - Private
- (NSArray *)applicationDirectionByCategory:(RCGroupNotificationCategory)category {
    NSArray *array = @[@(RCGroupApplicationDirectionInvitationReceived),
                       @(RCGroupApplicationDirectionApplicationReceived),
                       @(RCGroupApplicationDirectionApplicationSent),
                       @(RCGroupApplicationDirectionInvitationSent)];
    return array;
}

- (NSArray *)applicationStatusByCategory:(RCGroupNotificationCategory)category {
    NSArray *array = @[];
    switch (category) {
        case RCGroupNotificationCategoryToBeConfirmed:
            array = @[@(RCGroupApplicationStatusInviteeUnHandled),
            @(RCGroupApplicationStatusManagerUnHandled)];
            break;
        case RCGroupNotificationCategoryDealt:
            array = @[@(RCGroupApplicationStatusJoined),
                      @(RCGroupApplicationStatusInviteeRefused),
                      @(RCGroupApplicationStatusManagerRefused)];
            break;
        case RCGroupNotificationCategoryExpired:
            array = @[@(RCGroupApplicationStatusExpired)];
            break;
        default:
            array = @[@(RCGroupApplicationStatusManagerUnHandled),
                      @(RCGroupApplicationStatusManagerRefused),
                      @(RCGroupApplicationStatusInviteeUnHandled),
                      @(RCGroupApplicationStatusInviteeRefused),
                      @(RCGroupApplicationStatusJoined),
                      @(RCGroupApplicationStatusExpired)];
            break;
    }
    return array;
}

#pragma mark - RCApplyNaviItemsViewModelDelegate

/// 用户选择展示类别
- (void)userDidSelectCategory:(RCGroupNotificationCategory)category {
    NSArray *types = [self applicationDirectionByCategory:category];
    NSArray *status = [self applicationStatusByCategory:category];
    self.option.pageToken = nil;
    [self.dataSource removeAllObjects];
    [self reloadData:NO];
    [self fetchDataWithOption:self.option types:types status:status];
}

#pragma mark - Private
- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(__rc_group_notification_operation_queueTag)) {
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

- (void)setTypes:(NSArray<NSNumber *> *)types {
    if (_types != types) {
        _types = types;
    }
}

- (void)setStatus:(NSArray<NSNumber *> *)status {
    if (_status != status) {
        _status = status;
    }
}
@end
