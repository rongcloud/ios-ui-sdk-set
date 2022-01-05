//
//  RCConversationListViewController.h
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCBaseViewController.h"
#import "RCConversationBaseCell.h"
#import "RCConversationModel.h"
#import "RCThemeDefine.h"
#import <UIKit/UIKit.h>

@class RCNetworkIndicatorView;

/*!
 *  \~chinese
 会话列表界面类
 
 *  \~english
 Conversation list interface class 
 */
@interface RCConversationListViewController : RCBaseViewController <UITableViewDataSource, UITableViewDelegate>

#pragma mark - init

/*!
 *  \~chinese
 初始化会话列表

 @param displayConversationTypeArray    列表中需要显示的会话类型数组(需要将RCConversationType转为NSNumber构建Array)
 @param collectionConversationTypeArray
 列表中需要聚合为一条显示的会话类型数组(需要将RCConversationType转为NSNumber构建Array)
 @return                                    会话列表对象

 @discussion
 聚合为一条显示指的是，将指定会话类型的所有会话在会话列表中聚合显示成一条，点击进入会显示该会话类型的所有会话列表。
 
 *  \~english
 Initialize conversation list.

 @param displayConversationTypeArray An array of conversation types to be displayed in the list (you shall convert RCConversationType to NSNumber to build Array).
 @ param collectionConversationTypeArray.
 The list shall be aggregated into a displayed array of conversation types (you shall convert RCConversationType to NSNumber to build Array).
 @ return conversation list object.

 @ discussion
 Aggregation into one display refers to the aggregation of all conversations of the specified conversation type into one in the conversation list. To click to enter, the list of all conversations of this conversation type will display.
 */
- (instancetype)initWithDisplayConversationTypes:(NSArray *)displayConversationTypeArray
                      collectionConversationType:(NSArray *)collectionConversationTypeArray;

#pragma mark - displayConversationTypeArray

/*!
 *  \~chinese
 列表中需要显示的会话类型数组

 @discussion 数组中的元素为RCConversationType转换的NSNumber
 
 *  \~english
 An array of conversation types to be displayed in the list.

 @ discussion The elements in the array are NSNumber converted by RCConversationType
 */
@property (nonatomic, strong) NSArray *displayConversationTypeArray;

/*!
 *  \~chinese
 列表中需要聚合为一条显示的会话类型数组

 @discussion 数组中的元素为RCConversationType转换的NSNumber
 
 *  \~english
 The list shall be aggregated into a displayed array of conversation types.

 @ discussion The elements in the array are NSNumber converted by RCConversationType.
 */
@property (nonatomic, strong) NSArray *collectionConversationTypeArray;

/*!
 *  \~chinese
 设置在列表中需要显示的会话类型

 @param conversationTypeArray 列表中需要显示的会话类型数组(需要将RCConversationType转为NSNumber构建Array)
 
 *  \~english
 Set the type of conversation that shall be displayed in the list.

 @param conversationTypeArray An array of conversation types to be displayed in the list (you shall convert RCConversationType to NSNumber to build Array).
 */
- (void)setDisplayConversationTypes:(NSArray *)conversationTypeArray;

/*!
 *  \~chinese
 设置在列表中需要聚合为一条显示的会话类型

 @param conversationTypeArray 列表中需要聚合为一条显示的会话类型数组(需要将RCConversationType转为NSNumber构建Array)
 
 *  \~english
 Set the conversation type that shall be aggregated into a display in the list.

 @param conversationTypeArray The list shall be aggregated into a displayed array of conversation types (you shall convert RCConversationType to NSNumber to build Array).
 */
- (void)setCollectionConversationType:(NSArray *)conversationTypeArray;

/*!
 *  \~chinese
 当前会话列表是否为从聚合Cell点击进入的子会话列表

 @discussion 您在点击会话列表中的聚合Cell跳转到到子会话列表时，需要将此属性设置为YES。
 
 *  \~english
 Whether the current conversation list is a list of sub-conversations clicked into from the aggregate Cell.

 @Discussion You shall set this property to YES when you click the aggregate Cell in the conversation list to jump to the child conversation list.
 */
@property (nonatomic, assign) BOOL isEnteredToCollectionViewController;

#pragma mark - conversationListDataSource
/*!
 *  \~chinese
 列表中会话数据模型的数据源

 @discussion 数据源中存放的元素为会话Cell的数据模型，即RCConversationModel对象。
 @warning 非线程安全，请在主线程操作此属性
 
 *  \~english
 The data source of the conversation data model in the list.

 The element stored in the @ discussion data source is the data model of the conversation Cell, that is, the RCConversationModel object.
  @ warning Non thread safe, please operate this property in the main thread.
 */
