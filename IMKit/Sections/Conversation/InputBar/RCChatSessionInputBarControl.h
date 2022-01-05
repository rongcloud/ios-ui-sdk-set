//
//  RCChatSessionInputBarControl.h
//  RongExtensionKit
//
//  Created by xugang on 15/2/12.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCEmojiBoardView.h"
#import "RCPluginBoardView.h"
#import "RCTextView.h"
#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>
#import "RCInputContainerView.h"
#import "RCMenuContainerView.h"
#define RC_ChatSessionInputBar_Height 49.5f
/*!
 *  \~chinese
 输入栏扩展输入的唯一标示
 
 *  \~english
 Unique indication of the input extended by the input field
 */
#define INPUT_MENTIONED_SELECT_TAG 1000
#define PLUGIN_BOARD_ITEM_ALBUM_TAG 1001
#define PLUGIN_BOARD_ITEM_CAMERA_TAG 1002
#define PLUGIN_BOARD_ITEM_LOCATION_TAG 1003
#define PLUGIN_BOARD_ITEM_DESTRUCT_TAG 1004
#define PLUGIN_BOARD_ITEM_FILE_TAG 1006
#define PLUGIN_BOARD_ITEM_VOIP_TAG 1101
#define PLUGIN_BOARD_ITEM_VIDEO_VOIP_TAG 1102
#define PLUGIN_BOARD_ITEM_EVA_TAG 1103
#define PLUGIN_BOARD_ITEM_RED_PACKET_TAG 1104
#define PLUGIN_BOARD_ITEM_VOICE_INPUT_TAG 1105
#define PLUGIN_BOARD_ITEM_PTT_TAG 1106
#define PLUGIN_BOARD_ITEM_CARD_TAG 1107
#define PLUGIN_BOARD_ITEM_REMOTE_CONTROL_TAG 1108
#define PLUGIN_BOARD_ITEM_TRANSFER_TAG 1109

/*!
 *  \~chinese
 输入工具栏的点击监听器
 
 *  \~english
 Click listener of input toolbar
 */
@protocol RCChatSessionInputBarControlDelegate;

/*!
 *  \~chinese
 输入工具栏的数据源
 
 *  \~english
 Data source of input toolbar
 */
@protocol RCChatSessionInputBarControlDataSource;

/**
 *  \~chinese
 图片编辑的协议
 
 *  \~english
 Protocol for image editing
 */
@protocol RCPictureEditDelegate;

/*!
 *  \~chinese
 输入工具栏
 
 *  \~english
 Input Toolbar
 */
@interface RCChatSessionInputBarControl : UIView

#pragma mark - Conversation

/*!
 *  \~chinese
 当前的会话类型
 
 *  \~english
 Current conversation type
 */
@property (nonatomic, assign) RCConversationType conversationType;

/*!
 *  \~chinese
 当前的会话ID
 
 *  \~english
 Current conversation ID
 */
@property (nonatomic, strong) NSString *targetId;

#pragma mark - RCChatSessionInputBarControlDelegate
/*!
 *  \~chinese
 输入工具栏的点击回调监听
 
 *  \~english
 Click callback listening of input toolbar
 */
@property (weak, nonatomic) id<RCChatSessionInputBarControlDelegate> delegate;

/*!
 *  \~chinese
 输入工具栏获取用户信息的回调
 
 *  \~english
 Callback for getting user information from input toolbar
 */
@property (weak, nonatomic) id<RCChatSessionInputBarControlDataSource> dataSource;

/**
 *  \~chinese
 点击编辑按钮会调用该代理的onClickEditPicture方法
 
 *  \~english
 Clicking the edit button calls the agent's onClickEditimage method
 */
@property (weak, nonatomic) id<RCPictureEditDelegate> photoEditorDelegate;

#pragma mark - View
/*!
 *  \~chinese
 所处的会话页面View
 
 *  \~english
 Conversation page View
 */
@property (weak, nonatomic, readonly) UIView *containerView;

