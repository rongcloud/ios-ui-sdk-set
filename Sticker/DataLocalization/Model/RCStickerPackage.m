//
//  RCStickerPackage.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerPackage.h"
#import "RCStickerUtility.h"

@implementation RCStickerPackage

RCSticker_CODER_DECODER();

- (void)setConfig:(RCStickerPackageConfig *)packageConfig {
    self.packageId = packageConfig.packageId;
    self.name = packageConfig.name;
    self.author = packageConfig.author;
    self.icon = packageConfig.icon;
    self.isPreload = packageConfig.isPreload;
    self.cover = packageConfig.cover;
    self.copyright = packageConfig.copyright;
    self.createTime = packageConfig.createTime;
    self.digest = packageConfig.digest;
    self.order = packageConfig.order;
    self.pkgType = packageConfig.pkgType;
}

+ (RCStickerPackage *)modelWithDict:(NSDictionary *)dict {
    RCStickerPackage *model = [[RCStickerPackage alloc] init];
    model.packageId = [dict objectForKey:@"packageId"];
    model.name = [dict objectForKey:@"name"];
    model.author = [dict objectForKey:@"author"];
    model.icon = [dict objectForKey:@"icon"];
    model.isPreload = [[dict objectForKey:@"isPreload"] boolValue];
    model.cover = [dict objectForKey:@"cover"];
    model.copyright = [dict objectForKey:@"copyright"];
    model.createTime = [dict objectForKey:@"createTime"];
    model.digest = [dict objectForKey:@"digest"];
    model.order = [[dict objectForKey:@"order"] longValue];
    model.pkgType = [[dict objectForKey:@"pkgType"] longValue];
    model.isDownloaded = [[dict objectForKey:@"isDownloaded"] boolValue];
    model.isDeleted = [[dict objectForKey:@"isDeleted"] boolValue];
    return model;
}

+ (NSDictionary *)dictWithModel:(RCStickerPackage *)model {

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:model.packageId forKey:@"packageId"];
    [dict setObject:model.name forKey:@"name"];
    [dict setObject:model.author forKey:@"author"];
    [dict setObject:model.icon forKey:@"icon"];
    [dict setObject:@(model.isPreload) forKey:@"isPreload"];
    [dict setObject:model.cover forKey:@"cover"];
    [dict setObject:model.createTime forKey:@"createTime"];
    [dict setObject:model.digest forKey:@"digest"];
    [dict setObject:@(model.order) forKey:@"order"];
    [dict setObject:@(model.pkgType) forKey:@"pkgType"];
    [dict setObject:@(model.isDownloaded) forKey:@"isDownloaded"];
    [dict setObject:@(model.isDeleted) forKey:@"isDeleted"];
    return [dict copy];
}

+ (NSArray *)modelArrayWithDictArray:(NSArray *)dicts {
    NSMutableArray *models = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in dicts) {
        RCStickerPackage *model = [[self class] modelWithDict:dict];
        [models addObject:model];
    }
    return [models copy];
}

+ (NSArray *)dictArrayWithModelArray:(NSArray *)models {
    NSMutableArray *dicts = [[NSMutableArray alloc] init];
    for (RCStickerPackage *model in models) {
        NSDictionary *dict = [[self class] dictWithModel:model];
        [dicts addObject:dict];
    }
    return [dicts copy];
}

@end
