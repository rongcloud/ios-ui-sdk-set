//
//  RCCCContactTableViewCell.h
//  RongContactCard
//
//  Created by Jue on 16/3/16.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCloudImageView.h"
#import "RongContactCardAdaptiveHeader.h"
@interface RCCCContactTableViewCell : RCBaseTableViewCell

@property (nonatomic, strong) RCloudImageView *portraitView;

@property (nonatomic, strong) RCBaseLabel *nicknameLabel;

@property (nonatomic, strong) RCBaseLabel *userIdLabel;

@end
