//
//  RCAlbumModel.m
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/25.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCAlbumModel.h"

@implementation RCAlbumModel
+ (RCAlbumModel *)modelWithAsset:(id)asset name:(NSString *)string count:(long)count {
    RCAlbumModel *model = [[RCAlbumModel alloc] init];
    model.asset = asset;
    model.albumName = string?:@"";
    model.count = count;
    return model;
}
@end
