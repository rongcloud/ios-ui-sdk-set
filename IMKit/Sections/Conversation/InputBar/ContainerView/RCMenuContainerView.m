//
//  RCMenuContainerView.m
//  RongIMKit
//
//  Created by 张改红 on 2020/5/26.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCMenuContainerView.h"
#import "RCKitCommonDefine.h"
#import "RCPublicServicePopupMenuView.h"
#import "RCKitConfig.h"
#import <RongPublicService/RCPublicServiceMenu.h>
#define RC_PUBLIC_SERVICE_MENU_ICON_GAP 6
#define RC_PUBLIC_SERVICE_MENU_SEPARATE_WIDTH 0.5
#define RC_PUBLIC_SERVICE_SUBMENU_PADDING 6
@interface RCMenuContainerView () <RCPublicServicePopupMenuItemSelectedDelegate>
@property (nonatomic, strong) RCPublicServicePopupMenuView *publicServicePopupMenu;
@end
@implementation RCMenuContainerView
- (instancetype)initWithFrame:(CGRect)frame containerView:(UIView *)containerView {
    self = [super initWithFrame:frame];
    if (self) {
        [containerView addSubview:self.publicServicePopupMenu];
    }
    return self;
}

#pragma mark - RCPublicServicePopupMenuItemSelectedDelegate

- (void)dismissPublicServiceMenuPopupView {
    [self.publicServicePopupMenu resignFirstResponder];
}

- (void)setPublicServiceMenu:(RCPublicServiceMenu *)publicServiceMenu {
    _publicServiceMenu = publicServiceMenu;
    for (UIView *subView in [self subviews]) {
        [subView removeFromSuperview];
    }

    NSUInteger count = publicServiceMenu.menuItems.count;
    CGRect round = self.bounds;
    CGFloat itemWidth = (round.size.width - (count - 1) * RC_PUBLIC_SERVICE_MENU_SEPARATE_WIDTH) / count;
    CGFloat itemHeight = round.size.height;

    for (int i = 0; i < count; i++) {
        RCPublicServiceMenuItem *menuItem = publicServiceMenu.menuItems[i];

        UIView *container =
            [[UIView alloc] initWithFrame:CGRectMake(i * (itemWidth + 0.5), 0, itemWidth + 0.5, itemHeight)];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];

        label.numberOfLines = 1;
        label.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        label.textColor = RCDYCOLOR(0x000000, 0xffffff);
        label.textAlignment = NSTextAlignmentCenter;
        label.text = menuItem.name;

        CGSize labelsize =
            [RCKitUtility getTextDrawingSize:menuItem.name
                                              font:[[RCKitConfig defaultConfig].font fontOfFourthLevel]
                                   constrainedSize:CGSizeMake(itemWidth, 2000)];

        if (menuItem.type == RC_PUBLIC_SERVICE_MENU_ITEM_GROUP) {
            UIImageView *icon =
                [[UIImageView alloc] initWithImage:RCResourceImage(@"public_serive_menu_icon")];
            CGSize iconSize = CGSizeMake(7, 7);
            CGRect iconFrame = CGRectZero;
            iconFrame.origin.x = (itemWidth - labelsize.width - iconSize.width - RC_PUBLIC_SERVICE_MENU_ICON_GAP) / 2;
            iconFrame.origin.y = (itemHeight - iconSize.height) / 2;
            iconFrame.size = iconSize;
            icon.frame = iconFrame;

            CGRect lableFrame = CGRectZero;
            lableFrame.origin.x = iconFrame.origin.x + iconFrame.size.width + RC_PUBLIC_SERVICE_MENU_ICON_GAP;
            lableFrame.origin.y = (itemHeight - labelsize.height) / 2;
            lableFrame.size = labelsize;
            label.frame = lableFrame;
            [container addSubview:icon];
            [container addSubview:label];
        } else {
            CGRect lableFrame = CGRectZero;
            lableFrame.origin.x = (itemWidth - labelsize.width) / 2;
            lableFrame.origin.y = (itemHeight - labelsize.height) / 2;
            lableFrame.size = labelsize;
            label.frame = lableFrame;
            [container addSubview:label];
        }

        if (i != count - 1) {
            UIView *line = [self newLine];
            line.frame = CGRectMake(itemWidth, 0, 0.5, itemHeight);
            [container addSubview:line];
        }
        UIGestureRecognizer *tapRecognizer =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onMenuGroupPushed:)];
        [container addGestureRecognizer:tapRecognizer];

        [self addSubview:container];
        container.tag = i;
    }
}

- (void)onMenuGroupPushed:(UITapGestureRecognizer *)recognizer {
    UIView *touchedView = recognizer.view;
    int tag = (int)touchedView.tag;
    RCPublicServiceMenuItem *item = self.publicServiceMenu.menuItems[tag];

    CGRect frame = [self.publicServicePopupMenu.superview convertRect:touchedView.frame fromView:touchedView.superview];

    if (item.type != RC_PUBLIC_SERVICE_MENU_ITEM_GROUP) {
        [self onPublicServiceMenuItemSelected:item];
        [self.publicServicePopupMenu resignFirstResponder];
    } else {
        [self.publicServicePopupMenu
            displayMenuItems:item.subMenuItems
                     atPoint:CGPointMake(frame.origin.x + RC_PUBLIC_SERVICE_SUBMENU_PADDING, frame.origin.y)
                   withWidth:frame.size.width - RC_PUBLIC_SERVICE_SUBMENU_PADDING * 2];
    }
}

- (void)onPublicServiceMenuItemSelected:(RCPublicServiceMenuItem *)selectedMenuItem {
    if ([self.delegate respondsToSelector:@selector(onPublicServiceMenuItemSelected:)]) {
        [self.delegate onPublicServiceMenuItemSelected:selectedMenuItem];
    }
}

- (UIView *)newLine {
    UIView *line = [UIView new];
    line.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xe3e5e6) darkColor:HEXCOLOR(0x2f2f2f)];
    return line;
}

- (RCPublicServicePopupMenuView *)publicServicePopupMenu {
    if (!_publicServicePopupMenu) {
        _publicServicePopupMenu = [[RCPublicServicePopupMenuView alloc] initWithFrame:CGRectZero];
        _publicServicePopupMenu.delegate = self;
    }
    return _publicServicePopupMenu;
}
@end
