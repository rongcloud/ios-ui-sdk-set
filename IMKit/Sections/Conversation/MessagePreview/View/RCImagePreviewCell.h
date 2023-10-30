//
//  RCImagePreviewCell.h
//  RongIMKit
//
//  Created by zhanggaihong on 2021/5/27.
//  Copyright © 2021年 RongCloud. All rights reserved.
//

#import "RCBaseCollectionViewCell.h"

@class RCMessageModel, RCImagePreviewCell;
@protocol RCImagePreviewCellDelegate <NSObject>

- (void)imagePreviewCellDidSingleTap:(RCImagePreviewCell *)cell;

- (void)imagePreviewCellDidLongTap:(UILongPressGestureRecognizer *)sender;

@end

@interface RCImagePreviewCell : RCBaseCollectionViewCell

@property (nonatomic, weak)  id<RCImagePreviewCellDelegate> delegate;

@property (nonatomic, strong) RCMessageModel *messageModel;

- (void)configPreviewCellWithItem:(RCMessageModel *)model;

- (void)resetSubviews;

@end

