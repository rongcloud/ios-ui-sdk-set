//
//  RCApplyFriendCellViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCApplyFriendCellViewModel.h"
#import "RCApplyFriendOperationCell.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCApplyFriendAlertView.h"
#import "RCAlertView.h"

NSInteger const RCFriendApplyCellHeight = 78;
@interface RCApplyFriendCellViewModel()
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong)  NSIndexPath *indexPath;
@property (nonatomic, assign) CGFloat cellHeightOfExpand;
@property (nonatomic, weak) UIViewController <RCListViewModelResponder> *responder;
@end

@implementation RCApplyFriendCellViewModel

- (instancetype)initWithApplicationInfo:(RCFriendApplicationInfo *)application
{
    self = [super init];
    if (self) {
        self.application = application;
    }
    return self;
}

- (BOOL)shouldHideExpandButton:(CGSize)size natureSize:(CGSize)natureSize {
    if (self.style == RCFriendApplyCellStyleFolder) {
        return NO;
    }
    if (self.style == RCFriendApplyCellStyleNone) {
        if (natureSize.height > size.height) {
            self.style = RCFriendApplyCellStyleFolder;
            self.cellHeightOfExpand = RCFriendApplyCellHeight-size.height+natureSize.height;
            return NO;
        } else {
            self.style = RCFriendApplyCellStyleNormal;
        }
    }
    return YES;
}

#pragma mark - RCCellViewModelProtocol
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.tableView = tableView;
    self.indexPath = indexPath;
    RCApplyFriendCell *cell = nil;
    if (self.application.applicationStatus == RCFriendApplicationStatusUnHandled &&
        self.application.applicationType == RCFriendApplicationTypeReceived ) {
        cell = [tableView dequeueReusableCellWithIdentifier:RCFriendApplyOperationCellIdentifier
                                                                           forIndexPath:indexPath];
        if (!cell) {
            cell = [[RCApplyFriendOperationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RCFriendApplyOperationCellIdentifier];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:RCFriendApplyCellIdentifier
                                                                  forIndexPath:indexPath];
        if (!cell) {
            cell = [[RCApplyFriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RCFriendApplyCellIdentifier];
        }
    }
    cell.hideSeparatorLine = self.hideSeparatorLine;
    [cell updateWithViewModel:self];
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
    
}
#pragma mark - Function
//- (void)deleteApplication:(void(^)(RCErrorCode errorCode))completion {
//    [[RCCoreClient sharedCoreClient] deleteFriendApplication:self.application.userId type:self.application.applicationType success:^{
//        if (completion) {
//            completion(RC_SUCCESS);
//        }
//    } error:^(RCErrorCode errorCode) {
//        if (completion) {
//            completion(errorCode);
//        }
//    }];
//}


- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
                                    completion:(void(^)(RCErrorCode errorCode))completion {
    /* 一期暂时去掉
    UITableViewRowAction *actionDelete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:RCLocalizedString(@"Delete") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self deleteApplication:completion];
    }];
 
    return @[actionDelete];
     */
    return nil;
}


- (void)approveApplication {
    [[RCCoreClient sharedCoreClient] acceptFriendApplication:self.application.userId
                                                     success:^{
        self.application.applicationStatus = RCFriendApplicationStatusAccepted;
        [self reloadCell];
        } error:^(RCErrorCode errorCode) {
            [self showTips:RCLocalizedString(@"FriendApplicationAcceptFailed")];
        }];
}

- (void)showTips:(NSString *)tips {
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder showTips:tips];
        });
    }
}

- (void)rejectApplication {
    [self showRefuseAlertView];
}

- (void)commitRefuse:(NSString *)reason {
    [[RCCoreClient sharedCoreClient] refuseFriendApplication:self.application.userId success:^{
        self.application.applicationStatus = RCFriendApplicationStatusRefused;
        [self reloadCell];
    } error:^(RCErrorCode errorCode) {
        [self showTips:RCLocalizedString(@"FriendApplicationRefuseFailed")];
    }];
}

- (void)showRefuseAlertView {
    [RCAlertView showAlertController:nil message:[NSString stringWithFormat:@"%@?", RCLocalizedString(@"FriendApplayRefuseTitle")] actionTitles:nil cancelTitle:RCLocalizedString(@"Cancel") confirmTitle:RCLocalizedString(@"Confirm") preferredStyle:UIAlertControllerStyleAlert actionsBlock:nil cancelBlock:^{
    } confirmBlock:^{
        [self commitRefuse:@""];  
    } inViewController:self.responder];
    
//    [RCApplyFriendAlertView showAlert:RCLocalizedString(@"FriendApplayRefuseTitle")
//                          placeholder:RCLocalizedString(@"FriendApplayRefusePlaceholder")
//                          lengthLimit:64
//                           completion:^(NSString * text) {
//        [self commitRefuse:text];
//    }];
}

- (void)expandRemark {
    self.style = RCFriendApplyCellStyleExpand;
    [self reloadCell];
}

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCApplyFriendCell class]
      forCellReuseIdentifier:RCFriendApplyCellIdentifier];
    [tableView registerClass:[RCApplyFriendOperationCell class]
      forCellReuseIdentifier:RCFriendApplyOperationCellIdentifier];
}

- (CGFloat)cellHeight {
    if (self.style != RCFriendApplyCellStyleExpand) {
        return RCFriendApplyCellHeight;
    } else {
        return self.cellHeightOfExpand;
    }
}

- (void)bindResponder:(UIViewController <RCListViewModelResponder>*)responder {
    self.responder = responder;
}
#pragma mark - Private

- (void)setApplication:(RCFriendApplicationInfo *)application {
    _application = application;
    if (_application.extra.length == 0) {
        _application.extra = RCLocalizedString(@"FriendApplicationDefaultExtra");
    }
}

- (void)reloadCell {
    if (self.indexPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadRowsAtIndexPaths:@[self.indexPath] withRowAnimation:UITableViewRowAnimationFade];
        });
    }
}
@end
