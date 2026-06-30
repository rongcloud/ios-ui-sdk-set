//
//  RCMessageReadDetailViewModel.m
//  RongIMKit
//
//  Created by Lang on 10/15/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageReadDetailViewModel.h"
#import "RCIM.h"

@interface RCMessageReadDetailViewModel ()

@property (nonatomic, strong) RCMessageModel *messageModel;
@property (nonatomic, strong) RCMessageReadDetailViewConfig *config;
@property (nonatomic, assign) RCMessageReadDetailTabType currentTabType;

// 已读用户
@property (nonatomic, strong) NSMutableArray<RCMessageReadDetailCellViewModel *> *readUserList;
@property (nonatomic, copy, nullable) NSString *readPageToken;
@property (nonatomic, assign) BOOL isLoadingRead;

// 未读用户
@property (nonatomic, strong) NSMutableArray<RCMessageReadDetailCellViewModel *> *unreadUserList;
@property (nonatomic, copy, nullable) NSString *unreadPageToken;
@property (nonatomic, assign) BOOL isLoadingUnread;

// 业务状态（是否有更多数据）
@property (nonatomic, assign) BOOL hasMoreReadUsers;
@property (nonatomic, assign) BOOL hasMoreUnreadUsers;

// readReceiptInfo 重试次数
@property (nonatomic, assign) NSInteger readInfoRetryCount;

@end

@implementation RCMessageReadDetailViewModel

/// 最大重试次数
static const NSInteger kRCReadReceiptMaxRetryCount = 3;

/// 重试间隔时间
static const NSTimeInterval kRCReadReceiptRetryDelay = (1 * NSEC_PER_SEC);

- (instancetype)initWithMessageModel:(RCMessageModel *)messageModel
                              config:(RCMessageReadDetailViewConfig *)config {
    self = [super init];
    if (self) {
        _messageModel = messageModel;
        _config = config ?: [[RCMessageReadDetailViewConfig alloc] init];
        _currentTabType = RCMessageReadDetailTabTypeRead;
        
        _readUserList = [NSMutableArray array];
        _unreadUserList = [NSMutableArray array];
        
        _isLoadingRead = NO;
        _isLoadingUnread = NO;
    }
    return self;
}

- (void)bindResponder:(id<RCMessageReadDetailViewModelResponder>)responder {
    self.responder = responder;
}

- (void)switchTabToType:(RCMessageReadDetailTabType)tabType {
    if (self.currentTabType == tabType) {
        return;
    }
    
    self.currentTabType = tabType;
    
    // 切换到已读列表
    if (tabType == RCMessageReadDetailTabTypeRead) {
        if (self.readUserList.count == 0 && self.readPageToken == nil) {
            [self loadReadUsers];
        }
    } else {
        if (self.unreadUserList.count == 0 && self.unreadPageToken == nil) {
            [self loadUnreadUsers];
        }
    }
}

#pragma mark - Data Loading

- (void)loadData {
    // 先加载 readReceiptInfoV5，如果未传入，则会通过 libcore 接口获取
    [self loadReadReceiptInfo:^{
        // 并发加载已读和未读列表
        [self loadReadUsers];
        [self loadUnreadUsers];
    }];
}

- (void)loadReadUsers {
    [self loadUserListWithType:RCMessageReadDetailTabTypeRead pageToken:nil];
}

- (void)loadUnreadUsers {
    [self loadUserListWithType:RCMessageReadDetailTabTypeUnread pageToken:nil];
}

- (void)loadUserListWithType:(RCMessageReadDetailTabType)tabType pageToken:(NSString *)pageToken {
    BOOL isRead = tabType == RCMessageReadDetailTabTypeRead;
    // 检查加载状态
    BOOL isLoading = isRead ? self.isLoadingRead : self.isLoadingUnread;
    if (isLoading) {
        return;
    }
    
    // 设置加载状态
    if (isRead) {
        self.isLoadingRead = YES;
    } else {
        self.isLoadingUnread = YES;
    }
    
    // 创建请求选项
    RCReadReceiptUsersOption *option = [[RCReadReceiptUsersOption alloc] init];
    option.readReceiptStatus = isRead ? RCReadReceiptStatusResponse : RCReadReceiptStatusUnResponse;
    option.pageToken = pageToken;
    option.pageCount = self.config.pageSize;
    option.order = RCOrderDescending;
    
    RCConversationIdentifier *identifier = [[RCConversationIdentifier alloc] init];
    identifier.type = self.messageModel.conversationType;
    identifier.targetId = self.messageModel.targetId;
    
    __weak typeof(self) weakSelf = self;
    [[RCCoreClient sharedCoreClient] getMessagesReadReceiptUsersByPageV5:identifier
                                                              messageUId:self.messageModel.messageUId
                                                                  option:option
                                                              completion:^(RCReadReceiptUsersResult * _Nullable result, RCErrorCode code) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // 重置加载状态
        if (isRead) {
            strongSelf.isLoadingRead = NO;
        } else {
            strongSelf.isLoadingUnread = NO;
        }
        
        if (code != RC_SUCCESS) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.responder updateUserListForTabType:tabType isEmpty:YES hasMoreData:NO];
            });
            return;
        }

        NSMutableArray<RCMessageReadDetailCellViewModel *> *userList = 
            isRead ? strongSelf.readUserList : strongSelf.unreadUserList;

        for (RCReadReceiptUser *user in result.users) {
            RCUserInfo *userInfo = nil;
            if (strongSelf.messageModel.conversationType == ConversationType_PRIVATE) {
                userInfo = [[RCIM sharedRCIM] getUserInfoCache:user.userId];
            } else if (strongSelf.messageModel.conversationType == ConversationType_GROUP) {
                userInfo = [[RCIM sharedRCIM] getGroupUserInfoCache:user.userId
                                                        withGroupId:strongSelf.messageModel.targetId];
            }

            RCMessageReadDetailCellViewModel *cellVM =
            [[RCMessageReadDetailCellViewModel alloc] initWithUserInfo:userInfo
                                                                  readTime:user.timestamp];
            [userList addObject:cellVM];
        }

        NSString *resultPageToken = result.pageToken ?: @"";
        if (isRead) {
            strongSelf.readPageToken = resultPageToken;
        } else {
            strongSelf.unreadPageToken = resultPageToken;
        }

        BOOL hasMoreData = (resultPageToken.length > 0);
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.responder updateUserListForTabType:tabType 
                                              isEmpty:(userList.count == 0) 
                                          hasMoreData:hasMoreData];
        });
    
    }];
}

