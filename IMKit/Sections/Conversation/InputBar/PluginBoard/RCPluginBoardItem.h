//
//  RCPluginBoardItem.h
//  RongExtensionKit
//
//  Created by Liv on 15/3/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCPluginBoardItem : UICollectionViewCell

@property (nonatomic, copy) NSString *title;

@property (nonatomic, strong) UIImage *normalImage;

@property (nonatomic, strong) UIImage *highlightedImage;

@property (nonatomic, copy) void (^Itemclick)(void);

- (instancetype)initWithTitle:(NSString *)title
                  normalImage:(UIImage *)normalImage
             highlightedImage:(UIImage *)highlightedImage
                          tag:(NSInteger)tag;

- (void)loadView;
@end
