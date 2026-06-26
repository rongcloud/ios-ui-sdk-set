//
//  RCSightCollectionViewCell.h
//  RongIMKit
//
//  Created by zhaobindong on 2017/5/3.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCBaseCollectionViewCell.h"
@class RCSightModel;

@protocol RCSightCollectionViewCellDelegate <NSObject>
@optional
- (void)closeSight;

- (void)playEnd;

- (void)sightLongPressed:(NSString *)localPath;

@end

@interface RCSightCollectionViewCell : RCBaseCollectionViewCell

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, weak) id<RCSightCollectionViewCellDelegate> delegate;

@property (nonatomic, assign, getter=isAutoPlay) BOOL autoPlay;

- (void)setDataModel:(RCSightModel *)model;

- (void)stopPlay;

- (void)resetPlay;

@end
