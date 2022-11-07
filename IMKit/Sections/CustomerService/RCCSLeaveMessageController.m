//
//  RCCSLeaveMessageController.h
//  RongIMKit
//
//  Created by 张改红 on 2016/12/5.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCCSLeaveMessageController.h"
#import "RCCSLeaveMessagesCell.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"
#import "RCAlertView.h"
#import <RongCustomerService/RongCustomerService.h>
#import "RCSemanticContext.h"

@interface RCCSLeaveMessageController ()
@property (nonatomic, strong) NSMutableDictionary *leaveMessageInfoDic;
@end

@implementation RCCSLeaveMessageController

#pragma mark – Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.leaveMessageInfoDic = [NSMutableDictionary dictionary];
    self.title = @"留言";
    [self setBackAction];
    [self setupTableHeaderView];
    [self setupTableFooterView];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 10, 0, 0);
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        self.tableView.layoutMargins = UIEdgeInsetsMake(0, 10, 0, 0);
    }
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.leaveMessageConfig.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCCSLeaveMessagesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"leaveMessages"];
    if (!cell) {
        cell =
            [[RCCSLeaveMessagesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"leaveMessages"];
    }
    RCCSLeaveMessageItem *item = self.leaveMessageConfig[indexPath.row];
    [cell setDataWithModel:item indexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    __weak typeof(self) weakSelf = self;
    [cell setLeaveMessageInfomation:^(NSDictionary *info) {
        [weakSelf.leaveMessageInfoDic setValuesForKeysWithDictionary:info];
    }];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCCSLeaveMessageItem *item = self.leaveMessageConfig[indexPath.row];
    if ([item.type isEqualToString:@"textarea"]) {
        return 125;
    }
    return 43;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 15;
}

#pragma mark – Private Methods

- (void)setBackAction {
    UIImage *imgMirror = RCResourceImage(@"navigator_btn_back");
    imgMirror = [RCSemanticContext imageflippedForRTL:imgMirror];
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:RCLocalizedString(@"Back") target:self action:@selector(cancelAction)];
}

- (void)cancelAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setupTableHeaderView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    view.backgroundColor = HEXCOLOR(0xf0f0f6);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width, 30)];
    label.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
    label.textColor = HEXCOLOR(0x999999);
    label.text = @"请您留言，我们会尽快回复您。";
    [view addSubview:label];
    self.tableView.tableHeaderView = view;
}

- (void)setupTableFooterView {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 43)];
    UIButton *submitButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 20, 43)];
    submitButton.center = footerView.center;
    [submitButton setTitle:@"提交留言" forState:UIControlStateNormal];
    [submitButton setBackgroundImage:RCResourceImage(@"blue") forState:UIControlStateNormal];
    [submitButton setBackgroundImage:RCResourceImage(@"blue－hover") forState:UIControlStateHighlighted];
    [footerView addSubview:submitButton];
    [submitButton addTarget:self action:@selector(submitSuggestAction) forControlEvents:UIControlEventTouchUpInside];
    self.tableView.tableFooterView = footerView;
}

- (void)submitSuggestAction {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (int i = 0; i < self.leaveMessageConfig.count; i++) {
        RCCSLeaveMessageItem *item = self.leaveMessageConfig[i];
        NSString *infoString = self.leaveMessageInfoDic[item.name];
        for (int j = 0; j < item.message.count; j++) {
            if (j == 0 && item.required) {
                if (infoString.length == 0) {
                    //不能为空
                    [self showAlertView:item.message[j]];
                    return;
                }
            } else if (j == 1) {
                if (infoString.length > 0 && item.verification && [item.verification isEqualToString:@"phone"]) {
                    if (![self validateCellPhoneNumber:infoString]) {
                        //手机格式不正确
                        [self showAlertView:item.message[j]];
                        return;
                    }
                } else if (infoString.length > 0 && item.verification && [item.verification isEqualToString:@"email"]) {
                    if (![self validateEmail:infoString]) {
                        //邮箱格式不正确
                        [self showAlertView:item.message[j]];
                        return;
                    }
                }
            } else if (j == 2) {
                if ([item.type isEqualToString:@"textarea"]) {
                    if (infoString.length > item.max) {
                        [self showAlertView:item.message[j]];
                        return;
                    }
                }
            }
        }
        if (infoString.length > 0) {
            [dic setObject:infoString forKey:item.name];
        }
    }

    __weak typeof(self) weakSelf = self;
    [[RCCustomerServiceClient sharedCustomerServiceClient] leaveMessageCustomerService:self.targetId
        leaveMessageDic:dic
        success:^{
            weakSelf.leaveMessageSuccess();
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            });
        }
        failure:^{

        }];
}

- (void)showAlertView:(NSString *)str {
    [RCAlertView showAlertController:nil message:str cancelTitle:RCLocalizedString(@"OK") inViewController:self];
}

- (BOOL)validateCellPhoneNumber:(NSString *)cellNum {
    /**
     * 手机号码
     * 移动：134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     * 联通：130,131,132,152,155,156,185,186
     * 电信：133,1349,153,180,189
     */
    NSString *MOBILE = @"^1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$";

    /**
     10         * 中国移动：China Mobile
     11         * 134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     12         */
    NSString *CM = @"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d)\\d{7}$";

    /**
     15         * 中国联通：China Unicom
     16         * 130,131,132,152,155,156,185,186
     17         */
    NSString *CU = @"^1(3[0-2]|5[256]|8[56])\\d{8}$";

    /**
     20         * 中国电信：China Telecom
     21         * 133,1349,153,177,180,189
     22         */
    NSString *CT = @"^1((33|53|77|8[09])[0-9]|349)\\d{7}$";

    /**
     25         * 大陆地区固话及小灵通
     26         * 区号：010,020,021,022,023,024,025,027,028,029
     27         * 号码：七位或八位
     28         */
    // NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";

    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];

    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];

    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];

    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    // NSPredicate *regextestPHS = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", PHS];

    if (([regextestmobile evaluateWithObject:cellNum] == YES) || ([regextestcm evaluateWithObject:cellNum] == YES) ||
        ([regextestct evaluateWithObject:cellNum] == YES) || ([regextestcu evaluateWithObject:cellNum] == YES)) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)validateEmail:(NSString *)email {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}
@end
