//
//  RCMessageModel+Txt.h
//  RongIMKit
//
//  Created by RobinCui on 2022/5/20.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCMessageModel (Txt)
@property (nonatomic, assign) CGSize txt_textSize;

- (CGSize)txt_textSizeWithMaxWidth:(CGFloat)maxWidth;

@end

NS_ASSUME_NONNULL_END
