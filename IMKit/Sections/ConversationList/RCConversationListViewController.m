//
//  RCConversationListViewController.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCConversationListViewController.h"
#import "RCConversationCell.h"
#import "RCConversationCellUpdateInfo.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCNetworkIndicatorView.h"
#import "RCMJRefresh.h"
#import "UIImage+RCDynamicImage.h"
#import "RCConversationListDataSource.h"
#import "RCKitConfig.h"
#import "RCConversationViewController.h"
@interface RCConversationListViewController () <UITableViewDataSource, UITableViewDelegate, RCConversationCellDelegate,RCConversationListDataSourceDelegate>

@property (nonatomic, strong) UIView *connectionStatusView;
@property (nonatomic, strong) UIView *navigationTitleView;
@property (nonatomic, strong) RCMJRefreshAutoNormalFooter *footer;
@property (nonatomic, strong) RCConversationListDataSource *dataSource;
@end

@implementation RCConversationListViewController

#pragma mark - 初始化
- (instancetype)initWithDisplayConversationTypes:(NSArray *)displayConversationTypeArray
                      collectionConversationType:(NSArray *)collectionConversationTypeArray {
    self = [super init];
    if (self) {
        [self rcinit];
        self.displayConversationTypeArray = displayConversationTypeArray;
        self.collectionConversationTypeArray = collectionConversationTypeArray;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self rcinit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self rcinit];
    }
    return self;
}

- (void)rcinit {
    self.dataSource = [[RCConversationListDataSource alloc] init];
    self.dataSource.delegate = self;
    self.isEnteredToCollectionViewController = NO;
    self.isShowNetworkIndicatorView = YES;
    self.displayConversationTypeArray = @[@(ConversationType_PRIVATE), @(ConversationType_GROUP), @(ConversationType_SYSTEM), @(ConversationType_CUSTOMERSERVICE), @(ConversationType_CHATROOM), @(ConversationType_APPSERVICE), @(ConversationType_PUBLICSERVICE), @(ConversationType_Encrypted)];
}

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(setExtendedLayoutIncludesOpaqueBars:)]) {
        self.extendedLayoutIncludesOpaqueBars = YES;
    }
    
    self.conversationListTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.conversationListTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.conversationListTableView.backgroundColor = RCDYCOLOR(0xffffff, 0x000000);
    self.conversationListTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(1, 1, 0, CGFLOAT_MIN)];
    CGFloat leftOffset = 12 + [RCKitConfig defaultConfig].ui.globalConversationPortraitSize.width + 12;
    if ([self.conversationListTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        self.conversationListTableView.separatorInset = UIEdgeInsetsMake(0, leftOffset, 0, 0);
    }
    if ([self.conversationListTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        self.conversationListTableView.layoutMargins = UIEdgeInsetsMake(0, leftOffset, 0, 0);
    }
    self.conversationListTableView.dataSource = self;
    self.conversationListTableView.delegate = self;
    self.conversationListTableView.rcmj_footer = self.footer;
    [self.view addSubview:self.conversationListTableView];
    [self registerObserver];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateNetworkIndicatorView];
    [self refreshConversationTableViewIfNeeded];
    self.dataSource.isConverstaionListAppear = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self updateConnectionStatusView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.dataSource.isConverstaionListAppear = NO;
    [self hideConnectingView];
    [self.conversationListTableView setEditing:NO];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self layoutSubview:size];
    }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> context){

        }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - TableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCConversationModel *model = self.dataSource.dataList[indexPath.row];

    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION) {
        RCConversationBaseCell *userCustomCell =
            [self rcConversationListTableView:tableView cellForRowAtIndexPath:indexPath];
        if (!userCustomCell) {
            NSLog(@"The custom cell is returned as nil, "
                  @"if the conversationModelType is RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION，and the message type is RCContactNotificationMessage "
                  @"needs customized cell to display");
        }
        userCustomCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        [userCustomCell setDataModel:model];
        [self willDisplayConversationTableCell:userCustomCell atIndexPath:indexPath];

        return userCustomCell;
    } else {
        static NSString *cellReuseIndex = @"rc.conversationList.cellReuseIndex";
        RCConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIndex];
        if (!cell) {
            cell =
                [[RCConversationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIndex];
        }
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        [cell setDataModel:model];
        [self willDisplayConversationTableCell:cell atIndexPath:indexPath];

        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCConversationModel *model = self.dataSource.dataList[indexPath.row];
    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION) {
        return [self rcConversationListTableView:tableView heightForRowAtIndexPath:indexPath];
    } else {
        return RCKitConfigCenter.ui.globalConversationPortraitSize.height + 24.f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.dataSource.dataList.count) {
        return;
    }
    RCConversationModel *model = self.dataSource.dataList[indexPath.row];

    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE) {
        NSLog(@"Starting from SDK version 2.3.0,publicservice is processed in demo, "
              @"please Refer to onSelectedTableRow function in the RCDChatListViewController");
    }
    [self onSelectedTableRow:model.conversationModelType conversationModel:model atIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.isShowNetworkIndicatorView && !self.networkIndicatorView.hidden) {
        return self.networkIndicatorView.bounds.size.height;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.isShowNetworkIndicatorView && !self.networkIndicatorView.hidden) {
        return self.networkIndicatorView;
    } else {
        return nil;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        RCConversationModel *model = self.dataSource.dataList[indexPath.row];

        if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL ||
            model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE) {
            if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
                [self sendReadReceiptIfNeed:model];
            }
            [[RCIMClient sharedRCIMClient] removeConversation:model.conversationType targetId:model.targetId];
            [self.dataSource.dataList removeObjectAtIndex:indexPath.row];
            [self.conversationListTableView deleteRowsAtIndexPaths:@[ indexPath ]
                                                  withRowAnimation:UITableViewRowAnimationFade];
        } else if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
            [[RCIMClient sharedRCIMClient] clearConversations:@[ @(model.conversationType) ]];
            [self.dataSource.dataList removeObjectAtIndex:indexPath.row];
            [self.conversationListTableView deleteRowsAtIndexPaths:@[ indexPath ]
                                                  withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self rcConversationListTableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
        }

        [self didDeleteConversationCell:model];
        [self notifyUpdateUnreadMessageCount];

        if (self.isEnteredToCollectionViewController && self.dataSource.dataList.count == 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(),
                           ^{
                               [self.conversationListTableView removeFromSuperview];
                               [self.navigationController popViewControllerAnimated:YES];
                           });
        } else {
            [self updateEmptyConversationView];
        }
    } else {
        DebugLog(@"editingStyle %ld is unsupported.", (long)editingStyle);
    }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCLocalizedString(@"Delete");
}

