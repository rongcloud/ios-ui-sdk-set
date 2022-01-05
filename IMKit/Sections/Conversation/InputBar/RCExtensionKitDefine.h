//
//  RCExtensionKitDefine.h
//  RongIMKit
//
//  Created by RongCloud on 2020/5/26.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#ifndef RCExtensionKitDefine_h
#define RCExtensionKitDefine_h

/*!
 *  \~chinese
 输入工具栏的显示布局
 
 *  \~english
 Enter the display layout of the toolbar 
 */
typedef NS_ENUM(NSInteger, RCChatSessionInputBarControlStyle) {
    /*!
     *  \~chinese
     切换-输入框-扩展
     
     *  \~english
     Toggle-input box-extension
     */
    RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION = 0,
    /*!
     *  \~chinese
     扩展-输入框-切换
     
     *  \~english
     Extend-input box-toggle
     */
    RC_CHAT_INPUT_BAR_STYLE_EXTENTION_CONTAINER_SWITCH = 1,
    /*!
     *  \~chinese
     输入框-切换-扩展
     
     *  \~english
     Input box-switch-extend
     */
    RC_CHAT_INPUT_BAR_STYLE_CONTAINER_SWITCH_EXTENTION = 2,
    /*!
     *  \~chinese
     输入框-扩展-切换
     
     *  \~english
     Input box-extend-toggle
     */
    RC_CHAT_INPUT_BAR_STYLE_CONTAINER_EXTENTION_SWITCH = 3,
    /*!
     *  \~chinese
     切换-输入框
     
     *  \~english
     Toggle-input box
     */
    RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER = 4,
    /*!
     *  \~chinese
     输入框-切换
     
     *  \~english
     Input box-Toggle
     */
    RC_CHAT_INPUT_BAR_STYLE_CONTAINER_SWITCH = 5,
    /*!
     *  \~chinese
     扩展-输入框
     
     *  \~english
     Expansion-input box
     */
    RC_CHAT_INPUT_BAR_STYLE_EXTENTION_CONTAINER = 6,
    /*!
     *  \~chinese
     输入框-扩展
     
     *  \~english
     Input box-extension
     */
    RC_CHAT_INPUT_BAR_STYLE_CONTAINER_EXTENTION = 7,
    /*!
     *  \~chinese
     输入框
     
     *  \~english
     Input box
     */
    RC_CHAT_INPUT_BAR_STYLE_CONTAINER = 8,
};

/*!
 *  \~chinese
 输入工具栏的菜单类型
 
 *  \~english
 Enter the menu type for the toolbar
 */
typedef NS_ENUM(NSInteger, RCChatSessionInputBarControlType) {
    /*!
     *  \~chinese
     默认类型，非公众服务
     
     *  \~english
     Default type, non-public service
     */
    RCChatSessionInputBarControlDefaultType = 0,
    /*!
     *  \~chinese
     公众服务
     
     *  \~english
     Public service
     */
    RCChatSessionInputBarControlPubType = 1,

    /*!
     *  \~chinese
     客服机器人
     
     *  \~english
     Customer service robot
     */
    RCChatSessionInputBarControlCSRobotType = 2,

    /*!
     *  \~chinese
     客服机器人
     
     *  \~english
     Customer service robot
     */
    RCChatSessionInputBarControlNoAvailableType = 3
};

/*!
 *  \~chinese
 输入工具栏的输入模式
 
 *  \~english
 Enter the input mode of the toolbar
 */
typedef NS_ENUM(NSInteger, RCChatSessionInputBarInputType) {
    /*!
     *  \~chinese
     文本输入模式
     
     *  \~english
     Text input mode
     */
    RCChatSessionInputBarInputText = 0,
    /*!
     *  \~chinese
     语音输入模式
     
     *  \~english
     Voice input mode
     */
    RCChatSessionInputBarInputVoice = 1,
    /*!
     *  \~chinese
     扩展输入模式
     
     *  \~english
     Extended input mode.
     */
    RCChatSessionInputBarInputExtention = 2,
    /*!
     *  \~chinese
     阅后即焚输入模式
     
     *  \~english
     Burn-after-reading input mode
     */
    RCChatSessionInputBarInputDestructMode = 3
};

/*!
 *  \~chinese
 输入工具栏的输入模式
 
 *  \~english
 Enter the input mode of the toolbar
 */
typedef NS_ENUM(NSInteger, KBottomBarStatus) {
    /*!
     *  \~chinese
     初始状态
     
     *  \~english
     Initial state
     */
    KBottomBarDefaultStatus = 0,
    /*!
     *  \~chinese
     文本输入状态
     
     *  \~english
     Text input status
     */
    KBottomBarKeyboardStatus,
    /*!
     *  \~chinese
     功能板输入状态
     
     *  \~english
     Function board input status
     */
    KBottomBarPluginStatus,
    /*!
     *  \~chinese
     表情输入状态
     
     *  \~english
     Facial expression input status
     */
    KBottomBarEmojiStatus,
    /*!
     *  \~chinese
     语音消息输入状态
     
     *  \~english
     Voice message input status
     */
    KBottomBarRecordStatus,
    /*!
     *  \~chinese
     常用语输入状态
     
     *  \~english
     Idiom input state
     */
    KBottomBarCommonPhrasesStatus,
    /*!
     *  \~chinese
     阅后即焚输入状态
     
     *  \~english
     Burn-after-reading input status
     */
    KBottomBarDestructStatus,
};

#endif /* RCExtensionKitDefine_h */
