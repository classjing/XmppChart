//
//  AddRoomViewController.m
//  XmppChart
//
//  Created by classjing on 14-4-11.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "CreateRoomViewController.h"
#import "AppDelegate.h"
#import "NSString+Helper.h"
@interface CreateRoomViewController ()<UITextFieldDelegate,XMPPRoomDelegate,UIAlertViewDelegate>
{
    XMPPRoom *xmppRoom;
}
@property (weak, nonatomic) IBOutlet UITextField *contentTextFild;

@end

@implementation CreateRoomViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    NSString *text = [textField.text trimString];
    
    //创建一个新的群聊房间,roomName是房间名 fullName是房间里自己所用的昵称
    NSString *jidRoom = [NSString stringWithFormat:@"%@@conference.zhengjing.local",text];
    XMPPJID *jid = [XMPPJID jidWithString:jidRoom];
    
    //XMPPRoomCoreDataStorage *xmppRoomCoreDataStorage = [[XMPPRoomCoreDataStorage alloc] init];
    if (xmppDelegate.xmppRoomCoreDataStorage==nil) {
        NSLog(@"nil");
      //  xmppDelegate.xmppRoomCoreDataStorage = [[XMPPRoomCoreDataStorage alloc] init];
    }
    //
    
    xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:xmppDelegate.xmppRoomCoreDataStorage jid:jid dispatchQueue:dispatch_get_main_queue()];
    
    
    [xmppRoom activate:xmppDelegate.xmppStream];
    
    
    
    [xmppRoom joinRoomUsingNickname:xmppDelegate.xmppStream.myJID.user history:nil];
    
    
    [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    
    
    return YES;
}
- (BOOL)configureWithParent:(XMPPRoom *)aParent queue:(dispatch_queue_t)queue;

{
    
    return YES;
}
- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    //[self sendDefaultRoomConfig];
	DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
    
}
//
- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
	DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    ///XMPPJID *jid = [XMPPJID jidWithString:@"wangwu@zhengjing.local"];
    
	//[sender inviteUser:jid withMessage:@"来吧,加个群"];
	
    
    
    //[sender sendMessageWithBody:@"ssss"];
    [xmppRoom fetchConfigurationForm];
    //	[_xmppRoom fetchBanList];
    //	[_xmppRoom fetchMembersList];
    //	[_xmppRoom fetchModeratorsList];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"创建群成功" message:@"创建群成功" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    
    [alert show];
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%d",buttonIndex);
    if (buttonIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm
{ NSXMLElement *newConfig = [configForm copy];
#pragma mark 配置房间为永久房间
    
        NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
        
        NSXMLElement *field = [NSXMLElement elementWithName:@"field"];
        NSXMLElement *value = [NSXMLElement elementWithName:@"value"];
        
        NSXMLElement *fieldowners = [NSXMLElement elementWithName:@"field"];
        NSXMLElement *valueowners = [NSXMLElement elementWithName:@"value"];
        
        
        [field addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];  // 永久属性
        [fieldowners addAttributeWithName:@"var" stringValue:@"muc#roomconfig_roomowners"];  // 谁创建的房间
        
        
        [field addAttributeWithName:@"type" stringValue:@"boolean"];
        [fieldowners addAttributeWithName:@"type" stringValue:@"jid-multi"];
        
        [value setStringValue:@"1"];
        [valueowners setStringValue:xmppDelegate.xmppStream.myJID.user]; //创建者的Jid
        
        [x addChild:field];
        [x addChild:fieldowners];
        [field addChild:value];
        [fieldowners addChild:valueowners];
    
    [sender configureRoomUsingOptions:newConfig];
}





//是否已经离开
-(void)xmppRoomDidLeave:(XMPPRoom *)sender{
    NSLog(@"xmppRoomDidLeave");
}

//收到群聊消息
-(void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID{
    NSLog(@"xmppRoom:didReceiveMessage:fromOccupant:");
    //    NSLog(@"%@,%@,%@",occupantJID.user,occupantJID.domain,occupantJID.resource);
    NSString *msg = [[message elementForName:@"body"] stringValue];
    NSString *from = [[message attributeForName:@"from"] stringValue];
    
    if (![[sender myNickname] isEqualToString:occupantJID.resource]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        if (msg !=nil) {
            [dict setObject:msg forKey:@"msg"];
            //            [dict setObject:from forKey:@"sender"];
            if (occupantJID.resource) {
                [dict setObject:occupantJID.resource forKey:@"sender"];
            }else{
                [dict setObject:from forKey:@"sender"];
            }
            
        }
    }
}

//房间人员加入
- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    NSLog(@"occupantDidJoin");
    NSString *jid = occupantJID.user;
    NSString *domain = occupantJID.domain;
    NSString *resource = occupantJID.resource;
    NSString *presenceType = [presence type];
    NSString *userId = [sender myRoomJID].user;
    NSString *presenceFromUser = [[presence from] user];
    
    NSLog(@"occupantDidJoin----jid=%@,domain=%@,resource=%@,当前用户:%@ ,出席用户:%@,presenceType:%@",jid,domain,resource,userId,presenceFromUser,presenceType);
    
    if (![presenceFromUser isEqualToString:userId]) {
        //对收到的用户的在线状态的判断在线状态
        
        //在线用户
        if ([presenceType isEqualToString:@"available"]) {
//            NSString *buddy = [[NSString stringWithFormat:@"%@@%@", presenceFromUser, @"192.168.1.177"] retain];
            //            [chatDelegate newBuddyOnline:buddy];//用户列表委托
        }
        
        //用户下线
        else if ([presenceType isEqualToString:@"unavailable"]) {
            //            [chatDelegate buddyWentOffline:[NSString stringWithFormat:@"%@@%@", presenceFromUser, OpenFireHostName]];//用户列表委托
        }
    }
}

//房间人员离开
-(void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    NSString *jid = occupantJID.user;
    NSString *domain = occupantJID.domain;
    NSString *resource = occupantJID.resource;
    NSString *presenceType = [presence type];
    NSString *userId = [sender myRoomJID].user;
    NSString *presenceFromUser = [[presence from] user];
    NSLog(@"occupantDidLeave----jid=%@,domain=%@,resource=%@,当前用户:%@ ,出席用户:%@,presenceType:%@",jid,domain,resource,userId,presenceFromUser,presenceType);
}

//房间人员加入
-(void)xmppRoom:(XMPPRoom *)sender occupantDidUpdate:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    NSString *jid = occupantJID.user;
    NSString *domain = occupantJID.domain;
    NSString *resource = occupantJID.resource;
    NSString *presenceType = [presence type];
    NSString *userId = [sender myRoomJID].user;
    NSString *presenceFromUser = [[presence from] user];
    NSLog(@"occupantDidUpdate----jid=%@,domain=%@,resource=%@,当前用户:%@ ,出席用户:%@,presenceType:%@",jid,domain,resource,userId,presenceFromUser,presenceType);
}

@end