#pragma mark - Target action
- (void)loadMore {
    __weak typeof(self) ws = self;
    [self.dataSource loadMoreConversations:^(NSMutableArray<RCConversationModel *> *modelList) {
        if(modelList.count > 0) {
            [ws.conversationListTableView reloadData];
            [ws updateEmptyConversationView];
        }
        [ws.footer endRefreshing];
    }];
}

- (void)layoutSubview:(CGSize)size {
    if (![RCKitUtility currentDeviceIsIPad]) {
        return;
    }
    self.conversationListTableView.frame = self.view.bounds;
    [self.conversationListTableView reloadData];
}

- (void)refreshConversationTableViewIfNeeded {
    __weak typeof(self) weakSelf = self;
    [self.dataSource forceLoadConversationModelList:^(NSMutableArray *modelList) {
        [weakSelf.conversationListTableView reloadData];
        [weakSelf updateEmptyConversationView];
    }];
}


- (void)sendReadReceiptIfNeed:(RCConversationModel *)model{
    [RCKitUtility syncConversationReadStatusIfEnabled:model];
}

#pragma mark - RCConversationListDataSourceDelegate
- (NSMutableArray<RCConversationModel *> *)dataSource:(RCConversationListDataSource *)datasource willReloadTableData:(NSMutableArray<RCConversationModel *> *)modelList {
    return [self willReloadTableData:modelList];
}
- (void)dataSource:(RCConversationListDataSource *)dataSource willReloadAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    [self.conversationListTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateEmptyConversationView];
}
- (void)dataSource:(RCConversationListDataSource *)dataSource willInsertAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    [self.conversationListTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateEmptyConversationView];
}
- (void)dataSource:(RCConversationListDataSource *)dataSource willDeleteAtIndexPaths:(NSArray <NSIndexPath *> *)deleteIndexPaths willInsertAtIndexPaths:(NSArray <NSIndexPath *> *)insertIndexPaths {
    [self.conversationListTableView beginUpdates];
    [self.conversationListTableView
        deleteRowsAtIndexPaths:deleteIndexPaths
              withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.conversationListTableView
        insertRowsAtIndexPaths:insertIndexPaths
              withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.conversationListTableView endUpdates];
    [self updateEmptyConversationView];
}
- (void)refreshConversationTableViewIfNeededInDataSource:(RCConversationListDataSource *)datasource {
    [self refreshConversationTableViewIfNeeded];
}

