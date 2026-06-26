//
//  RCPluginBoardHorizontalCollectionViewLayout.m
//  RongExtensionKit
//
//  Created by Liv on 15/3/16.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPluginBoardHorizontalCollectionViewLayout.h"

#define RCPlaginBoardCellSize ((CGSize){75, 80})
#define HorizontalItemsCount 4
#define VerticalItemsCount 2
#define ItemsPerPage (HorizontalItemsCount * VerticalItemsCount)

@implementation RCPluginBoardHorizontalCollectionViewLayout
- (instancetype)init {
    self = [super init];
    if (self) {
        _itemsPerSection = ItemsPerPage;
        self.itemSize = RCPlaginBoardCellSize;
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

- (CGSize)collectionViewContentSize {
    NSInteger sectionNumber = [self.collectionView numberOfSections];
    CGSize size = self.collectionView.bounds.size;
    size.width = sectionNumber * size.width;
    return size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributes = [NSMutableArray array];
    for (NSInteger i = 0; i < self.collectionView.numberOfSections; i++) {
        for (NSInteger j = 0; j < [self.collectionView numberOfItemsInSection:i]; j++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:i];
            [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
        }
    }
    return attributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return NO;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes
        layoutAttributesForCellWithIndexPath:
            path]; //生成空白的attributes对象，其中只记录了类型是cell以及对应的位置是indexPath
                   //    CGFloat horizontalInsets = (self.collectionView.bounds.size.width - RCPlaginBoardCellSize.width
                   //    *HorizontalItemsCount) /(HorizontalItemsCount + 1);

    NSInteger currentPage = path.section;
    NSInteger currentRow = (NSInteger)floor((double)(path.row) / (double)HorizontalItemsCount);
    NSInteger currentColumn = path.row % HorizontalItemsCount;
    CGRect frame = attributes.frame;
    float leftOffset = (self.collectionView.bounds.size.width - 75 * 4) / 5.0;

    frame.origin.x = self.itemSize.width * currentColumn + leftOffset * (currentColumn + 1) +
                     currentPage * self.collectionView.bounds.size.width;
    frame.origin.y = self.itemSize.height * currentRow + 15 + currentRow * 18;
    frame.size.width = RCPlaginBoardCellSize.width;
    frame.size.height = RCPlaginBoardCellSize.height;
    attributes.frame = frame;
    return attributes;
}

@end
