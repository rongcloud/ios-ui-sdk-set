//
//  RCCSStarView.h
//  RongSelfBuiltCustomerDemo
//
//  Created by 张改红 on 2016/12/6.
//  Copyright © 2016年 rongcloud. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface RCCSStarView : UIView
@property (nonatomic, copy) void (^starEvaluateBlock)(RCCSStarView *starView, NSInteger index);

@property (nonatomic, strong) UIImage *defaultImage;

@property (nonatomic, strong) UIImage *lightImage;

- (instancetype)initWithFrame:(CGRect)startFrame
                    starIndex:(NSInteger)index
                    starWidth:(CGFloat)starWidth
                        space:(CGFloat)space
                 defaultImage:(UIImage *)defaultImage
                   lightImage:(UIImage *)lightImage
                     isCanTap:(BOOL)isCanTap;

@end