- (void)notifyUpdateUnreadMessageCountInDataSource {
    [self notifyUpdateUnreadMessageCount];
}

#pragma mark - update view
- (void)updateNetworkIndicatorView {
    RCConnectionStatus status = [[RCIMClient sharedRCIMClient] getConnectionStatus];

    BOOL needReloadTableView = NO;
    if (status == ConnectionStatus_NETWORK_UNAVAILABLE || status == ConnectionStatus_UNKNOWN ||
        status == ConnectionStatus_Unconnected) {
        if (self.networkIndicatorView.hidden) {
            needReloadTableView = YES;
        }
        self.networkIndicatorView.hidden = NO;
        [self.networkIndicatorView setText:RCLocalizedString(@"ConnectionIsNotReachable")];
    } else if(status == ConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT){
        if (self.networkIndicatorView.hidden) {
            needReloadTableView = YES;
        }
        self.networkIndicatorView.hidden = NO;
        [self.networkIndicatorView setText:RCLocalizedString(@"KickedOfflineByOtherClient")];
    } else if (status == ConnectionStatus_PROXY_UNAVAILABLE) {
        if (self.networkIndicatorView.hidden) {
            needReloadTableView = YES;
        }
        self.networkIndicatorView.hidden = NO;
        [self.networkIndicatorView setText:RCLocalizedString(@"ConnectionstatusProxyUnavailable")];
    } else if (status != ConnectionStatus_Connecting) {
        if (!self.networkIndicatorView.hidden) {
            needReloadTableView = YES;
        }
        self.networkIndicatorView.hidden = YES;
    }

    if (needReloadTableView) {
        [self.conversationListTableView reloadData];
    }
}

- (void)updateConnectionStatusView {
    if (self.isEnteredToCollectionViewController || !self.showConnectingStatusOnNavigatorBar ||
        !self.dataSource.isConverstaionListAppear) {
        return;
    }

    RCConnectionStatus status = [[RCIMClient sharedRCIMClient] getConnectionStatus];
    if (status == ConnectionStatus_Connecting || status == ConnectionStatus_Suspend) {
        [self showConnectingView];
    } else {
        [self hideConnectingView];
    }
}

- (void)showConnectingView {
    UINavigationItem *visibleNavigationItem = nil;
    if (self.tabBarController) {
        visibleNavigationItem = self.tabBarController.navigationItem;
    } else if (self.navigationItem) {
        visibleNavigationItem = self.navigationItem;
    }

    if (visibleNavigationItem) {
        if (![visibleNavigationItem.titleView isEqual:self.connectionStatusView]) {
            self.navigationTitleView = visibleNavigationItem.titleView;
            visibleNavigationItem.titleView = self.connectionStatusView;
        }
    }
}

- (void)hideConnectingView {
    UINavigationItem *visibleNavigationItem = nil;
    if (self.tabBarController) {
        visibleNavigationItem = self.tabBarController.navigationItem;
    } else if (self.navigationItem) {
        visibleNavigationItem = self.navigationItem;
    }

    if (visibleNavigationItem) {
        if ([visibleNavigationItem.titleView isEqual:self.connectionStatusView]) {
            visibleNavigationItem.titleView = self.navigationTitleView;
        } else {
            self.navigationTitleView = visibleNavigationItem.titleView;
        }
    }
}