/*!
 *  \~chinese
 容器View
 
 *  \~english
 Container View
 */
@property (strong, nonatomic) RCInputContainerView *inputContainerView;

/*!
 *  \~chinese
 公众服务菜单的容器View
 
 *  \~english
 Container View of the public service menu
 */
@property (strong, nonatomic) RCMenuContainerView *menuContainerView;

/*!
 *  \~chinese
 公众服务菜单切换的按钮
 
 *  \~english
 Public service menu toggle button
 */
@property (strong, nonatomic) RCButton *pubSwitchButton;

/*!
 *  \~chinese
 客服机器人转人工切换的按钮
 
 *  \~english
 Switch button from customer service robot to manual switch
 */
@property (strong, nonatomic) RCButton *robotSwitchButton;

/*!
 *  \~chinese
 语音与文本输入切换的按钮
 
 *  \~english
 Button to switch between voice and text input
 */
@property (strong, nonatomic) RCButton *switchButton;

/*!
 *  \~chinese
 录制语音消息的按钮
 
 *  \~english
 Buttons to record voice messages
 */
@property (strong, nonatomic) RCButton *recordButton;

/*!
 *  \~chinese
 文本输入框
 
 *  \~english
 Text input box
 */
@property (strong, nonatomic) RCTextView *inputTextView;

/*!
 *  \~chinese
 表情的按钮
 
 *  \~english
 A button with an expression
 */
@property (strong, nonatomic) RCButton *emojiButton;

/*!
 *  \~chinese
 扩展输入的按钮
 
 *  \~english
 extend the input button
 */
@property (strong, nonatomic) RCButton *additionalButton;

/*!
 *  \~chinese
 公众服务账号菜单
 
 *  \~english
 Public service account menu
 */
@property (strong, nonatomic) RCPublicServiceMenu *publicServiceMenu;

/*!
 *  \~chinese
 输入扩展功能板View
 
 *  \~english
 Enter the extended function board View
 */
@property (nonatomic, strong) RCPluginBoardView *pluginBoardView;

/*!
 *  \~chinese
 表情View
 
 *  \~english
 Facial expression View
 */
@property (nonatomic, strong) RCEmojiBoardView *emojiBoardView;

/*!
 *  \~chinese
 输入工具栏底部的 SafeArea view；当前设备没有 SafeArea，则该 view 为 nil
 
 *  \~english
 SafeArea view at the bottom of the input toolbar. If the current device does not have a SafeArea, the view is nil
 */
@property (nonatomic, strong, readonly) UIView *safeAreaView;

/*!
 *  \~chinese
 View即将显示的回调
 
 *  \~english
 Callback for View to display
 */
- (void)containerViewWillAppear;

/*!
 *  \~chinese
 View已经显示的回调
 
 *  \~english
 Callback for displayed  View
 */
- (void)containerViewDidAppear;

/*!
 *  \~chinese
 View即将隐藏的回调
 
 *  \~english
 Callback for View to hide
 */
- (void)containerViewWillDisappear;

#pragma mark - Setting
/*!
 *  \~chinese
 当前的输入状态
 
 *  \~english
 Current input status
 */
@property (nonatomic,assign) KBottomBarStatus currentBottomBarStatus;

/**
 *  \~chinese
 输入框最大输入行数

 @discussion 该变量设置范围为: 1~6, 超过该范围会自动调整为边界值
 
 *  \~english
 Maximum number of input lines in the input box.

 @ discussion This variable is set in the range of: 1 to 6, beyond which it will automatically be adjusted to the boundary value.
 */
@property (nonatomic, assign) NSInteger maxInputLines;

/*!
 *  \~chinese
 草稿
 
 *  \~english
 Draft
 */
@property (nonatomic, strong) NSString *draft;

/*!
 *  \~chinese
 @提醒信息
 
 *  \~english
 @ reminder message
 */
@property (nonatomic, strong, readonly) RCMentionedInfo *mentionedInfo;

