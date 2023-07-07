//
//  RCPublicServiceListViewCell.h
//  HelloIos
//
//  Created by litao on 15/4/9.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCThemeDefine.h"
#import "RCloudImageView.h"
#import <UIKit/UIKit.h>
@interface RCPublicServiceListViewCell : UITableViewCell
@property (nonatomic, strong) RCloudImageView *headerImageView;
@property (nonatomic) RCUserAvatarStyle portraitStyle;
@property (nonatomic, copy) NSString *searchKey;
- (void)setName:(NSString *)name;
- (void)setDescription:(NSString *)description;

@end
