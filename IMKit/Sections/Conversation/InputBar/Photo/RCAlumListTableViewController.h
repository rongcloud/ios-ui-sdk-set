//
//  RCAlumListTableViewController.h
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/18.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseTableViewController.h"

@protocol RCAlbumListViewControllerDelegate;
@interface RCAlumListTableViewController : RCBaseTableViewController
@property (nonatomic, strong) NSArray *libraryList;
/**
 是否开启了图片编辑功能
 */
@property (nonatomic, assign) BOOL photoEditEnable;
@property (nonatomic, weak) id<RCAlbumListViewControllerDelegate> delegate;
@end

@protocol RCAlbumListViewControllerDelegate <NSObject>

- (void)albumListViewController:(RCAlumListTableViewController *)albumListViewController
                 selectedImages:(NSArray *)selectedImages
                isSendFullImage:(BOOL)enable;

- (void)onClickEditPhoto:(UIViewController *)rootCtrl previewImage:(UIImage *)previewImage;

@end
