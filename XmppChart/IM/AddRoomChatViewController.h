//
//  AddRoomChatViewController.h
//  XmppChart
//
//  Created by classjing on 14-4-16.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddRoomChatViewController : UITableViewController

@property(nonatomic,strong) NSString *roomId;//群聊的Id ，群聊加好友的时候跳过来接收数据
@end
