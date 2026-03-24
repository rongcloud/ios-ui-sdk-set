//
//  RCAlertView.m
//  RongIMKit
//
//  Created by 张改红 on 2020/5/25.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCAlertView.h"
#import <UIKit/UIKit.h>
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
@implementation RCAlertView
+ (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    [self showAlertController:title message:message actionTitles:nil cancelTitle:cancelTitle confirmTitle:nil preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:nil inViewController:nil];
}

+ (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle inViewController:(UIViewController *)controller{
    [self showAlertController:title message:message actionTitles:nil cancelTitle:cancelTitle confirmTitle:nil preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:nil inViewController:controller];
}

+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
           hiddenAfterDelay:(NSTimeInterval)timeInterval {
    [self showAlertController:title message:message hiddenAfterDelay:timeInterval inViewController:nil dismissCompletion:nil];
}

+ (void)showAlertController:(NSString *)title message:(NSString *)message hiddenAfterDelay:(NSTimeInterval)timeInterval inViewController:(UIViewController *)controller{
    [self showAlertController:title message:message hiddenAfterDelay:timeInterval inViewController:controller dismissCompletion:nil];
}

+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
           hiddenAfterDelay:(NSTimeInterval)timeInterval
           inViewController:(UIViewController *)controller
          dismissCompletion: (void (^)(void))completion{
    if (!title) {
        title = @"";
    }
    if (!message) {
        message = @"";
    }
    dispatch_main_async_safe(^{
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        if (!controller) {
            UIViewController *rootVC = [RCKitUtility getKeyWindow].rootViewController;
            [rootVC presentViewController:alertController animated:YES completion:nil];
        }else{
            [controller presentViewController:alertController animated:YES completion:nil];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(),
                       ^{
            [alertController dismissViewControllerAnimated:YES completion:completion];
        });
    });
}

+ (void)showAlertController:(NSArray *)actionTitles
                cancelTitle:(NSString *)cancelTitle
             preferredStyle:(UIAlertControllerStyle)style
               actionsBlock:(void (^)(int index, UIAlertAction *alertAction))actionsBlock
           inViewController:(UIViewController *)controller{
    [self showAlertController:nil message:nil actionTitles:actionTitles cancelTitle:cancelTitle confirmTitle:nil preferredStyle:style actionsBlock:actionsBlock cancelBlock:nil confirmBlock:nil inViewController:controller];
}

+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
               actionTitles:(NSArray *)actionTitles
                cancelTitle:(NSString *)cancelTitle
               confirmTitle:(NSString *)confirmTitle
             preferredStyle:(UIAlertControllerStyle)style
               actionsBlock:(void (^)(int index, UIAlertAction *alertAction))actionsBlock
                cancelBlock:(void (^)(void))cancelBlock
               confirmBlock:(void (^)(void))confirmBlock
           inViewController:(UIViewController *)controller {
    if (!title) {
        title = @"";
    }
    if (!message) {
        message = @"";
    }
    dispatch_main_async_safe(^{
        UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:title message:message preferredStyle:style];
        for (NSString *actionTitle in actionTitles) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitle
              style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *_Nonnull action) {
                if (actionsBlock) {
                    actionsBlock((int)[actionTitles indexOfObject:actionTitle], action);
                }
            }];
            [alertController addAction:action];
        }
        if (cancelTitle.length > 0) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:cancelTitle
              style:UIAlertActionStyleCancel
            handler:^(UIAlertAction *_Nonnull action) {
                if (cancelBlock) {
                    cancelBlock();
                }
            }];
            [alertController addAction:action];
        }
        if (confirmTitle.length > 0) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:confirmTitle
              style:UIAlertActionStyleDestructive
            handler:^(UIAlertAction *_Nonnull action) {
                if (confirmBlock) {
                    confirmBlock();
                }
            }];
            [alertController addAction:action];
        }
        if (style == UIAlertControllerStyleActionSheet && [RCKitUtility currentDeviceIsIPad]) {
            UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            popPresenter.sourceView = window;
            popPresenter.sourceRect = CGRectMake(window.frame.size.width / 2, window.frame.size.height / 2, 0, 0);
            popPresenter.permittedArrowDirections = 0;
        }
        if (!controller) {
             UIViewController *rootVC = [RCKitUtility getKeyWindow].rootViewController;
            [rootVC presentViewController:alertController animated:YES completion:nil];
        }else{
            [controller presentViewController:alertController animated:YES completion:nil];
        }
    });
}
@end
