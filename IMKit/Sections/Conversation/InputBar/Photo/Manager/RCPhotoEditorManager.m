//
//  RCPhotoEditorManager.m
//  RongExtensionKit
//
//  Created by Zqy on 2018/1/18.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCPhotoEditorManager.h"

@interface RCPhotoEditorManager ()

@property (nonatomic, strong) NSMutableDictionary *editPhotos;

@end

@implementation RCPhotoEditorManager

+ (instancetype)sharedManager {
    static RCPhotoEditorManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[RCPhotoEditorManager alloc] init];
        sharedManager.editPhotos = [[NSMutableDictionary alloc] init];
    });
    return sharedManager;
}

- (void)addEditPhoto:(NSString *)localIdentifier andAssetModel:(RCAssetModel *)assetModel {

    @synchronized(self) {
        [self.editPhotos setObject:assetModel forKey:localIdentifier];
    }
}

- (BOOL)hasBeenEdit:(NSString *)localIdentifier {

    @synchronized(self) {
        if ([self.editPhotos valueForKey:localIdentifier] != nil) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (RCAssetModel *)getEditPhoto:(NSString *)localIdentifier {
    @synchronized(self) {
        if ([self.editPhotos valueForKey:localIdentifier] != nil) {
            return [self.editPhotos valueForKey:localIdentifier];
        } else {
            return nil;
        }
    }
}

- (void)removeAllEditPhotos {
    @synchronized(self) {
        [self.editPhotos removeAllObjects];
    }
}

@end
