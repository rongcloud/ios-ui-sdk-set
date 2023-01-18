//
//  RCCSStarView.m
//  RongSelfBuiltCustomerDemo
//
//  Created by 张改红 on 2016/12/6.
//  Copyright © 2016年 rongcloud. All rights reserved.
//

#import "RCCSStarView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
@interface RCCSStarView ()
@property (nonatomic) int starValue; // 0-4
@property (nonatomic, strong) NSArray *starButtonArray;
@end
@implementation RCCSStarView
- (instancetype)initWithFrame:(CGRect)startFrame
                    starIndex:(NSInteger)index
                    starWidth:(CGFloat)starWidth
                        space:(CGFloat)space
                 defaultImage:(UIImage *)defaultImage
                   lightImage:(UIImage *)lightImage
                     isCanTap:(BOOL)isCanTap {

    self = [super initWithFrame:startFrame];
    if (self) {

        if (defaultImage) {
            self.defaultImage = defaultImage;
        } else {
            self.defaultImage = RCResourceImage(@"custom_service_evaluation_star");
        }

        if (lightImage) {
            self.lightImage = lightImage;
        } else {
            self.lightImage = RCResourceImage(@"custom_service_evaluation_star_hover");
        }

        for (NSInteger j = 0; j < 5; j++) {
            UIButton *btn = [[UIButton alloc]
                initWithFrame:CGRectMake(j * (starWidth + space), 0, starWidth, startFrame.size.height)];

            btn.enabled = YES;
            btn.tag = j + 1;
            [btn addTarget:self action:@selector(starTapBtn:) forControlEvents:UIControlEventTouchUpInside];
            // 上左下右 星星居中
            [btn setImageEdgeInsets:UIEdgeInsetsMake((startFrame.size.height - starWidth) / 2, 0,
                                                     (startFrame.size.height - starWidth) / 2, 0)];
            if (j < index) {
                [btn setImage:self.lightImage forState:UIControlStateNormal];
            } else {
                [btn setImage:self.defaultImage forState:UIControlStateNormal];
            }
            [self addSubview:btn];

            // self.width
            startFrame.size.width = (starWidth + space) * 5;
            self.frame = startFrame;
        }
    }
    return self;
}

- (void)starTapBtn:(UIButton *)btn {
    for (NSInteger i = 1; i <= 5; i++) {
        UIButton *starBtn = (UIButton *)[self viewWithTag:i];
        if (i <= btn.tag) {
            [starBtn setImage:self.lightImage forState:UIControlStateNormal];
        } else {
            [starBtn setImage:self.defaultImage forState:UIControlStateNormal];
        }
    }

    if (self.starEvaluateBlock) {
        self.starEvaluateBlock(self, btn.tag);
    }
}
@end
