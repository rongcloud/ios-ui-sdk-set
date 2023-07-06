//
//  RCUserListTableViewCell.h
//  RongExtensionKit
//
//  Created by 杜立召 on 16/7/14.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseTableViewCell.h"
#import "RCBaseImageView.h"
#import "RCBaseLabel.h"
@interface RCUserListTableViewCell : RCBaseTableViewCell
@property (nonatomic, strong) RCBaseImageView *headImageView; //头像
@property (nonatomic, strong) RCBaseLabel *nameLabel;         //姓名
@end