@property (nonatomic, strong) NSMutableArray *conversationListDataSource;

/*!
 *  \~chinese
 列表的TableView
 
 *  \~english
 TableView of the list
 */
@property (nonatomic, strong) UITableView *conversationListTableView;

#pragma mark - isShowNetworkIndicatorView

/*!
 *  \~chinese
 当网络断开时，是否在Tabel View Header中显示网络连接不可用的提示。

 @discussion 默认值为YES。
 
 *  \~english
 Whether to display a prompt in Tabel View Header that the network connection is not available when the network is disconnected.

  @ discussion The default value is YES.
 */
@property (nonatomic, assign) BOOL isShowNetworkIndicatorView;

/*!
 *  \~chinese
 当连接状态变化SDK自动重连时，是否在NavigationBar中显示连接中的提示。

 @discussion 默认是是NO。
 
 *  \~english
 Whether the prompt in the connection is displayed in the NavigationBar when the connection state changes and the SDK automatically reconnects.

  @ discussion The default value is NO.
 */
@property (nonatomic, assign) BOOL showConnectingStatusOnNavigatorBar;

#pragma mark - emptyConversationView

/*!
 *  \~chinese
 列表为空时显示的View
 
 *  \~english
 View displayed when the list is empty.
 */
@property (nonatomic, strong) UIView *emptyConversationView;

/*!
 *  \~chinese
 Cell的背景颜色
 
 *  \~english
 Background color of Cell.
 */
@property (nonatomic, strong) UIColor *cellBackgroundColor;

/*!
 *  \~chinese
 置顶会话的Cell背景颜色
 
 *  \~english
 Cell background color of the set-top conversation
 */
@property (nonatomic, strong) UIColor *topCellBackgroundColor;

/*!
 *  \~chinese
提示网络连接不可用的 View
 
 *  \~english
 View that indicates that the network connection is not available.
*/
@property (nonatomic, strong) RCNetworkIndicatorView *networkIndicatorView;

/*!
 *  \~chinese
 设置在会话列表中显示的头像形状，矩形或者圆形（全局有效）

 @param avatarStyle 显示的头像形状

 @discussion 默认值为矩形，即RC_USER_AVATAR_RECTANGLE。
 请在viewDidLoad之前设置，此设置在SDK中全局有效。
 
 *  \~english
 Set the portrait shape, rectangle or circle displayed in the conversation list (valid globally).

 @param avatarStyle The shape of the portrait displayed.

 @ discussion The default value is rectangle, that is, RC_USER_AVATAR_RECTANGLE.
  Please set it before viewDidLoad, which is valid globally in SDK.
 */
- (void)setConversationAvatarStyle:(RCUserAvatarStyle)avatarStyle;

/*!
 *  \~chinese
 设置会话列表界面中显示的头像大小（全局有效），高度必须大于或者等于36

 @param size 显示的头像大小

 @discussion  默认值为46*46。
 请在viewDidLoad之前设置，此设置在SDK中全局有效。
 
 *  \~english
 Set the size of the portrait displayed in the conversation list interface (valid globally). The height must be greater than or equal to 36.

 @param size The size of the portrait displayed.

 @ discussion The default value is 46*46.
  Please set it before viewDidLoad, which is valid globally in SDK.
 */
- (void)setConversationPortraitSize:(CGSize)size;

#pragma mark - UI event callback

#pragma mark tap event callback
/*!
 *  \~chinese
 点击会话列表中Cell的回调

 @param conversationModelType   当前点击的会话的Model类型
 @param model                   当前点击的会话的Model
 @param indexPath               当前会话在列表数据源中的索引值

 @discussion 您需要重写此点击事件，跳转到指定会话的会话页面。
 如果点击聚合Cell进入具体的子会话列表，在跳转时，需要将isEnteredToCollectionViewController设置为YES。
 
 *  \~english
 Callback for clicking Cell in the conversation list.

 @param conversationModelType The Model type of the conversation currently clicked.
 @param model The Model of the conversation currently clicked.
 @param indexPath The index value of the current conversation in the list data source.

 @ discussion You shall override this click event and jump to the conversation page of the specified conversation.
  If you click aggregate Cell to enter the list of specific child conversations, you shall set isEnteredToCollectionViewController to YES when you jump.
 */
- (void)onSelectedTableRow:(RCConversationModelType)conversationModelType
         conversationModel:(RCConversationModel *)model
               atIndexPath:(NSIndexPath *)indexPath;

/*!
 *  \~chinese
 点击Cell头像的回调

 @param model   会话Cell的数据模型
 
 *  \~english
 Callback for clicking Cell portrait.

 @param model Data Model of conversation Cell.
 */
