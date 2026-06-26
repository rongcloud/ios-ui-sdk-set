//
//  RCAlbumModel.h
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/25.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RCAlbumModel : NSObject

@property (nonatomic, strong) NSString *albumName;

@property (nonatomic, assign) long count;

@property (nonatomic, strong) id asset;

+ (RCAlbumModel *)modelWithAsset:(id)asset name:(NSString *)string count:(long)count;

@end
