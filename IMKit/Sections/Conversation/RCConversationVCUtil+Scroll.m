//
//  RCConversationVCUtil+Scroll.m
//  RongIMKit
//
//  Created by Codex.
//

#import "RCConversationVCUtil+Scroll.h"

#import "RCConversationViewController.h"
#import "RCConversationViewController+internal.h"
#import "RCConversationVCUtil+internal.h"

@implementation RCConversationVCUtil (Scroll)

- (BOOL)rc_shouldKeepAtBottomForMessageReactionReload {
    UICollectionView *collectionView = self.chatVC.conversationMessageCollectionView;
    if (!collectionView || [self rc_isUserInteractingWithMessageReactionCollectionView:collectionView]) {
        return NO;
    }
    CGFloat visibleBottomY = collectionView.contentOffset.y + CGRectGetHeight(collectionView.bounds);
    CGFloat contentBottomY = collectionView.contentSize.height + collectionView.contentInset.bottom;
    return contentBottomY - visibleBottomY <= 10.0;
}

- (BOOL)rc_isUserInteractingWithMessageReactionCollectionView:(UICollectionView *)collectionView {
    return collectionView.isTracking || collectionView.isDragging || collectionView.isDecelerating || self.chatVC.isTouchScrolled;
}

- (void)rc_alignMessageReactionCollectionViewToBottomAfterLayout:(UICollectionView *)collectionView {
    if (!collectionView || [self rc_isUserInteractingWithMessageReactionCollectionView:collectionView]) {
        return;
    }
    [collectionView layoutIfNeeded];
    [self rc_alignMessageReactionCollectionViewToBottom:collectionView];
}

- (void)rc_alignMessageReactionCollectionViewToBottom:(UICollectionView *)collectionView {
    CGFloat minOffsetY = -collectionView.contentInset.top;
    CGFloat maxOffsetY =
        MAX(minOffsetY, collectionView.contentSize.height - CGRectGetHeight(collectionView.bounds) + collectionView.contentInset.bottom);
    if (fabs(collectionView.contentOffset.y - maxOffsetY) > 0.5) {
        [collectionView setContentOffset:CGPointMake(collectionView.contentOffset.x, maxOffsetY) animated:NO];
    }
}

- (NSIndexPath *)rc_messageReactionVisibleAnchorIndexPathInCollectionView:(UICollectionView *)collectionView {
    NSArray<NSIndexPath *> *visibleIndexPaths = [collectionView indexPathsForVisibleItems];
    if (visibleIndexPaths.count == 0) {
        return nil;
    }
    NSIndexPath *anchorIndexPath = nil;
    CGFloat minY = CGFLOAT_MAX;
    for (NSIndexPath *indexPath in visibleIndexPaths) {
        UICollectionViewLayoutAttributes *attributes =
            [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
        if (!attributes) {
            attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
        }
        if (!attributes) {
            continue;
        }
        if (CGRectGetMinY(attributes.frame) < minY) {
            minY = CGRectGetMinY(attributes.frame);
            anchorIndexPath = indexPath;
        }
    }
    return anchorIndexPath;
}

- (CGFloat)rc_messageReactionVisibleOffsetForAnchorIndexPath:(NSIndexPath *)indexPath
                                              collectionView:(UICollectionView *)collectionView {
    if (!indexPath || !collectionView) {
        return CGFLOAT_MAX;
    }
    UICollectionViewLayoutAttributes *attributes =
        [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
    if (!attributes) {
        attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
    }
    if (!attributes) {
        return CGFLOAT_MAX;
    }
    return CGRectGetMinY(attributes.frame) - collectionView.contentOffset.y;
}

- (void)rc_restoreMessageReactionVisibleOffset:(CGFloat)visibleOffset
                               anchorIndexPath:(NSIndexPath *)indexPath
                                collectionView:(UICollectionView *)collectionView
                             allowElasticOffset:(BOOL)allowElasticOffset {
    if (visibleOffset == CGFLOAT_MAX || !indexPath || !collectionView) {
        return;
    }
    UICollectionViewLayoutAttributes *attributes =
        [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
    if (!attributes) {
        attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
    }
    if (!attributes) {
        return;
    }
    CGFloat targetOffsetY = CGRectGetMinY(attributes.frame) - visibleOffset;
    if (!allowElasticOffset) {
        CGFloat minOffsetY = -collectionView.contentInset.top;
        CGFloat maxOffsetY =
            MAX(minOffsetY, collectionView.contentSize.height - CGRectGetHeight(collectionView.bounds) + collectionView.contentInset.bottom);
        targetOffsetY = MIN(MAX(targetOffsetY, minOffsetY), maxOffsetY);
    }
    if (fabs(collectionView.contentOffset.y - targetOffsetY) > 0.5) {
        [collectionView setContentOffset:CGPointMake(collectionView.contentOffset.x, targetOffsetY) animated:NO];
    }
}

@end
