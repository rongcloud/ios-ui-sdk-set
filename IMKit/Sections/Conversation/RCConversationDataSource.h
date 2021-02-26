//
//  RCConversationDataSource.h
//  RongIMKit
//
//  Created by Sin on 2020/7/6.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class RCConversationViewController,RCMessageModel,RCMessage,RCConversationViewLayout,RCConversation;

@interface RCConversationDataSource : NSObject

- (instancetype)init:(RCConversationViewController *)chatVC;
//是否所有消息都已经加载完成
@property (nonatomic, assign, readonly) BOOL allMessagesAreLoaded;
//collection 的 layout
@property (nonatomic, strong, readonly) RCConversationViewLayout *customFlowLayout;
//显示查看未读的消息 id
@property (nonatomic, assign, readonly) long long showUnreadViewMessageId;
//聊天页面上下滑动加载更多消息时，当有菊花转时，该值为 yes，加载消息完成后为 no，避免频繁滑动加载过快
@property (nonatomic, assign, readonly) BOOL isIndicatorLoading;
//是否正在加载历史消息
@property (nonatomic, assign, readonly) BOOL isLoadingHistoryMessage;
// 用于统计在当前页面时右下角未读数的显示
@property (nonatomic, strong) NSMutableArray *unreadNewMsgArr;

@property (nonatomic, strong) NSMutableArray *unreadMentionedMessages;

//进入聊天页面初次加载的消息
- (void)getInitialMessage:(RCConversation *)conversation;

- (void)loadLatestHistoryMessage;

//聊天页面滚动到顶部再拉历史消息调
- (void)loadMoreHistoryMessageIfNeed;
//设置消息是否显示用户名称
- (RCMessageModel *)setModelIsDisplayNickName:(RCMessageModel *)model;
//往数据源中添加发送出去的消息
- (void)appendSendOutMessage:(RCMessage *)message;

- (void)appendAndDisplayMessage:(RCMessage *)rcMessage;
//撤回消息
- (void)didRecallMessage:(RCMessage *)recalledMsg;
//刷新被撤回消息的 UI
- (void)didReloadRecalledMessage:(long)recalledMsgId;

//聊天页面滚动着加载更多历史消息
- (void)scrollToLoadMoreHistoryMessage;
//聊天页面滚动着加载更多新消息
- (void)scrollToLoadMoreNewerMessage;
//聊天页面滚动到合适的位置，滚动到第一条未读的 @ 消息或者用户指定时间的消息
- (void)scrollToSuitablePosition;
//在聊天页面 disappear 时取消所有的数据源追加消息的操作
- (void)cancelAppendMessageQueue;
//点击右下角消息未读个数的按钮
- (void)tapRightBottomMsgCountIcon:(UIGestureRecognizer *)gesture;
//点击右上角未读消息个数的按钮
- (void)tapRightTopMsgUnreadButton;
- (void)tapRightTopUnReadMentionedButton:(UIButton *)sender;
//viewWillDisappear 清空未读的 @ 消息
- (void)clearUnreadMentionedMessages;

- (void)quitChatRoomIfNeed;

- (void)setupUnReadMentionedButton;

- (void)removeMentionedMessage:(long )curMessageId;

#pragma mark - Notification
//处理聊天页面收到的消息
- (void)didReceiveMessageNotification:(RCMessage *)rcMessage leftDic:(NSDictionary *)leftDic;
@end
