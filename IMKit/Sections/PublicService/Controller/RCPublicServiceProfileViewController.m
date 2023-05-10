//
//  RCPublicServiceProfileViewController.m
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//
#import "RCPublicServiceProfileViewController.h"
#import "RCConversationViewController.h"
#import "RCPublicServiceProfileActionCell.h"
#import "RCPublicServiceProfileOwnerCell.h"
#import "RCPublicServiceProfilePlainCell.h"
#import "RCPublicServiceProfileRcvdMsgCell.h"
#import "RCPublicServiceProfileTelCell.h"
#import "RCPublicServiceProfileUrlCell.h"
#import "RCPublicServiceViewConstants.h"
#import <objc/runtime.h>
#import <RongPublicService/RongPublicService.h>

#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCloudImageView.h"
#import "RCKitConfig.h"
#import "RCActionSheetView.h"
// main section of PA, include descrptions, owner,
#define RC_PUBLIC_ACCOUNT_INFO_VIEW_SECTION_TYPE_MAIN 0
// Business scope
#define RC_PUBLIC_ACCOUNT_INFO_VIEW_SECTION_TYPE_BUSINESS 1
// receive msg or not
#define RC_PUBLIC_ACCOUNT_INFO_VIEW_SECTION_TYPE_MESSAGE_SETTING 2
// MSG histroy, location
#define RC_PUBLIC_ACCOUNT_INFO_VIEW_SECTION_TYPE_MORE 3
// follow or enter conversation, depend on follow status
#define RC_PUBLIC_ACCOUNT_INFO_VIEW_SECTION_TYPE_ACTION 4

@interface RCPublicServiceProfileViewController () <UITableViewDataSource, RCPublicServiceProfileViewUrlDelegate,
                                                    RCPublicServiceProfileActionDelegate>
@property (nonatomic, strong) NSArray *cellCollections; // array of array of cells
@property (nonatomic, strong) RCPublicServiceProfileActionCell *actionCell;
@property (nonatomic, strong) RCPublicServiceProfileRcvdMsgCell *rcvdMsgCell;
@end

@implementation RCPublicServiceProfileViewController
#pragma mark – Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = RCDYCOLOR(0xf0f0f6, 0x000000);
    self.tableView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
    [self.tableView reloadData];
}

#pragma mark - Private Methods

- (void)onAction {
}

- (void)setup {
    self.tableView.dataSource = self;
}


- (void)setServiceProfile:(RCPublicServiceProfile *)serviceProfile {
    _serviceProfile = serviceProfile;

    //    _serviceProfile.descriptions=@"公司办公企业办办公企业办公企业办公企业办公企业办公企业办公企业办公企业办公企业办公企业办公企业办公企业办公企业办公企业";
    //    _serviceProfile.owner=@"北京爱还是觉得快放办公企业办公企业办公企业办公企业办公企业办公企业办公企业办公企业假";
    //    _serviceProfile.ownerUrl=@"http://www.baidu.com";
    //    _serviceProfile.serviceTel=@"1234567891234";
    //    _serviceProfile.histroyMsgUrl=@"http://www.baidu.com";
    //    _serviceProfile.scope=@"互联网/软联网/软件开发";
    self.tableView.tableHeaderView = [self getTableViewHeader];
    //    if (_serviceProfile.followed) {
    //        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStylePlain
    //        target:self action:@selector(onOptionButtonPressed)];
    //        self.navigationItem.rightBarButtonItem = item;
    //    }else
    //    {
    //        self.navigationItem.rightBarButtonItem = nil;
    //    }
    self.navigationItem.title = self.serviceProfile.name;
}

- (void)onOptionButtonPressed {
    [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"Share"), RCLocalizedString(@"Report"), RCLocalizedString(@"ClearHistory"), RCLocalizedString(@"Unfollow")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
        if (index == 3) {
            [self unsubscribePublicService];
        }
    } cancelBlock:^{
            
    }];
}