- (void)loadMoreData {
    BOOL isRead = (self.currentTabType == RCMessageReadDetailTabTypeRead);
    NSString *pageToken = isRead ? self.readPageToken : self.unreadPageToken;
    
    if (pageToken.length == 0) {
        return;
    }
    
    [self loadUserListWithType:self.currentTabType pageToken:pageToken];
}

- (void)loadReadReceiptInfo:(void (^)(void))completion {
    void (^safeCompletion)(void) = ^(void) {
        !completion ?: completion();
    };
    // 如果已经有了 readReceiptInfoV5，则不需要重新获取
    if (self.messageModel.readReceiptInfoV5) {
        safeCompletion();
        return;
    }
    
    RCConversationIdentifier *identifier = [[RCConversationIdentifier alloc] init];
    identifier.type = self.messageModel.conversationType;
    identifier.targetId = self.messageModel.targetId;
    
    __weak typeof(self) weakSelf = self;
    [[RCCoreClient sharedCoreClient] getMessageReadReceiptInfoV5:identifier
                                                     messageUIds:@[self.messageModel.messageUId]
                                                      completion:^(NSArray<RCReadReceiptInfoV5 *> * _Nullable infoList, RCErrorCode code) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // 重试
        void (^retryBlock)(void) = ^(void){
            if (strongSelf.readInfoRetryCount < kRCReadReceiptMaxRetryCount) {
                strongSelf.readInfoRetryCount++;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kRCReadReceiptRetryDelay), dispatch_get_main_queue(), ^{
                    [strongSelf loadReadReceiptInfo:completion];
                });
            } else {
                safeCompletion();
            }
        };
        
        if (code == RC_REQUEST_OVERFREQUENCY) {
            retryBlock();
            return;
        }
        
        if (code == RC_SUCCESS) {
            // 成功
            dispatch_async(dispatch_get_main_queue(), ^{
                if (infoList.count > 0) {
                    strongSelf.readInfoRetryCount = 0; // 成功清零
                    RCReadReceiptInfoV5 *info = infoList.firstObject;
                    strongSelf.messageModel.readReceiptInfoV5 = info;
                    [strongSelf.responder updateTabViewWithReadCount:info.readCount unreadCount:info.unreadCount];
                    safeCompletion();
                } else {
                    // 空数据：首次打开可能出现，调用重试
                    retryBlock();
                }
            });
        }
    }];
}

#pragma mark - utils

- (NSMutableArray<RCMessageReadDetailCellViewModel *> *)currentUserList {
    if (self.currentTabType == RCMessageReadDetailTabTypeUnread) {
        return self.unreadUserList;
    }
    return self.readUserList;
}

- (NSInteger)getReadCount {
    return self.messageModel.readReceiptInfoV5.readCount;
}

- (NSInteger)getUnreadCount {
    return self.messageModel.readReceiptInfoV5.unreadCount;
}

- (NSInteger)getTotalCount {
    return [self getReadCount] + [self getUnreadCount];
}

- (NSInteger)numberOfSectionsForTabType:(RCMessageReadDetailTabType)tabType {
    return 1;
}

- (NSInteger)numberOfRowsForTabType:(RCMessageReadDetailTabType)tabType inSection:(NSInteger)section {
    NSArray<RCMessageReadDetailCellViewModel *> *userList = tabType == RCMessageReadDetailTabTypeRead
        ? self.readUserList
        : self.unreadUserList;
    
    return userList.count;
}

- (RCMessageReadDetailCellViewModel *)cellViewModelForTabType:(RCMessageReadDetailTabType)tabType atIndex:(NSInteger)index {
    NSArray<RCMessageReadDetailCellViewModel *> *userList = tabType == RCMessageReadDetailTabTypeRead
        ? self.readUserList
        : self.unreadUserList;
    
    // 索引越界检查
    if (index < 0 || index >= userList.count) {
        return nil;
    }
    
    return userList[index];
}

- (CGFloat)cellHeightForTabType:(RCMessageReadDetailTabType)tabType atIndex:(NSInteger)index {
    RCMessageReadDetailCellViewModel *cellViewModel = [self cellViewModelForTabType:tabType atIndex:index];
    return cellViewModel ? cellViewModel.cellHeight : 0;
}

@end