- (void)updateEmptyConversationView {
    if (self.dataSource.dataList.count == 0) {
        self.emptyConversationView.hidden = NO;
    } else {
        self.emptyConversationView.hidden = YES;
    }
}

#pragma mark - Notification selector
- (void)registerObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onConnectionStatusChangedNotification:)
                                                 name:RCKitDispatchConnectionStatusChangedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshConversationTableViewIfNeeded)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateCellIfNeed:)
                                                 name:RCKitConversationCellUpdateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMessageNotification:)
                                                 name:RCKitDispatchMessageNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(conversationStatusChanged:)
                                                 name:RCKitDispatchConversationStatusChangeNotification
                                               object:nil];
}

- (void)didReceiveMessageNotification:(NSNotification *)notification {
    [self.dataSource didReceiveMessageNotification:notification];
}

- (void)onConnectionStatusChangedNotification:(NSNotification *)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateConnectionStatusView];
        [self updateNetworkIndicatorView];
        if (ConnectionStatus_Connected == [status.object integerValue]) {
            if (self.dataSource.dataList.count == 0) {
                [self refreshConversationTableViewIfNeeded];
            }
        }
    });
}

- (void)updateCellIfNeed:(NSNotification *)notification {
    RCConversationCellUpdateInfo *updateInfo = notification.object;
    dispatch_main_async_safe(^{
        for (int i = 0; i < self.dataSource.dataList.count; i++) {
            RCConversationModel *model = self.dataSource.dataList[i];
            if ([updateInfo.model isEqual:model]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                [self updateCellAtIndexPath:indexPath];
                break;
            }
        }
    });
}

- (void)conversationStatusChanged:(NSNotification *)notification {
    NSArray<RCConversationStatusInfo *> *conversationStatusInfos = notification.object;
    __weak typeof(self) ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ws.conversationListDataSource.count <= 0) {
            return;
        }
        if (conversationStatusInfos.count == 1) {
            RCConversationStatusInfo *statusInfo = [conversationStatusInfos firstObject];
            if (statusInfo.conversationStatusType == RCConversationStatusType_Top) {
                [ws refreshConversationTableViewIfNeeded];
            }else {
                for (int i = 0; i < ws.conversationListDataSource.count; i++) {
                    RCConversationModel *conversationModel = ws.conversationListDataSource[i];
                    BOOL isSameConversation = [conversationModel.targetId isEqualToString:statusInfo.targetId] &&
                    (conversationModel.conversationType == statusInfo.conversationType);
                    BOOL isSameChannel = [conversationModel.channelId isEqualToString:statusInfo.channelId];
                    BOOL isUtralGroup = (statusInfo.conversationType == ConversationType_ULTRAGROUP);
                    BOOL ret = isUtralGroup ? (isSameConversation && isSameChannel) : isSameConversation;
                    if (ret) {
                        NSInteger refreshIndex = [self.conversationListDataSource indexOfObject:conversationModel];
                        if (statusInfo.conversationStatusType == RCConversationStatusType_Mute) {
                            conversationModel.blockStatus = statusInfo.conversationStatusvalue;
                        } else if (statusInfo.conversationStatusType == RCConversationStatusType_Top) {
                            conversationModel.isTop = (statusInfo.conversationStatusvalue == 1);
                        }
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:refreshIndex inSection:0];
                        [ws.conversationListTableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                            withRowAnimation:UITableViewRowAnimationNone];
                        break;
                    }
                }
            }
        } else {
            [ws refreshConversationTableViewIfNeeded];
        }
    });
}

#pragma mark - View Setter&Getter

- (RCMJRefreshAutoNormalFooter *)footer {
    if(!_footer) {
        _footer = [RCMJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
        _footer.refreshingTitleHidden = YES;
    }
    return _footer;
}

- (RCNetworkIndicatorView *)networkIndicatorView {
    if (!_networkIndicatorView) {
        _networkIndicatorView = [[RCNetworkIndicatorView alloc]
            initWithText:RCLocalizedString(@"ConnectionIsNotReachable")];
        _networkIndicatorView.backgroundColor = RCDYCOLOR(0xffdfdf, 0x7D2C2C);
        [_networkIndicatorView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, 48)];
        _networkIndicatorView.hidden = YES;
    }
    return _networkIndicatorView;
}

