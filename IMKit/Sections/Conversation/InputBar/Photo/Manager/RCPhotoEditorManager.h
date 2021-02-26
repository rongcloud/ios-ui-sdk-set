//
//  RCPhotoEditorManager.h
//  RongExtensionKit
//
//  Created by Zqy on 2018/1/18.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RCAssetModel;
@interface RCPhotoEditorManager : NSObject

+ (instancetype)sharedManager;

- (void)addEditPhoto:(NSString *)localIdentifier andAssetModel:(RCAssetModel *)assetModel;

- (BOOL)hasBeenEdit:(NSString *)localIdentifier;

- (RCAssetModel *)getEditPhoto:(NSString *)localIdentifier;

- (void)removeAllEditPhotos;

@end