/*!
 *  \~chinese
 是否允许@功能
 
 *  \~english
 Whether the @ function is allowed
 */
@property (nonatomic, assign) BOOL isMentionedEnabled;

#pragma mark - init

/*!
 *  \~chinese
 初始化输入工具栏

 @param frame            显示的Frame
 @param containerView    所处的会话页面View
 @param controlType      菜单类型
 @param controlStyle     显示布局
 @param defaultInputType 默认的输入模式

 @return 输入工具栏对象
 
 *  \~english
 Initialize the input toolbar.

 @param frame Displayed Frame.
 @param containerView conversation page View.
 @param controlType Menu type
 @param controlStyle Display layout.
 @param defaultInputType Default input mode.

 @ return input Toolbar object.
 */
- (instancetype)initWithFrame:(CGRect)frame
            withContainerView:(UIView *)containerView
                  controlType:(RCChatSessionInputBarControlType)controlType
                 controlStyle:(RCChatSessionInputBarControlStyle)controlStyle
             defaultInputType:(RCChatSessionInputBarInputType)defaultInputType;

/*!
 *  \~chinese
 设置输入工具栏的样式

 @param type  菜单类型
 @param style 显示布局

 @discussion 您可以在会话页面RCConversationViewController的viewDidLoad之后设置，改变输入工具栏的样式。
 
 *  \~english
 Set the style of the input toolbar.

 @param type Menu type
 @param style Display layout.

 @ discussion You can change the style of the input toolbar by setting it after the viewDidLoad of the conversation page RCConversationViewController.
 */
- (void)setInputBarType:(RCChatSessionInputBarControlType)type style:(RCChatSessionInputBarControlStyle)style;

/*!
 *  \~chinese
 销毁公众账号弹出的菜单
 
 *  \~english
 Destroy the pop-up menu of the public account.
 */
- (void)dismissPublicServiceMenuPopupView;

/*!
 *  \~chinese
 撤销录音
 
 *  \~english
 Undo the recording
 */
- (void)cancelVoiceRecord;

/*!
 *  \~chinese
 结束录音
 
 *  \~english
 End recording
 */
- (void)endVoiceRecord;

/*!
 *  \~chinese
 设置输入框的输入状态

 @param status          输入框状态
 @param animated        是否使用动画效果

 @discussion 如果需要设置，请在输入框执行containerViewWillAppear之后（即会话页面viewWillAppear之后）。
 
 *  \~english
 Set the input status of the input box.

 @param status Input box status.
 @param animated Whether to use animation effects.

 @ discussion If you shall set it, it is performed after the input box executes containerViewWillAppear (that is, after the conversation page viewWillAppear).
 */
- (void)updateStatus:(KBottomBarStatus)status animated:(BOOL)animated;

/*!
 *  \~chinese
 重置到默认状态
 
 *  \~english
 Reset to the default state
 */
- (void)resetToDefaultStatus;

/*!
 *  \~chinese
 内容区域大小发生变化。

 @discussion 当本view所在的view frame发生变化，需要重新计算本view的frame时，调用此方法
 
 *  \~english
 The size of the content area has changed

  @ discussion call this method when the view frame of this view changes and the frame of this view shall be recalculated
 */
- (void)containerViewSizeChanged;

/**
 *  \~chinese
 内容区域大小发生变化。

 @discussion 当本view所在的view frame发生变化，需要重新计算本view的frame时，调用此方法，无动画
 
 *  \~english
 The size of the content area has changed.

  @ discussion This method is called when the view frame of this view changes and the frame of this view shall be recalculated. There is no animation
 */
- (void)containerViewSizeChangedNoAnnimation;

/*!
 *  \~chinese
 设置默认的输入框类型

 @param defaultInputType  默认输入框类型
 
 *  \~english
 Set the default input box type.

 @param defaultInputType Default input box type
 */
- (void)setDefaultInputType:(RCChatSessionInputBarInputType)defaultInputType;

