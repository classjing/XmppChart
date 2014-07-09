//
//  ChatViewController.h
//  XmppChart
//
//  Created by classjing on 14-4-3.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
@interface ChatViewController : UIViewController
// 聊天的好友JID
@property (nonatomic, strong) XMPPJID *bareJID;

// 对话方头像
@property (strong, nonatomic) UIImage *bareImage;
// 我的头像
@property (strong, nonatomic) UIImage *myImage;

@end
