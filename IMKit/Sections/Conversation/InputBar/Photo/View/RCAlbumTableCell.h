//
//  RCAlbumTableCell.h
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/18.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCAlbumModel.h"
#import "RCAssetHelper.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface RCAlbumTableCell : UITableViewCell

- (void)configCellWithItem:(RCAlbumModel *)model;

@end