- (NSArray *)cellCollections {
    if (!_cellCollections) {
        NSMutableArray *collections = [[NSMutableArray alloc] init];
        NSMutableArray *mainSection = [[NSMutableArray alloc] init];

        if (self.serviceProfile.introduction || self.serviceProfile.owner ||
            self.serviceProfile.publicServiceTel) { // for main
            if (self.serviceProfile.introduction) {
                RCPublicServiceProfilePlainCell *cell = [[RCPublicServiceProfilePlainCell alloc] init];

                [cell setTitle:RCLocalizedString(@"Introduced")
                       Content:self.serviceProfile.introduction];
                [mainSection addObject:cell];
            }

            if (self.serviceProfile.owner) {
                RCPublicServiceProfileOwnerCell *cell = [[RCPublicServiceProfileOwnerCell alloc] init];
                [cell setTitle:RCLocalizedString(@"AccountType")
                       Content:self.serviceProfile.owner
                           url:self.serviceProfile.ownerUrl
                      delegate:self];
                [mainSection addObject:cell];
            }

            if (self.serviceProfile.publicServiceTel) {
                RCPublicServiceProfileTelCell *cell = [[RCPublicServiceProfileTelCell alloc] init];
                [cell setTitle:RCLocalizedString(@"ServicePhone")
                       Content:self.serviceProfile.publicServiceTel];
                [mainSection addObject:cell];
            }
        }

        if (self.serviceProfile.scope) { // for business
            // NSMutableArray *businessSection = [[NSMutableArray alloc] init];

            if (self.serviceProfile.introduction) {
                RCPublicServiceProfilePlainCell *cell = [[RCPublicServiceProfilePlainCell alloc] init];

                [cell setTitle:RCLocalizedString(@"BusinessScope")
                       Content:self.serviceProfile.scope];
                [mainSection addObject:cell];
            }
        }

        if (self.serviceProfile.followed) { // for msg settings
            RCPublicServiceProfileRcvdMsgCell *cell = [[RCPublicServiceProfileRcvdMsgCell alloc] init];

            [cell setTitleText:RCLocalizedString(@"NewMessageNotification")];
            self.rcvdMsgCell = cell;
            cell.serviceProfile = self.serviceProfile;
            if (1) {
                __weak RCPublicServiceProfileViewController *weakSelf = self;
                [[RCIMClient sharedRCIMClient]
                    getConversationNotificationStatus:(RCConversationType)self.serviceProfile.publicServiceType
                    targetId:self.serviceProfile.publicServiceId
                    success:^(RCConversationNotificationStatus nStatus) {
                        BOOL enableNotification = NO;
                        if (nStatus == NOTIFY) {
                            enableNotification = YES;
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.rcvdMsgCell setOn:enableNotification];
                        });
                    }
                    error:^(RCErrorCode status){

                    }];
            }

            [mainSection addObject:cell];
        }

        if (self.serviceProfile.histroyMsgUrl) {
            RCPublicServiceProfileUrlCell *cell = [[RCPublicServiceProfileUrlCell alloc] init];

            [cell setTitle:RCLocalizedString(@"ViewHistory")
                       url:self.serviceProfile.histroyMsgUrl
                  delegate:self];
            [mainSection addObject:cell];
        }
        [collections addObject:mainSection];
        NSMutableArray *actionSection = [[NSMutableArray alloc] init];
        RCPublicServiceProfileActionCell *cell = [[RCPublicServiceProfileActionCell alloc] init];

        if (self.serviceProfile.followed || self.serviceProfile.isGlobal) {
            [cell setTitleText:RCLocalizedString(@"EnterOfficialAccount")
                andBackgroundColor:RGBCOLOR(83, 213, 105)];
        } else {
            [cell setTitleText:RCLocalizedString(@"Attention")
                andBackgroundColor:RGBCOLOR(83, 213, 105)];
        }
        __weak typeof(self) weakSelf = self;
        cell.onClickEvent = ^{
            if (weakSelf.serviceProfile.followed || weakSelf.serviceProfile.isGlobal) {
                [weakSelf enterPublicServiceConversation];
            } else {
                [weakSelf subscribePublicService];
            }
        };
        self.actionCell = cell;
        [actionSection addObject:cell];

        RCPublicServiceProfileActionCell *unSubscribeCell = [[RCPublicServiceProfileActionCell alloc] init];

        if (self.serviceProfile.followed && !self.serviceProfile.isGlobal) {
            [unSubscribeCell setTitleText:RCLocalizedString(@"Unfollow")
                       andBackgroundColor:RGBCOLOR(228, 54, 62)];
            unSubscribeCell.onClickEvent = ^{
                [weakSelf unsubscribePublicService];
            };
            [actionSection addObject:unSubscribeCell];
        }
        [collections addObject:actionSection];

        _cellCollections = collections;
    }
    return _cellCollections;
}