- (void)didTapCellPortrait:(RCConversationModel *)model;

/*!
 *  \~chinese
 长按Cell头像的回调

 @param model   会话Cell的数据模型
 
 *  \~english
 Callback for holding Cell portrait.

 @param model Data Model of conversation Cell.
 */
- (void)didLongPressCellPortrait:(RCConversationModel *)model;

#pragma mark delete conversation callback

/*!
 *  \~chinese
 删除会话的回调

 @param model   会话Cell的数据模型
 
 *  \~english
 Callback for deleting conversation.

 @param model Data Model of conversation Cell.
 */
- (void)didDeleteConversationCell:(RCConversationModel *)model;

#pragma mark - Cell load callback

/*!
 *  \~chinese
 即将加载增量数据源的回调

 @param dataSource      即将加载的增量数据源（元素为RCConversationModel对象）
 @return                修改后的数据源（元素为RCConversationModel对象）

 @discussion 您可以在回调中修改、添加、删除数据源的元素来定制显示的内容，会话列表会根据您返回的修改后的数据源进行显示。
 数据源中存放的元素为会话Cell的数据模型，即RCConversationModel对象。
 2.9.21 及其以前版本，dataSource 为全量数据，conversationListDataSource = dataSource
 2.9.22 及其以后版本，dataSource 为增量数据，conversationListDataSource += dataSource，如果需要更改全量数据的内容，可以更改 conversationListDataSource
 
 *  \~english
 Callback for the incremental data source that is about to be loaded.

 @param dataSource Incremental data source to be loaded (elements are RCConversationModel objects).
 @ return modified data source (element is RCConversationModel object).

 @ discussion You can modify, add, or delete elements of the data source to customize the display in the callback, and the conversation list will be displayed according to the modified data source you returned.
  The element stored in the data source is the data model of the conversation Cell, that is, the RCConversationModel object.
  2.9.21 and previous versions, dataSource is full data, conversationListDataSource = dataSource.
 2.9.22 and later, dataSource is incremental data, conversationListDataSource + = dataSource,. If you shall change the content of all data, you can change conversationListDataSource.
 */
- (NSMutableArray<RCConversationModel *> *)willReloadTableData:(NSMutableArray<RCConversationModel *> *)dataSource;

/*!
 *  \~chinese
 即将显示Cell的回调

 @param cell        即将显示的Cell
 @param indexPath   该Cell对应的会话Cell数据模型在数据源中的索引值

 @discussion 您可以在此回调中修改Cell的一些显示属性。
 
 *  \~english
 Callback for Cell to be displayed.

 @param cell Cell to be displayed.
 @param indexPath The index value of the conversation Cell data model corresponding to the Cell in the data source.

 @ discussion You can modify some of the display properties of Cell in this callback.
 */
