//
//  RCStickerPackageConfig.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerPackageConfig.h"
#import "RCStickerUtility.h"

@implementation RCStickerPackageConfig

RCSticker_CODER_DECODER();

+ (RCStickerPackageConfig *)modelWithDict:(NSDictionary *)dict {
    RCStickerPackageConfig *model = [[RCStickerPackageConfig alloc] init];
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
    return model;
}

+ (NSDictionary *)dictWithModel:(RCStickerPackageConfig *)model {

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
    return [dict copy];
}

+ (NSArray *)modelArrayWithDictArray:(NSArray *)dicts {
    NSMutableArray *models = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in dicts) {
        RCStickerPackageConfig *model = [[self class] modelWithDict:dict];
        [models addObject:model];
    }
    return [models copy];
}

+ (NSArray *)dictArrayWithModelArray:(NSArray *)models {
    NSMutableArray *dicts = [[NSMutableArray alloc] init];
    for (RCStickerPackageConfig *model in models) {
        NSDictionary *dict = [[self class] dictWithModel:model];
        [dicts addObject:dict];
    }
    return [dicts copy];
}

@end