- (UIView *)connectionStatusView {
    if (!_connectionStatusView) {
        _connectionStatusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];

        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] init];
        [indicatorView startAnimating];
        [_connectionStatusView addSubview:indicatorView];

        NSString *loading = RCLocalizedString(@"Connecting...");
        CGSize textSize = [RCKitUtility getTextDrawingSize:loading
                                                      font:[[RCKitConfig defaultConfig].font fontOfSecondLevel]
                                           constrainedSize:CGSizeMake(_connectionStatusView.frame.size.width, 2000)];

        CGRect frame = CGRectMake(
            (_connectionStatusView.frame.size.width - (indicatorView.frame.size.width + textSize.width + 3)) / 2,
            (_connectionStatusView.frame.size.height - indicatorView.frame.size.height) / 2,
            indicatorView.frame.size.width, indicatorView.frame.size.height);
        indicatorView.frame = frame;
        frame = CGRectMake(indicatorView.frame.origin.x + 14 + indicatorView.frame.size.width,
                           (_connectionStatusView.frame.size.height - textSize.height) / 2, textSize.width,
                           textSize.height);
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        [label setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        [label setText:loading];
        //    [label setTextColor:[UIColor whiteColor]];
        [_connectionStatusView addSubview:label];
    }
    return _connectionStatusView;
}

@synthesize emptyConversationView = _emptyConversationView;
- (UIView *)emptyConversationView {
    if (!_emptyConversationView) {
        _emptyConversationView = [[UIImageView alloc] initWithImage:RCResourceImage(@"no_message_img")];
        _emptyConversationView.center = self.view.center;
        CGRect emptyRect = _emptyConversationView.frame;
        emptyRect.origin.y -= 36;
        [_emptyConversationView setFrame:emptyRect];
        UILabel *emptyLabel =
            [[UILabel alloc] initWithFrame:CGRectMake(-10, _emptyConversationView.frame.size.height,
                                                      _emptyConversationView.frame.size.width + 20, 20)];
        emptyLabel.text = RCLocalizedString(@"no_message");
        [emptyLabel setFont:[[RCKitConfig defaultConfig].font fontOfFourthLevel]];
        [emptyLabel setTextColor:[UIColor lightGrayColor]];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        [_emptyConversationView addSubview:emptyLabel];
        [self.conversationListTableView addSubview:_emptyConversationView];
    }
    return _emptyConversationView;
}

- (void)setEmptyConversationView:(UIView *)emptyConversationView {
    if (_emptyConversationView) {
        [_emptyConversationView removeFromSuperview];
    }
    _emptyConversationView = emptyConversationView;
    [self.conversationListTableView addSubview:_emptyConversationView];
}

- (void)setShowConnectingStatusOnNavigatorBar:(BOOL)showConnectingStatusOnNavigatorBar {
    _showConnectingStatusOnNavigatorBar = showConnectingStatusOnNavigatorBar;
    if (!_showConnectingStatusOnNavigatorBar) {
        [self hideConnectingView];
    }
}

- (void)setConversationListDataSource:(NSMutableArray *)conversationListDataSource {
    self.dataSource.dataList = conversationListDataSource;
}

- (NSMutableArray *)conversationListDataSource {
    return self.dataSource.dataList;
}

- (void)setDisplayConversationTypeArray:(NSArray *)displayConversationTypeArray {
    self.dataSource.displayConversationTypeArray = displayConversationTypeArray;
}

- (NSArray *)displayConversationTypeArray {
    return self.dataSource.displayConversationTypeArray;
}

- (void)setCollectionConversationTypeArray:(NSArray *)collectionConversationTypeArray {
    self.dataSource.collectionConversationTypeArray = collectionConversationTypeArray;
}

- (NSArray *)collectionConversationTypeArray {
    return self.dataSource.collectionConversationTypeArray;
}

