//
//  RCStickerCollectionView.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/14.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCStickerCollectionView : UIView

@property (nonatomic, strong) NSString *packageId;

- (instancetype)initWithStickers:(NSArray *)stickers;

@end