/*!
 *  \~chinese
 添加被@的用户

 @param userInfo    被@的用户信息
 
 *  \~english
 Add @ users.

 @param userInfo User information that has been @.
 */
- (void)addMentionedUser:(RCUserInfo *)userInfo;

/*!
 *  \~chinese
 打开系统相册，选择图片

 @discussion 选择结果通过delegate返回
 
 *  \~english
 Open the system image album and select a image.

 @ discussion selection result is returned through delegate
 */
- (void)openSystemAlbum;

/*!
 *  \~chinese
 打开系统相机，拍摄图片

 @discussion 拍摄结果通过delegate返回
 
 *  \~english
 Turn on the system camera and take images.

 @ discussion shooting result is returned via delegate
 */
- (void)openSystemCamera;

/*!
 *  \~chinese
 打开地图picker，选择位置

 @discussion 选择结果通过delegate返回
 
 *  \~english
 Open the map picker and select a location.

 @ discussion selection result is returned through delegate
 */
- (void)openLocationPicker;

/*!
 *  \~chinese
 打开文件选择器，选择文件

 @discussion 选择结果通过delegate返回
 
 *  \~english
 Open the file selector and select the file.

 @ discussion selection result is returned through delegate
 */
- (void)openFileSelector;

/*!
 *  \~chinese
 常用语列表设置

 @param commonPhrasesList 您需要展示的常用语列表

 @discussion 常用语条数需大于 0 条，每条内容最多可配置 30 个字，且只支持单聊。
 如果二次设置常用语列表，需要设置后主动调用 - (void)updateStatus:(KBottomBarStatus)status animated:(BOOL)animated 方法
 
 *  \~english
 Idiom list setting.

 @param commonPhrasesList A list of common phrases that you shall show.

 @ discussion The number of commonly used entries should be greater than 0, each item can be configured with a maximum of 30 characters, and only single chat is supported.
  If you set the idiom list for the second time, you shall call the-(void) updateStatus: (KBottomBarStatus) status animated: (BOOL) animated method actively after setting it
 */
- (BOOL)setCommonPhrasesList:(NSArray<NSString *> *)commonPhrasesList;

/*!
 *  \~chinese
 按照 tag 触发扩展中某个 pluginItem 的事件
 
 @param functionTag 某个 pluginItem 的 tag
 
 *  \~english
 Trigger the event of a pluginItem in the extension according to tag.

 @param functionTag Tag of some pluginItem.
*/
- (void)openDynamicFunction:(NSInteger)functionTag;

/*!
 *  \~chineses
 是否处于阅后即焚模式
 
 *  \~english
 Whether it is in the mode of burning immediately after reading
*/
@property (nonatomic, assign) BOOL destructMessageMode;

@end

/*!
 *  \~chineses
 输入工具栏的点击监听器
 
 *  \~english
 Click listener of input toolbar
 */
@protocol RCChatSessionInputBarControlDelegate <NSObject>

/*!
 *  \~chineses
 显示ViewController

 @param viewController 需要显示的ViewController
 @param functionTag    功能标识
 
 *  \~english
 Show ViewController.

 @param viewController ViewController to be displayed.
 @param functionTag Functional identification.
 */
- (void)presentViewController:(UIViewController *)viewController functionTag:(NSInteger)functionTag;

@optional

/*!
 *  \~chinese
 输入工具栏尺寸（高度）发生变化的回调

 @param chatInputBar 输入工具栏
 @param frame        输入工具栏最终需要显示的Frame
 
 *  \~english
 Callback for a change in the size (height) of the input toolbar.

 @param chatInputBar Input Toolbar.
 @param frame Enter the Frame that the toolbar finally shall display
 */
- (void)chatInputBar:(RCChatSessionInputBarControl *)chatInputBar shouldChangeFrame:(CGRect)frame;

/*!
 *  \~chinese
 点击键盘Return按钮的回调

 @param inputTextView 文本输入框
 
 *  \~english
 Callback for clicking the keyboard Return button.

 @param inputTextView Text input box.
 */