- (void)willDisplayConversationTableCell:(RCConversationBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath;

/**
 *  \~chinese
 Cell状态更新时的回调

 @param indexPath 该Cell对应的会话Cell数据模型在数据源中的索引值

 @discussion 当Cell的阅读状态等信息发生改变时的回调，您可以在此回调中更新Cell的显示。
 
 *  \~english
 Callback when Cell status updates.

 @param indexPath The index value of the conversation Cell data model corresponding to the Cell in the data source.

 @ discussion callback when information such as the reading status of Cell changes. You can update the display of Cell in this callback.
 */
- (void)updateCellAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Custom  Conversation Cell

/*!
 *  \~chinese
 自定义会话Cell显示时的回调

 @param tableView       当前TabelView
 @param indexPath       该Cell对应的会话Cell数据模型在数据源中的索引值
 @return                自定义会话需要显示的Cell
 
 *  \~english
 Callback when the custom conversation Cell is displayed.

 @param tableView Current TabelView.
 @param indexPath The index value of the conversation Cell data model corresponding to the Cell in the data source.
 @ return The Cell that the custom conversation shall display.
 */
- (RCConversationBaseCell *)rcConversationListTableView:(UITableView *)tableView
                                  cellForRowAtIndexPath:(NSIndexPath *)indexPath;

/*!
 *  \~chinese
 自定义会话Cell显示时的回调

 @param tableView       当前TabelView
 @param indexPath       该Cell对应的会话Cell数据模型在数据源中的索引值
 @return                自定义会话需要显示的Cell的高度
 
 *  \~english
 Callback when the custom conversation Cell is displayed.

 @param tableView Current TabelView.
 @param indexPath The index value of the conversation Cell data model corresponding to the Cell in the data source.
 @ return The height of the Cell that the custom conversation shall display.
 */
- (CGFloat)rcConversationListTableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

/*!
 *  \~chinese
 左滑删除自定义会话时的回调

 @param tableView       当前TabelView
 @param editingStyle    当前的Cell操作，默认为UITableViewCellEditingStyleDelete
 @param indexPath       该Cell对应的会话Cell数据模型在数据源中的索引值

 @discussion 自定义会话Cell在删除时会回调此方法，您可以在此回调中，定制删除的提示UI、是否删除。
 如果确定删除该会话，您需要在调用RCIMClient中的接口删除会话或其中的消息，
 并从conversationListDataSource和conversationListTableView中删除该会话。
 
 *  \~english
 Callback for left sliding and deleting a custom conversation.

 @param tableView Current TabelView.
 @param editingStyle Current Cell operation. The default value is UITableViewCellEditingStyleDelete.
 @param indexPath The index value of the conversation Cell data model corresponding to the Cell in the data source.

 @ discussion Custom conversation Cell calls back this method when it is deleted. In this callback, you can customize the prompt UI for deletion and whether to delete it.
  If you decide to delete the conversation, you shall delete the conversation or the message in it when calling the interface in RCIMClient and delete the conversation from conversationListDataSource and conversationListTableView.
 */
- (void)rcConversationListTableView:(UITableView *)tableView
                 commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                  forRowAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - UI Refresh

/*!
 *  \~chinese
 从数据库中重新读取会话列表数据，并刷新会话列表

 @warning 从数据库中重新读取并刷新，会比较耗时，请谨慎使用。
 
 *  \~english
 Reread the conversation list data from the database and refresh the conversation list.

 @ warning Reread and refresh from the database, which is time-consuming, so use it with caution.
 */
- (void)refreshConversationTableViewIfNeeded;

/*!
 *  \~chinese
 向列表中插入或更新一条会话，并刷新会话列表界面

 @param conversationModel   会话Cell的数据模型

 @discussion 如果该会话Cell数据模型在数据源中已经存在，则会更新数据源中的数据并更新UI；
 如果数据源没有该会话Cell的数据模型，则插入数据源再更新UI。
 
 *  \~english
 Insert or update a conversation to the list and refresh the conversation list interface.

 @param conversationModel Data Model of conversation Cell.

 @ discussion If the conversation Cell data model already exists in the data source, the data in the data source is updated and the UI is updated.
 If the data source does not have a data model for the conversation Cell, insert the data source and update the UI.
 */
- (void)refreshConversationTableViewWithConversationModel:(RCConversationModel *)conversationModel;

/*!
 *  \~chinese
 当用户退出登陆时，是否还能继续显示会话列表

 @discussion 默认值为YES。
 @warning 该字段已被废弃，用户会使用 APP  收发个人的敏感消息，如果断开链接之后不关闭数据库，可能出现当前用户看到上个用户的敏感消息，基于安全方面考虑：当断开 SDK 连接的时候，SDK 会把消息数据库关闭
 
 *  \~english
 Can the conversation list continue to be displayed when the user logs out and logs in?

 @ discussion The default value is YES.
 */
@property (nonatomic, assign) BOOL showConversationListWhileLogOut __deprecated_msg("");

#pragma mark - Other

/*!
 *  \~chinese
 在会话列表中，收到新消息的回调

 @param notification    收到新消息的notification

 @discussion SDK在此方法中有针对消息接收有默认的处理（如刷新等），如果您重写此方法，请注意调用super。

 notification的object为RCMessage消息对象，userInfo为NSDictionary对象，其中key值为@"left"，value为还剩余未接收的消息数的NSNumber对象。
 
 *  \~english
 Callback for receiving new message in the conversation list

 @param notification Notification that received the new message.

 @ discussion SDK has default processing (such as refresh, etc.) for message reception in this method. If you override this method, be careful to call super.

  The object of notification is the RCMessage message object, and userInfo is the NSDictionary object, where the key value is @ "left" and value is the NSNumber object with the number of messages remaining unreceived.
 */
- (void)didReceiveMessageNotification:(NSNotification *)notification;

/*!
 *  \~chinese
 即将更新未读消息数的回调，该方法在非主线程回调，如果想在本方法中操作 UI，请手动切换到主线程。

 @discussion 当收到消息或删除会话时，会调用此回调，您可以在此回调中执行未读消息数相关的操作。
 
 *  \~english
 The callback for the number of unread messages is about to be updated. This method is called back from a non-main thread. If you want to operate UI, in this method, please manually switch to the main thread.

  @ discussion This callback is called when it receives a message or deletes a conversation, and you can perform operations related to the number of unread messages in this callback.
 */
- (void)notifyUpdateUnreadMessageCount;

@end
