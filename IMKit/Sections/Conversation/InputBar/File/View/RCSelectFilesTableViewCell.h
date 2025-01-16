//
//  RCSelectFilesTableViewCell.h
//  RongExtensionKit
//
//  Created by Jue on 16/4/28.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseTableViewCell.h"
#import "RCBaseImageView.h"
#import "RCBaseLabel.h"
@interface RCSelectFilesTableViewCell : RCBaseTableViewCell

@property (nonatomic, strong) RCBaseImageView *selectedImageView;

@property (nonatomic, strong) RCBaseImageView *fileIconImageView;

@property (nonatomic, strong) RCBaseLabel *fileNameLabel;

@end