- (void)setCellBackgroundColor:(UIColor *)cellBackgroundColor {
    self.dataSource.cellBackgroundColor = cellBackgroundColor;
}

- (UIColor *)cellBackgroundColor {
    return self.dataSource.cellBackgroundColor;
}

- (void)setTopCellBackgroundColor:(UIColor *)topCellBackgroundColor {
    self.dataSource.topCellBackgroundColor = topCellBackgroundColor;
}

- (UIColor *)topCellBackgroundColor {
    return self.dataSource.topCellBackgroundColor;
}

#pragma mark - 钩子
- (void)notifyUpdateUnreadMessageCount {
}
- (void)didTapCellPortrait:(RCConversationModel *)model {
}
- (void)didLongPressCellPortrait:(RCConversationModel *)model {
}
- (NSMutableArray<RCConversationModel *> *)willReloadTableData:(NSMutableArray<RCConversationModel *> *)dataSource {
    return dataSource;
}
- (void)willDisplayConversationTableCell:(RCConversationBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath {
}
- (void)updateCellAtIndexPath:(NSIndexPath *)indexPath {
}
- (void)onSelectedTableRow:(RCConversationModelType)conversationModelType
         conversationModel:(RCConversationModel *)model
               atIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationController) {
        RCConversationViewController *conversationVC = [[RCConversationViewController alloc] initWithConversationType:model.conversationType targetId:model.targetId];
        conversationVC.conversationType = model.conversationType;
        conversationVC.targetId = model.targetId;
        conversationVC.title = model.conversationTitle;
        if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
            conversationVC.unReadMessage = model.unreadMessageCount;
            conversationVC.enableNewComingMessageIcon = YES; //开启消息提醒
            conversationVC.enableUnreadMessageIcon = YES;
        }
        [self.navigationController pushViewController:conversationVC animated:YES];
    }else{
        RCLogI(@"navigationController is nil , Please Rewrite `onSelectedTableRow:conversationModel:atIndexPath:` method to implement the conversation cell click to push RCConversationViewController vc");
    }
}
- (void)didDeleteConversationCell:(RCConversationModel *)model {
}
- (void)rcConversationListTableView:(UITableView *)tableView
                 commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                  forRowAtIndexPath:(NSIndexPath *)indexPath {
}
- (RCConversationBaseCell *)rcConversationListTableView:(UITableView *)tableView
                                  cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}
- (CGFloat)rcConversationListTableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.5f;
}

#pragma mark - 向后兼容

- (void)setDisplayConversationTypes:(NSArray *)conversationTypeArray {
    self.displayConversationTypeArray = conversationTypeArray;
}
- (void)setCollectionConversationType:(NSArray *)conversationTypeArray {
    self.collectionConversationTypeArray = conversationTypeArray;
}
- (void)setConversationAvatarStyle:(RCUserAvatarStyle)avatarStyle {
    RCKitConfigCenter.ui.globalConversationAvatarStyle = avatarStyle;
}
- (void)setConversationPortraitSize:(CGSize)size {
    RCKitConfigCenter.ui.globalConversationPortraitSize = size;
}
- (void)refreshConversationTableViewWithConversationModel:(RCConversationModel *)conversationModel {
    [self.dataSource refreshConversationModel:conversationModel];
}

#pragma mark - traitCollection
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self fitDarkMode];
}

- (void)fitDarkMode {
    if (!RCKitConfigCenter.ui.enableDarkMode) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        self.networkIndicatorView.networkUnreachableImageView.image = RCResourceImage(@"network_fail");
        if ([self.emptyConversationView isKindOfClass:[UIImageView class]]) {
            UIImageView *imageView = (UIImageView *)self.emptyConversationView;
            if (imageView.image.rc_imageLocalPath && imageView.image.rc_imageLocalPath.length > 0 &&
                [imageView.image rc_needReloadImage]) {
                imageView.image = [UIImage rc_imageWithLocalPath:imageView.image.rc_imageLocalPath];
            }
        }
        if (self.dataSource.isConverstaionListAppear) {
            [self.conversationListTableView reloadData];
        }
    }
}
@end
