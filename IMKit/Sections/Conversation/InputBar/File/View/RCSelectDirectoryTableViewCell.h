//
//  RCSelectDirectoryTableViewCell.h
//  RongExtensionKit
//
//  Created by Jue on 16/8/17.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseTableViewCell.h"
#import "RCBaseImageView.h"
#import "RCBaseLabel.h"
@interface RCSelectDirectoryTableViewCell : RCBaseTableViewCell

@property (nonatomic, strong) RCBaseImageView *directoryImageView;

@property (nonatomic, strong) RCBaseLabel *directoryNameLabel;

@end
