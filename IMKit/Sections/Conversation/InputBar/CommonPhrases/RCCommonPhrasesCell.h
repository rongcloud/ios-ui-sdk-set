//
//  RCCommonPhrasesCell.h
//  RongExtensionKit
//
//  Created by liyan on 2019/7/9.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseTableViewCell.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCCommonPhrasesCell : RCBaseTableViewCell

+ (CGFloat)heightForCommonPhrasesCell:(NSString *)text;

- (void)setLableText:(NSString *)lableText;

@end

NS_ASSUME_NONNULL_END
