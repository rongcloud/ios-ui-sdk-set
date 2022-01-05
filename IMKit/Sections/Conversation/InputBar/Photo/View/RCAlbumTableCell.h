//
//  RCAlbumTableCell.h
//  RongExtensionKit
//
//  Created by RongCloud on 16/3/18.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import "RCAlbumModel.h"
#import "RCAssetHelper.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface RCAlbumTableCell : UITableViewCell

- (void)configCellWithItem:(RCAlbumModel *)model;

@end
