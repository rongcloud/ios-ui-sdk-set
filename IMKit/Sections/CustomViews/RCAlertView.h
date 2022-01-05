//
//  RCAlertView.h
//  RongIMKit
//
//  Created by RongCloud on 2020/5/25.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCAlertView : UIView

/*!
 *  \~chinese
 显示 AlertController
 
 @param title title
 @param message  message
 @param cancelTitle 取消 title
 
 @discussion 默认显示在 keyWindow rootViewController 上
 
 *  \~english
 Show AlertController.

 @param title Title.
 @param message Message.
 @param cancelTitle Cancel title.

 @ discussion Display on keyWindow rootViewController by default.
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
                cancelTitle:(NSString *)cancelTitle;

/*!
 *  \~chinese
 显示 AlertController
 
 @param title title
 @param message  message
 @param cancelTitle 取消 title
 @param controller AlertController 展示的父类控制器，如果 controller 为 nil，则显示在 keyWindow rootViewController 上
 
 *  \~english
 Show AlertController.

 @param title Title.
 @param message Message.
 @param cancelTitle Cancel title.
 @param controller The parent controller shown by AlertController, which is displayed on keyWindow rootViewController if controller is nil,
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
                cancelTitle:(NSString *)cancelTitle
           inViewController:(UIViewController *)controller;

/*!
 *  \~chinese
 显示 AlertController（可设置自动消失时间）
 
 @param title title
 @param message  message
 @param timeInterval 消失时间
 
 @discussion 默认显示在 keyWindow rootViewController 上
 
 *  \~english
 Display AlertController (automatic disappearance time can be set).

 @param title Title.
 @param message Message.
 @param timeInterval Vanishing time.

 @ discussion display on keyWindow rootViewController by default.
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
           hiddenAfterDelay:(NSTimeInterval)timeInterval;

/*!
 *  \~chinese
 显示 AlertController（可设置自动消失时间）
 
 @param title title
 @param message  message
 @param timeInterval 消失时间
 @param controller AlertController 展示的父类控制器，如果 controller 为 nil，则显示在 keyWindow rootViewController 上
 
 *  \~english
 Display AlertController (automatic disappearance time can be set).

 @param title Title.
 @param message Message.
 @param timeInterval Vanishing time.
 @param controller The parent controller shown by AlertController, which is displayed on keyWindow rootViewController if controller is nil,
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
           hiddenAfterDelay:(NSTimeInterval)timeInterval
           inViewController:(UIViewController *)controller;

/*!
 *  \~chinese
 显示 AlertController（可设置自动消失时间）
 
 @param title title
 @param message  message
 @param timeInterval 消失时间
 @param controller AlertController 展示的父类控制器，如果 controller 为 nil，则显示在 keyWindow rootViewController 上
 @param completion  AlertController 消失回调
 
 *  \~english
 Display AlertController (automatic disappearance time can be set).

 @param title Title.
 @param message Message.
 @param timeInterval Vanishing time.
 @param controller The parent controller shown by AlertController, which is displayed on keyWindow rootViewController if controller is nil,
 @param completion AlertController disappearance callback.
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
           hiddenAfterDelay:(NSTimeInterval)timeInterval
           inViewController:(UIViewController *)controller
          dismissCompletion: (void (^)(void))completion;

/*!
 *  \~chinese
 显示 AlertController
 
 @param actionTitles 操作事件 title 列表
 @param cancelTitle 取消 title
 @param style    ActionSheet or Alert
 @param actionsBlock 操作事件回调，回调参数 index 、alertAction 与 actionTitles 顺序一致
 @param controller AlertController 展示的父类控制器，如果 controller 为 nil，则显示在 keyWindow rootViewController 上
 
 *  \~english
 Show AlertController.

 @param actionTitles Action event title list.
 @param cancelTitle Cancel title.
 @param style ActionSheet or Alert.
 @param actionsBlock Callback for operation event. The callback parameters index, alertAction and actionTitles are in the same order.
 @param controller The parent controller shown by AlertController, which is displayed on keyWindow rootViewController if controller is nil,
 */
+ (void)showAlertController:(NSArray *)actionTitles
                cancelTitle:(NSString *)cancelTitle
             preferredStyle:(UIAlertControllerStyle)style
               actionsBlock:(void (^)(int index, UIAlertAction *alertAction))actionsBlock
           inViewController:(UIViewController *)controller;

/*!
 *  \~chinese
 显示 AlertController
 
 @param title title
 @param message  message
 @param actionTitles 操作事件 title 列表
 @param cancelTitle 取消 title
 @param confirmTitle 确认 title
 @param style    ActionSheet or Alert
 @param actionsBlock 操作事件回调，回调参数 index 、alertAction 与 actionTitles 顺序一致
 @param cancelBlock 取消按钮点击回调
 @param confirmBlock  确认按钮点击回调
 @param controller AlertController 展示的父类控制器，如果 controller 为 nil，则显示在 keyWindow rootViewController 上
 
 *  \~english
 Show AlertController.

 @param title Title.
 @param message Message.
 @param actionTitles Action event title list.
 @param cancelTitle Cancel title.
 @param confirmTitle Confirm title.
 @param style ActionSheet or Alert.
 @param actionsBlock Callback for operation event. The callback parameters index, alertAction and actionTitles are in the same order.
 @param cancelBlock Click the cancel button to call back.
 @param confirmBlock Click the confirm button to call back.
 @param controller The parent controller shown by AlertController, which is displayed on keyWindow rootViewController if controller is nil,
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
               actionTitles:(NSArray *)actionTitles
                cancelTitle:(NSString *)cancelTitle
               confirmTitle:(NSString *)confirmTitle
             preferredStyle:(UIAlertControllerStyle)style
               actionsBlock:(void (^)(int index, UIAlertAction *alertAction))actionsBlock
                cancelBlock:(void (^)(void))cancelBlock
               confirmBlock:(void (^)(void))confirmBlock
           inViewController:(UIViewController *)controller;
@end
