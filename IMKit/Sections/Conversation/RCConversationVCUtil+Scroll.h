//
//  RCConversationVCUtil+Scroll.h
//  RongIMKit
//
//  Created by Codex.
//

#import "RCConversationVCUtil.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCConversationVCUtil (Scroll)

/// 判断消息回应刷新时，当前列表是否已经接近底部，需要继续保持贴底刷新。
- (BOOL)rc_shouldKeepAtBottomForMessageReactionReload;
/// 判断当前 collectionView 是否正处于用户交互中，交互期间允许保留弹性偏移。
- (BOOL)rc_isUserInteractingWithMessageReactionCollectionView:(UICollectionView *)collectionView;
/// 在消息回应刷新完成后按当前内容高度对齐到底部。
- (void)rc_alignMessageReactionCollectionViewToBottomAfterLayout:(UICollectionView *)collectionView;
/// 选取当前可见区域中最靠上的消息作为滚动锚点，用于刷新后恢复位置。
- (NSIndexPath *)rc_messageReactionVisibleAnchorIndexPathInCollectionView:(UICollectionView *)collectionView;
/// 计算锚点消息在当前视口中的可见偏移量，刷新后用来还原原始位置。
- (CGFloat)rc_messageReactionVisibleOffsetForAnchorIndexPath:(NSIndexPath *)indexPath
                                              collectionView:(UICollectionView *)collectionView;
/// 根据锚点和偏移量恢复刷新前的可见位置，可按需限制在内容边界内。
- (void)rc_restoreMessageReactionVisibleOffset:(CGFloat)visibleOffset
                               anchorIndexPath:(NSIndexPath *)indexPath
                                collectionView:(UICollectionView *)collectionView
                             allowElasticOffset:(BOOL)allowElasticOffset;

@end

NS_ASSUME_NONNULL_END
