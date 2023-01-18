//
//  RCButton.m
//  RongExtensionKit
//
//  Created by 张改红 on 2019/11/28.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCButton.h"
#import "RCExtensionService.h"
#import "UIImage+RCDynamicImage.h"
#import "RCKitConfig.h"
@implementation RCButton
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self fitDarkMode];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self fitDarkMode];
}

- (void)fitDarkMode {
    if (!RCKitConfigCenter.ui.enableDarkMode) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        [self rc_setDyImageForState:(UIControlStateNormal)];
        [self rc_setDyImageForState:(UIControlStateSelected)];
        [self rc_setDyImageForState:(UIControlStateHighlighted)];
        [self rc_setDyBackgroundImageForState:(UIControlStateNormal)];
        [self rc_setDyBackgroundImageForState:(UIControlStateSelected)];
        [self rc_setDyBackgroundImageForState:(UIControlStateHighlighted)];
    }
}

- (void)rc_setDyBackgroundImageForState:(UIControlState)state {
    UIImage *oldImage = [self backgroundImageForState:state];
    if (oldImage && [oldImage rc_needReloadImage]) {
        UIImage *newImage = [UIImage rc_imageWithLocalPath:oldImage.rc_imageLocalPath];
        if (newImage) {
            [self setBackgroundImage:newImage forState:state];
        }
    }
}

- (void)rc_setDyImageForState:(UIControlState)state {
    UIImage *oldImage = [self imageForState:state];
    if (oldImage && [oldImage rc_needReloadImage]) {
        UIImage *newImage = [UIImage rc_imageWithLocalPath:oldImage.rc_imageLocalPath];
        if (newImage) {
            [self setImage:newImage forState:state];
        }
    }
}

@end
