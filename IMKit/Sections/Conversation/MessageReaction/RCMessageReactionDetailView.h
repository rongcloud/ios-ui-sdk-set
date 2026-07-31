//
//  RCMessageReactionDetailView.h
//  RongIMKit
//
//  Created by RC on 2026/6/9.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RCMessageReaction;
@class RCMessageReactionDetailView;
@class RCMessageReactionDetailUserItem;
@class RCMessageReactionUser;

@protocol RCMessageReactionDetailViewDelegate <NSObject>

- (void)messageReactionDetailViewDidDismiss:(RCMessageReactionDetailView *)detailView;
- (void)messageReactionDetailView:(RCMessageReactionDetailView *)detailView didSelectReaction:(RCMessageReaction *)reaction;
- (void)messageReactionDetailView:(RCMessageReactionDetailView *)detailView
           didRequestMoreUsersForReaction:(RCMessageReaction *)reaction
                            nextPageToken:(NSString *)nextPageToken;
- (void)messageReactionDetailView:(RCMessageReactionDetailView *)detailView
                       didTapUser:(RCMessageReactionUser *)user
                          reaction:(RCMessageReaction *)reaction;

@end

@interface RCMessageReactionDetailView : UIView

@property (nonatomic, weak, nullable) id<RCMessageReactionDetailViewDelegate> delegate;
@property (nonatomic, assign) CGFloat topLimitInset;

- (instancetype)initWithReactions:(NSArray<RCMessageReaction *> *)reactions
                 selectedReactionId:(NSString *)selectedReactionId;
- (void)showInView:(UIView *)view;
- (void)dismiss;
- (void)dismissAnimated:(BOOL)animated;
- (void)updateUserItems:(NSArray<RCMessageReactionDetailUserItem *> *)userItems
             totalCount:(NSInteger)totalCount
          nextPageToken:(nullable NSString *)nextPageToken
          forReactionId:(NSString *)reactionId
                 append:(BOOL)append;
- (void)endLoadingUsersForReactionId:(NSString *)reactionId;

@end

NS_ASSUME_NONNULL_END
