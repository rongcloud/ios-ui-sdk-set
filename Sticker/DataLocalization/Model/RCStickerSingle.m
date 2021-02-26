//
//  RCStickerSingle.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerSingle.h"
#import "RCStickerUtility.h"

@implementation RCStickerSingle

RCSticker_CODER_DECODER();

+ (RCStickerSingle *)modelWithDict:(NSDictionary *)dict {
    RCStickerSingle *model = [[RCStickerSingle alloc] init];
    model.stickerId = [dict objectForKey:@"stickerId"];
    model.digest = [dict objectForKey:@"digest"];
    model.pkgId = [dict objectForKey:@"pkgId"];
    model.thumbUrl = [dict objectForKey:@"thumbUrl"];
    model.url = [dict objectForKey:@"url"];
    model.width = [[dict objectForKey:@"width"] longValue];
    model.height = [[dict objectForKey:@"height"] longValue];
    model.order = [[dict objectForKey:@"order"] longValue];
    return model;
}

+ (NSDictionary *)dictWithModel:(RCStickerSingle *)model {

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:model.stickerId forKey:@"stickerId"];
    [dict setObject:model.digest forKey:@"digest"];
    [dict setObject:model.pkgId forKey:@"pkgId"];
    [dict setObject:model.thumbUrl forKey:@"thumbUrl"];
    [dict setObject:model.url forKey:@"url"];
    [dict setObject:@(model.width) forKey:@"width"];
    [dict setObject:@(model.height) forKey:@"height"];
    [dict setObject:@(model.order) forKey:@"order"];
    return [dict copy];
}

+ (NSArray *)modelArrayWithDictArray:(NSArray *)dicts {
    NSMutableArray *models = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in dicts) {
        RCStickerSingle *model = [[self class] modelWithDict:dict];
        [models addObject:model];
    }
    return [models copy];
}

+ (NSArray *)dictArrayWithModelArray:(NSArray *)models {
    NSMutableArray *dicts = [[NSMutableArray alloc] init];
    for (RCStickerSingle *model in models) {
        NSDictionary *dict = [[self class] dictWithModel:model];
        [dicts addObject:dict];
    }
    return [dicts copy];
}

@end