- (void)inputTextViewDidTouchSendKey:(UITextView *)inputTextView;

/*!
 *  \~chinese
 点击客服机器人切换按钮的回调
 
 *  \~english
 Callback for clicking the customer service robot switch button
 */
- (void)robotSwitchButtonDidTouch;

/*!
 *  \~chinese
 输入框中内容发生变化的回调

 @param inputTextView 文本输入框
 @param range         当前操作的范围
 @param text          插入的文本
 
 *  \~english
 Callback for a change in the content of the input box.

 @param inputTextView Text input box.
 @param range The scope of the current operation.
 @param text Inserted text.
 */
- (void)inputTextView:(UITextView *)inputTextView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text;

/*!
 *  \~chinese
 公众服务菜单的点击回调

 @param selectedMenuItem 点击的公众服务菜单项
 
 *  \~english
 Callback for clicking the public service menu.

 @param selectedMenuItem Click on the public service menu item
 */
- (void)onPublicServiceMenuItemSelected:(RCPublicServiceMenuItem *)selectedMenuItem;

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

/*!
 *  \~chinese
 点击表情的回调

 @param emojiView    表情输入的View
 @param touchedEmoji 点击的表情对应的字符串编码
 
 *  \~english
 Callback for clicking the facial expression.

 @param emojiView View of facial expression input.
 @param touchedEmoji The string encoding corresponding to the clicked expression.
 */
- (void)emojiView:(RCEmojiBoardView *)emojiView didTouchedEmoji:(NSString *)touchedEmoji;

/*!
 *  \~chinese
 点击发送按钮的回调

 @param emojiView  表情输入的View
 @param sendButton 发送按钮
 
 *  \~english
 Callback for clicking the send button.

 @param emojiView View of facial expression input.
 @param sendButton Send button.
 */
- (void)emojiView:(RCEmojiBoardView *)emojiView didTouchSendButton:(UIButton *)sendButton;

/*!
 *  \~chinese
 点击常用语的回调

 @param commonPhrases  常用语
 
 *  \~english
 Callback for clicking common phrases.

 @param commonPhrases Common language.
 */
- (void)commonPhrasesViewDidTouch:(NSString *)commonPhrases;

/*!
 *  \~chinese
 即将开始录制语音消息
 返回 YES：继续录音
 返回 NO：停止录音（音频配占用时，可以处理弹窗等）
 
 *  \~english
 Recording of voice messages is about to begin.
 Return to YES: to continue recording.
 Return to NO: to stop recording (when audio is occupied, you can handle pop-up windows, etc.).
 */
- (BOOL)recordWillBegin;

/*!
 *  \~chinese
 开始录制语音消息
 
 *  \~english
 Start recording voice messages.
 */
- (void)recordDidBegin;

/*!
 *  \~chinese
 取消录制语音消息
 
 *  \~english
 Cancel recording of voice message.
 */
- (void)recordDidCancel;

/*!
 *  \~chinese
 结束录制语音消息
 
 *  \~english
 End recording voice message
 */
- (void)recordDidEnd:(NSData *)recordData duration:(long)duration error:(NSError *)error;

/*!
 *  \~chinese
  相机拍照图片

 @param image   相机拍摄，选择发送的图片
 
 *  \~english
 The camera takes images.

 @param image Take images with the camera and select the images to be sent.
 */
- (void)imageDidCapture:(UIImage *)image;

/**
 *  \~chinese
 相机录制小视频完成后调用

 @param url 小视频url
 @param image 小视频首帧图片
 @param duration 小视频时长 单位秒
 
 *  \~english
 Called after the camera has finished recording the short video.

 @param url small video url.
 @param image The first image of the short video.
 @param duration small video duration unit second.
 */
- (void)sightDidFinishRecord:(NSString *)url thumbnail:(UIImage *)image duration:(NSUInteger)duration;

