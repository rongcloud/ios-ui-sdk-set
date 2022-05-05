//
//  RCConversationViewLayout.m
//  RongIMKit
//
//  Created by zhaobingdong on 2018/6/13.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCConversationViewLayout.h"

@implementation RCConversationViewLayout

- (instancetype)init {
    if (self = [super init]) {
        self.minimumLineSpacing = 0.0f;
        self.sectionInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
    }
    return self;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset {
    CGFloat offset = self.collectionViewNewContentSize.height - self.collectionView.contentSize.height;
    if (offset > 0) {
        proposedContentOffset.y += offset;
    }
    return proposedContentOffset;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind
                                                                     atIndexPath:(NSIndexPath *)indexPath {
    if (![super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath]) {
        UICollectionViewLayoutAttributes *layoutAttributes =
            [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind
                                                                           withIndexPath:indexPath];
        return layoutAttributes;
    } else {
        UICollectionViewLayoutAttributes *layoutAttributes =
            [super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
        return layoutAttributes;
    }
}
@end
