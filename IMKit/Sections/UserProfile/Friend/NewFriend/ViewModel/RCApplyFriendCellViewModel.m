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

NSInteger const RCFriendApplyCellHeight = 56;
@interface RCApplyFriendCellViewModel()
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong)  NSIndexPath *indexPath;
@property (nonatomic, strong) UILabel *labSlaver;
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

- (void)configureFolderRemarkSize:(CGSize)size {
    if (self.style == RCFriendApplyCellStyleNone) {
        self.labSlaver.bounds = CGRectMake(0, 0, size.width, size.height);
        self.labSlaver.text = self.application.extra;
        self.labSlaver.numberOfLines = 0;
        [self.labSlaver sizeToFit];
        if (self.labSlaver.bounds.size.width > size.width || self.labSlaver.bounds.size.height > size.height) {
            self.style = RCFriendApplyCellStyleFolder;
        } else {
            self.style = RCFriendApplyCellStyleNormal;
        }
    }
}

- (void)configureExpandRemarkSize:(CGSize)size {
    // 折叠状态 才可以计算展开的高度
    if (self.style == RCFriendApplyCellStyleFolder) {
        if (self.cellHeightOfExpand == 0) {
            self.labSlaver.bounds = CGRectMake(0, 0, size.width, 10000);
            self.labSlaver.text = self.application.extra;
            self.labSlaver.numberOfLines = 0;
            [self.labSlaver sizeToFit];
            self.cellHeightOfExpand = RCFriendApplyCellHeight-size.height+self.labSlaver.frame.size.height;
        }
    }
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
            [self.tableView setNeedsLayout];
            [self.tableView layoutIfNeeded];
        });
    }
}

- (UILabel *)labSlaver {
    if (!_labSlaver) {
        UILabel *lab = [UILabel new];
        lab.font = [UIFont systemFontOfSize:14];
        _labSlaver= lab;
    }
    return _labSlaver;
}
@end
