//
//  RCPluginBoardView.h
//  RongExtensionKit
//
//  Created by Liv on 15/3/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RCPluginBoardViewDelegate;

/*!
 *  \~chinese
 输入扩展功能板的View
 
 *  \~english
 Enter the View of the extended function board. 
 */
@interface RCPluginBoardView : UIView

/*!
 *  \~chinese
 当前所有的扩展项
 
 *  \~english
 All current extensions.
 */
@property (nonatomic, strong) NSMutableArray *allItems;

/*!
 *  \~chinese
 展示所有的功能按钮
 
 *  \~english
 Show all the function buttons.
 */
@property (nonatomic, strong) UICollectionView *contentView;

/*!
 *  \~chinese
 扩展view ，此视图会覆盖加号区域其他视图，默认隐藏
 
 *  \~english
 Extended view, which overrides other views in the plus area and is hidden by default.
 */
@property (nonatomic, strong) UIView *extensionView;

/*!
 *  \~chinese
 扩展功能板的点击回调
 
 *  \~english
 Callback for clicking extended function board.
 */
@property (nonatomic, weak) id<RCPluginBoardViewDelegate> pluginBoardDelegate;

/*!
 *  \~chinese
 向扩展功能板中插入扩展项

 @param normalImage 扩展项的展示图片
 @param highlightedImage 扩展项的触摸高亮图片
 @param title 扩展项的展示标题
 @param index 需要添加到的索引值
 @param tag   扩展项的唯一标示符

 @discussion 您以在RCConversationViewController的viewdidload后，添加自定义的扩展项。
 SDK默认的扩展项的唯一标示符为1XXX，我们建议您在自定义扩展功能时不要选用1XXX，以免与SDK预留的扩展项唯一标示符重复。
 
 *  \~english
 Insert an extension into the extension board.

 @param normalImage Display image of the extension.
 @param highlightedImage Touch highlight image of the extension.
 @param title Display title of the extension.
 @param index The index value to be added to.
 @param tag Unique identifier of the extension.

 @ discussion You can add custom extensions after the viewdidload of RCConversationViewController.
  The only identifier for the default extension of SDK is 1XXX. We recommend that you do not choose 1XXX when customizing the extension function, so as not to repeat the unique identifier reserved by SDK.
 */
- (void)insertItem:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title atIndex:(NSInteger)index tag:(NSInteger)tag;

/*!
 *  \~chinese
 添加扩展项到扩展功能板，并在显示为最后一项

 @param normalImage 扩展项的展示图片
 @param highlightedImage 扩展项的触摸高亮图片
 @param title 扩展项的展示标题
 @param tag   扩展项的唯一标示符

 @discussion 您以在RCConversationViewController的viewdidload后，添加自定义的扩展项。
 SDK默认的扩展项的唯一标示符为1XXX，我们建议您在自定义扩展功能时不要选用1XXX，以免与SDK预留的扩展项唯一标示符重复。
 
 *  \~english
 Add an extension to the extension board and display it as the last item.

 @param normalImage Display image of the extension.
 @param highlightedImage Touch highlight image of the extension.
 @param title Display title of the extension.
 @param tag Unique identifier of the extension.

 @ discussion You can add custom extensions after the viewdidload of RCConversationViewController.
  The only identifier for the default extension of SDK is 1XXX. We recommend that you do not choose 1XXX when customizing the extension function, so as not to repeat the unique identifier reserved by SDK.
 */
- (void)insertItem:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title tag:(NSInteger)tag;

/*!
 *  \~chinese
 更新指定扩展项

 @param index 扩展项的索引值
 @param normalImage 扩展项的展示图片
 @param highlightedImage 扩展项的触摸高亮图片
 @param title 扩展项的展示标题
 
 *  \~english
 Update the specified extension.

 @param index The index value of the extension.
 @param normalImage Display image of the extension.
 @param highlightedImage Touch highlight image of the extension.
 @param title Display title of the extension.
 */
- (void)updateItemAtIndex:(NSInteger)index normalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title;

/*!
 *  \~chinese
 更新指定扩展项

 @param tag   扩展项的唯一标示符
 @param normalImage 扩展项的展示图片
 @param highlightedImage 扩展项的触摸高亮图片
 @param title 扩展项的展示标题
 
 *  \~english
 Update the specified extension.

 @param tag Unique identifier of the extension.
 @param normalImage Display image of the extension.
 @param highlightedImage Touch highlight image of the extension.
 @param title Display title of the extension.
 */
- (void)updateItemWithTag:(NSInteger)tag normalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title;

/*!
 *  \~chinese
 删除扩展功能板中的指定扩展项

 @param index 指定扩展项的索引值
 
 *  \~english
 Delete the specified extension in the extension function board.

 @param index Specify the index value of the extension.
 */
- (void)removeItemAtIndex:(NSInteger)index;

/*!
 *  \~chinese
 删除扩展功能板中的指定扩展项

 @param tag 指定扩展项的唯一标示符
 
 *  \~english
 Delete the specified extension in the extension function board.

 @param tag Specify a unique identifier for the extension.
 */
- (void)removeItemWithTag:(NSInteger)tag;

/*!
 *  \~chinese
 删除扩展功能板中的所有扩展项
 
 *  \~english
 Delete all extensions in the extension function board.
 */
- (void)removeAllItems;
@end

/*!
 *  \~chinese
 扩展功能板的点击回调
 
 *  \~english
 Callback for clicking extended function board.
 */
@protocol RCPluginBoardViewDelegate <NSObject>

/*!
 *  \~chinese
 点击扩展功能板中的扩展项的回调

 @param pluginBoardView 当前扩展功能板
 @param tag             点击的扩展项的唯一标示符
 
 *  \~english
 Callback for clicking extension in the extension function board.

 @param pluginBoardView Current extended function board.
 @param tag Unique identifier of the extension clicked
 */
- (void)pluginBoardView:(RCPluginBoardView *)pluginBoardView clickedItemWithTag:(NSInteger)tag;

@end
