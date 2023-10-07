//
//  RCConversationListDataSource.h
//  RongIMKit
//
//  Created by Sin on 2020/5/26.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCConversationModel.h"

@protocol RCConversationListDataSourceDelegate;


/// 会话列表页面的数据源，负责数据的获取、处理，通知会话列表页面刷新数据

/// 普通类，由会话列表页面持有
@interface RCConversationListDataSource : NSObject

/// 需要展示的会话类型，通过该字段获取匹配的会话类型的数据
@property (nonatomic, strong) NSArray *displayConversationTypeArray;

/// 需要聚合的会话类型，通过该字段将特定的会话聚合
@property (nonatomic, strong) NSArray *collectionConversationTypeArray;

/// 普通模式和暗黑模式下，cell 背景色
@property (nonatomic, strong) UIColor *cellBackgroundColor;

/// 普通模式和暗黑模式下，置顶 cell 背景色
@property (nonatomic, strong) UIColor *topCellBackgroundColor;

/// 会话列表页面是否处于 appear 状态，主要是当会话列表页面不出现的时候，收到消息不用刷新会话列表页面，等会话列表页 viewWillAppear 时候会重新获取会话
@property (nonatomic, assign) BOOL isConverstaionListAppear;

/// 数据源，会话列表页的数据源，非线程安全，需在主线程处理
@property (nonatomic, strong) NSMutableArray *dataList;

/// 数据源代理，主要是部分数据处理完成之后回调给会话列表页面，让会话列表页面进行页面刷新
@property (nonatomic, weak) id<RCConversationListDataSourceDelegate> delegate;

/// 强制获取会话列表数据，一般在 viewWillApper 调用
/// @param completion 会话列表数据
/// @discussion 回调在 UI 线程
- (void)forceLoadConversationModelList:(void (^)(NSMutableArray<RCConversationModel *> *modelList))completion;

/// 加载更多绘画猎豹数据，一般是 上拉操作调用
/// @param completion 上拉新增的会话列表数据
/// @discussion 回调在 UI 线程
- (void)loadMoreConversations:(void (^)(NSMutableArray<RCConversationModel *> *modelList))completion;

/// 刷新单个会话
/// @param conversationModel 需要刷新的会话
- (void)refreshConversationModel:(RCConversationModel *)conversationModel;

/// 收到消息的通知，原则上不应该由会话列表监听该通知透传到该类
/// 但是会话列表对外接口已经声明了 didReceiveMessageNotification: 为了接口兼容，做了这样的处理
/// @param notification 携带消息的通知
- (void)didReceiveMessageNotification:(NSNotification *)notification;
@end

@protocol RCConversationListDataSourceDelegate <NSObject>

- (NSMutableArray<RCConversationModel *> *)dataSource:(RCConversationListDataSource *)datasource willReloadTableData:(NSMutableArray<RCConversationModel *> *)modelList;

- (void)dataSource:(RCConversationListDataSource *)dataSource willReloadAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths;
- (void)dataSource:(RCConversationListDataSource *)dataSource willInsertAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths;
- (void)dataSource:(RCConversationListDataSource *)dataSource willDeleteAtIndexPaths:(NSArray <NSIndexPath *> *)deleteIndexPaths willInsertAtIndexPaths:(NSArray <NSIndexPath *> *)insertIndexPaths;

- (void)refreshConversationTableViewIfNeededInDataSource:(RCConversationListDataSource *)datasource;

- (void)notifyUpdateUnreadMessageCountInDataSource;
@end