- (UIView *)getTableViewHeader {
    UIView *container = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, RCPublicServiceProfileHeaderPaddingTop +
                                                                       RCPublicServiceProfileHeaderImageHeigh +
                                                                       RCPublicServiceProfileHeaderPaddingBottom)];
    container.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                         darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];

    RCloudImageView *headerImageView = [[RCloudImageView alloc]
        initWithFrame:CGRectMake(RCPublicServiceProfileHeaderPaddingLeft, RCPublicServiceProfileHeaderPaddingTop,
                                 RCPublicServiceProfileHeaderImageWidth, RCPublicServiceProfileHeaderImageHeigh)];

    headerImageView.placeholderImage = RCResourceImage(@"default_portrait");
    [headerImageView setImageURL:[NSURL URLWithString:self.serviceProfile.portraitUrl]];
    headerImageView.layer.masksToBounds = YES;
    if (!self.portraitStyle) {
        headerImageView.layer.cornerRadius = 30;
    } else {
        if (_portraitStyle == RC_USER_AVATAR_RECTANGLE) {
            headerImageView.layer.cornerRadius = 4;
        } else if (_portraitStyle == RC_USER_AVATAR_CYCLE) {
            headerImageView.layer.cornerRadius = 30;
        }
    }

    CGFloat headlineFontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline].lineHeight;
    CGFloat midLineHeigh = RCPublicServiceProfileHeaderPaddingTop + RCPublicServiceProfileHeaderImageHeigh / 2;
    UILabel *nameLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(RCPublicServiceProfileHeaderPaddingLeft + RCPublicServiceProfileHeaderImageWidth +
                                     RCPublicServiceProfileCellPaddingLeft,
                                 midLineHeigh - headlineFontSize,
                                 self.tableView.frame.size.width - RCPublicServiceProfileHeaderPaddingLeft -
                                     RCPublicServiceProfileHeaderImageWidth,
                                 headlineFontSize)];

    nameLabel.numberOfLines = 1;
    nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    nameLabel.font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];
    nameLabel.textColor = [RCKitUtility generateDynamicColor:[UIColor blackColor] darkColor:HEXCOLOR(0x9f9f9f)];
    nameLabel.text = self.serviceProfile.name;

    CGFloat subheadlineFontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline].lineHeight;
    UILabel *userIdLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(RCPublicServiceProfileHeaderPaddingLeft + RCPublicServiceProfileHeaderImageWidth +
                                     RCPublicServiceProfileCellPaddingLeft,
                                 midLineHeigh + 5,
                                 self.tableView.frame.size.width - RCPublicServiceProfileHeaderPaddingLeft -
                                     RCPublicServiceProfileHeaderImageWidth,
                                 subheadlineFontSize)];
    userIdLabel.numberOfLines = 1;
    userIdLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    userIdLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    userIdLabel.text = [NSString stringWithFormat:RCLocalizedString(@"PublicNum"),
                                                  self.serviceProfile.publicServiceId];
    userIdLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
    userIdLabel.textColor = [RCKitUtility generateDynamicColor:[UIColor grayColor] darkColor:HEXCOLOR(0x707070)];

    [container addSubview:nameLabel];
    [container addSubview:userIdLabel];
    [container addSubview:headerImageView];

    return container;
}
- (void)subscribePublicService {
    __weak RCPublicServiceProfileViewController *weakSelf = self;

    [RCKitUtility showProgressViewFor:self.tableView
                                       text:RCLocalizedString(@"Wait")
                                   animated:YES];
    [[RCPublicServiceClient sharedPublicServiceClient] subscribePublicService:self.serviceProfile.publicServiceType
        publicServiceId:self.serviceProfile.publicServiceId
        success:^{
            if (!weakSelf.serviceProfile.followed) {
                weakSelf.serviceProfile.followed = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.serviceProfile = weakSelf.serviceProfile;
                    weakSelf.cellCollections = nil;
                    [weakSelf cellCollections];
                    [weakSelf.tableView reloadData];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [RCKitUtility hideProgressViewFor:weakSelf.tableView animated:YES];
            });
        }
        error:^(RCErrorCode status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [RCKitUtility hideProgressViewFor:weakSelf.tableView animated:YES];
            });
        }];
}
- (void)unsubscribePublicService {
    __weak RCPublicServiceProfileViewController *weakSelf = self;

    [RCKitUtility showProgressViewFor:self.tableView
                                       text:RCLocalizedString(@"Wait")
                                   animated:YES];

    [[RCPublicServiceClient sharedPublicServiceClient] unsubscribePublicService:self.serviceProfile.publicServiceType
        publicServiceId:self.serviceProfile.publicServiceId
        success:^{
            if (weakSelf.serviceProfile.followed) {
                weakSelf.serviceProfile.followed = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!weakSelf.serviceProfile.followed) {
                        NSUInteger count = weakSelf.navigationController.viewControllers.count;
                        if (count > 1) {
                            UIViewController *preVC = weakSelf.navigationController.viewControllers[count - 2];
                            if ([preVC isKindOfClass:[RCConversationViewController class]]) {
                                [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                                return;
                            }
                        }
                    }
                    weakSelf.serviceProfile = weakSelf.serviceProfile;
                    weakSelf.cellCollections = nil;
                    [weakSelf cellCollections];
                    [weakSelf.tableView reloadData];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [RCKitUtility hideProgressViewFor:weakSelf.tableView animated:YES];
            });
        }
        error:^(RCErrorCode status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [RCKitUtility hideProgressViewFor:weakSelf.tableView animated:YES];
            });
        }];
}

- (void)enterPublicServiceConversation {
    if (self.fromConversation) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        RCConversationViewController *vc = [[RCConversationViewController alloc]
            initWithConversationType:(RCConversationType)self.serviceProfile.publicServiceType
                            targetId:self.serviceProfile.publicServiceId];
        [self.navigationController pushViewController:vc animated:YES];
    }
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = self.cellCollections[section];
    return sections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sections = self.cellCollections[indexPath.section];
    UITableViewCell *cell = sections[indexPath.row];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    cell.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                    darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.cellCollections.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sections = self.cellCollections[indexPath.section];
    UITableViewCell *cell = sections[indexPath.row];
    if (cell.frame.size.height < 44)
        return 44;
    return cell.frame.size.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    return header;
}

#pragma mark - RCPublicServiceProfileViewUrlDelegate
- (void)gotoUrl:(NSString *)url {
    [RCKitUtility openURLInSafariViewOrWebView:url base:self];
}

@end
