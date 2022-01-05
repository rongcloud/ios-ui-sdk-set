//
//  RCMenuContainerView.h
//  RongIMKit
//
//  Created by RongCloud on 2020/5/26.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCPublicServiceMenu,RCPublicServiceMenuItem;
@protocol RCMenuContainerViewDelegate;

@interface RCMenuContainerView : UIView

/*!
 Public Service Menu
 */
@property (nonatomic, strong) RCPublicServiceMenu *publicServiceMenu;

@property (nonatomic, weak) id<RCMenuContainerViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame containerView:(UIView *)containerView;

- (void)setPublicServiceMenu:(RCPublicServiceMenu *)publicServiceMenu;

- (void)dismissPublicServiceMenuPopupView;
@end

@protocol RCMenuContainerViewDelegate <NSObject>

- (void)onPublicServiceMenuItemSelected:(RCPublicServiceMenuItem *)selectedMenuItem;

@end
