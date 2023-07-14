//
//  RCPublicServiceProfileUrlCell.h
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCPublicServiceProfileViewController.h"
#import <UIKit/UIKit.h>
#import "RCBaseTableViewCell.h"
@interface RCPublicServiceProfileUrlCell : RCBaseTableViewCell
- (void)setTitle:(NSString *)title
             url:(NSString *)urlString
        delegate:(id<RCPublicServiceProfileViewUrlDelegate>)delegate;
@end
