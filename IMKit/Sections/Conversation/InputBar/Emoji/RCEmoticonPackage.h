//
//  RCEmoticonPackage.h
//  RongExtensionKit
//
//  Created by 杜立召 on 16/7/27.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCEmojiBoardView.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RCEmoticonPackage : NSObject

/**
 *  表情包唯一标示
 */
@property (nonatomic, copy) NSString *identify;

//表情包总页数
@property (nonatomic, assign) int totalPage;

// tabIcon
@property (nonatomic, strong) UIImage *tabImage;

/**
 *  表情包容器
 */
@property (nonatomic, strong) UIScrollView *emotionContainerView;

/**
 *  表情数据源
 */
@property (nonatomic, strong) id<RCEmoticonTabSource> tabSource;

@property (nonatomic, weak) RCEmojiBoardView *emojBoardView;

- (id)initEmoticonPackage:(UIImage *)tabImage withTotalCount:(int)pageCount;

- (void)showEmoticonView:(int)index;

- (void)setNeedLayout;
@end
