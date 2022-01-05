//
//  RCTipLabel.h
//  iOS-IMKit
//
//  Created by Gang Li on 10/27/14.
//  Copyright (c) 2014 RongCloud. All rights reserved.
//

#import "RCAttributedLabel.h"
#import <UIKit/UIKit.h>

/*!
 *  \~chinese
 灰条提示Label
 
 *  \~english
 Gray bar prompts label 
 */
@interface RCTipLabel : RCAttributedLabel

/*!
 *  \~chinese
 边缘间隙
 
 *  \~english
 Edge clearance
 */
@property (nonatomic, assign) UIEdgeInsets marginInsets;

/*!
 *  \~chinese
 初始化灰条提示Label对象

 @return 灰条提示Label对象
 
 *  \~english
 Initialize the prompt label object of gray bar

 @ return prompt label object of gray bar
 */
+ (instancetype)greyTipLabel;

@end