/*!
 *  \~chinese
 地理位置选择完成之后的回调
 @param location       位置的二维坐标
 @param locationName   位置的名称
 @param mapScreenShot  位置在地图中的缩略图
 
 *  \~english
 Callback after completion of geographic location selection.
 @param location Two-dimensional coordinates of the location.
 @param locationName The name of the location.
 @param mapScreenShot A thumbnail of a location in a map.
 */
- (void)locationDidSelect:(CLLocationCoordinate2D)location
             locationName:(NSString *)locationName
            mapScreenShot:(UIImage *)mapScreenShot;

/*!
 *  \~chinese
 相册选择图片列表,返回图片的 NSData

 @param selectedImages   选中的图片
 @param full             用户是否要求原图
 
 *  \~english
 Select a list of images in the album and return the NSData of the image.

 @param selectedImages Selected image.
 @param full Does the user require the original image?
 */
- (void)imageDataDidSelect:(NSArray *)selectedImages fullImageRequired:(BOOL)full;

/*!
 *  \~chinese
 选择文件列表

 @param filePathList   被选中的文件路径list
 
 *  \~english
 Select File list.

 @param filePathList Selected file path list.
 */
- (void)fileDidSelect:(NSArray *)filePathList;

/**
 *  \~chinese
 会话页面发送文件消息，在文件选择页面选择某个文件时调用该方法方法

 @param path 文件路径
 @return 返回 YES 允许文件被选中，否则不允许选中
 @discussion 该方法默认返回YES，这个方法可以控制某些文件是否可以被选中。
 
 *  \~english
 The conversation page sends a file message and this method is called when the file selection page selects a file.

 @param path File path.
 @ return Return YES to allow the file to be selected, otherwise it is not allowed to be selected.
 @ discussion This method returns YES by default and this method controls whether certain files can be selected.
 */
- (BOOL)canBeSelectedAtFilePath:(NSString *)path;

/*!
 *  \~chinese
 输入工具栏状态变化时的回调（暂未实现）

 @param bottomBarStatus 当前状态
 
 *  \~english
 Callback for the status change of the input toolbar (not implemented yet).

 @param bottomBarStatus Current state.
 */
- (void)chatSessionInputBarStatusChanged:(KBottomBarStatus)bottomBarStatus;

@end

@protocol RCChatSessionInputBarControlDataSource <NSObject>

/*!
 *  \~chinese
 获取待选择的用户ID列表

 @param completion  获取完成的回调
 @param functionTag 功能标识
 
 *  \~english
 Get the ID list of users to be selected.

 @param completion Callback for getting completion
 @param functionTag Functional identification.
 */
- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion functionTag:(NSInteger)functionTag;

/*!
 *  \~chinese
 获取待选择的UserId的用户信息

 @param userId           用户ID
 @return 用户信息
 
 *  \~english
 Get the user information of the UserId to be selected.

 @param userId User ID.
 @ return user Information.
 */
- (RCUserInfo *)getSelectingUserInfo:(NSString *)userId;

@end

/**
 *  \~chinese
 图片编辑的代理
 
 *  \~english
 An agent for image editing.
 */
@protocol RCPictureEditDelegate <NSObject>

/**
 *  \~chinese
 点击编辑按钮时的回调，可以通过rootCtrl控制器进行页面的跳转，在源码中默认跳转到RCPictureEditViewController

 @param rootCtrl 图片编辑根控制器，用于页面跳转
 @param originalImage 原图片
 @param editCompletion 编辑过的图片通过Block回传给SDK
 
 *  \~english
 Callback when you click the edit button, you can jump to the page through the rootCtrl controller. By default, you can jump to RCimageEditViewController in the source code.

 @param rootCtrl image editing root controller for page jump.
 @param originalImage Original image.
 @param editCompletion The edited image is sent back to SDK via Block
 */
- (void)onClickEditPicture:(UIViewController *)rootCtrl
             originalImage:(UIImage *)originalImage
            editCompletion:(void (^)(UIImage *editedImage))editCompletion;

@end
