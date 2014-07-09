//
//  RosterViewController.m
//  XmppChart
//
//  Created by classjing on 14-4-2.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "AddRoomChatViewController.h"
#import <CoreData/CoreData.h>
#import "ChatViewController.h"
#import "AppDelegate.h"
#import "LoginUser.h"
#import "AddRoomRosterCell.h"

@interface AddRoomChatViewController ()<NSFetchedResultsControllerDelegate,XMPPRoomDelegate>
{
    NSFetchedResultsController *_fetchedResultsController;
    XMPPJID                     *_toRemovedJID;
    NSMutableArray *_userList;//存放选中添加用户的数组
    XMPPRoom *_xmppRoom;
}

@end

@implementation AddRoomChatViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    //初始化数组
    _userList = [NSMutableArray array];
    
    
    [self loadData];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    
    [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
    
    if ([identifier isEqualToString:@"ChatSegue"]) {
        // 将选中用户的jid传递给聊天视图控制器，以便提取聊天记录
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        XMPPUserCoreDataStorageObject *user = [_fetchedResultsController objectAtIndexPath:indexPath];
        
        ChatViewController *controller = segue.destinationViewController;
        controller.bareJID = user.jid;
        controller.bareImage = user.photo;
        // 取出对话方的头像数据
        NSData *barePhoto = [[xmppDelegate xmppvCardAvatarModule] photoDataForJID:user.jid];
        controller.bareImage = [UIImage imageWithData:barePhoto];
        
        NSString *myStr = [LoginUser sharedLoginUser].myJIDName;
        XMPPJID *myJID = [XMPPJID jidWithString:myStr];
        NSData *myPhoto = [[xmppDelegate xmppvCardAvatarModule] photoDataForJID:myJID];
        controller.myImage = [UIImage imageWithData:myPhoto];
    }
}

-(void)loadData
{
    //1.获取花名册上下文
    NSManagedObjectContext *context = xmppDelegate.xmppRosterCoreDataStorage.mainThreadManagedObjectContext;
    //2.查询请求
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
    
    //3.排序
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    
    request.sortDescriptors = @[sort];
    
    //4.实例化查询控制器
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:@"sectionNum" cacheName:nil];
    //5.设置代理
    _fetchedResultsController.delegate = self;
    //6.控制器查询
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"%@",error);
    }
    
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

#pragma mark - 数据源方法
// 分组数量
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> info = _fetchedResultsController.sections[section];

    return [info numberOfObjects];;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AddRoomRosterCell";
    
    
    
    AddRoomRosterCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[AddRoomRosterCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
          }

    
    
    XMPPUserCoreDataStorageObject *user = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.userName.text = user.displayName;
    cell.userName.tag = indexPath.row +1;
    cell.statusBtn.tag = indexPath.row +10;
    // 显示用户的实际状态
   // cell.detailTextLabel.text = user.primaryResource.status;
    
    return cell;
}

#pragma mark 表格代理方法
#pragma mark 选中表格行
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIButton *status = (UIButton*)[tableView viewWithTag:(indexPath.row +10)];
     UILabel *userName = (UILabel*)[tableView viewWithTag:(indexPath.row +1)];
     status.selected = !status.selected;
    if (status.selected) {
        [status setBackgroundImage:[UIImage imageNamed:@"yes"] forState:UIControlStateSelected];
        
        [_userList addObject:userName.text];
        
       
        
    }else{
        [_userList removeObject:userName.text];
    }
    //判断被选中的用户是否大于0
    if (_userList.count>0) {
        
        NSString *count = [NSString stringWithFormat:@"确定(%d)",_userList.count];
        
        UIBarButtonItem *rightOk = [[UIBarButtonItem alloc] initWithTitle:count style:UIBarButtonItemStylePlain target:self action:@selector(okAction)];
        self.navigationItem.rightBarButtonItem = rightOk;
    }else{
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    NSLog(@"%@",_userList);
    
}
-(void)okAction
{
    NSLog(@"xxx");
    
    
    NSLog(@"%@------",[xmppDelegate.xmppRoomCoreDataStorage occupantEntityName]);
    
    //创建一个新的群聊房间,roomName是房间名 fullName是房间里自己所用的昵称
   
    XMPPJID *jid = [XMPPJID jidWithString:self.roomId];
    
    XMPPRoomCoreDataStorage *xmppRoomCoreDataStorage = [[XMPPRoomCoreDataStorage alloc] init];
    if (xmppRoomCoreDataStorage==nil) {
        NSLog(@"nil");
        xmppRoomCoreDataStorage = [[XMPPRoomCoreDataStorage alloc] init];
    }
    //
    
    _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:xmppRoomCoreDataStorage jid:jid dispatchQueue:dispatch_get_main_queue()];
    
    
    [_xmppRoom activate:xmppDelegate.xmppStream];
    
    
    
    [_xmppRoom joinRoomUsingNickname:xmppDelegate.xmppStream.myJID.user history:nil];
    
    
    [_xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppRoom configureRoomUsingOptions:nil];
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
	
    for (int i = 0; i<_userList.count; i++) {
        XMPPJID *jid = [XMPPJID jidWithString:_userList[i]];
        
        [sender inviteUser:jid withMessage:@"来吧,加个群"];
    }
    
    //[sender sendMessageWithBody:@"ssss"];
    [_xmppRoom fetchConfigurationForm];
    	[_xmppRoom fetchBanList];
    	[_xmppRoom fetchMembersList];
    	[_xmppRoom fetchModeratorsList];
    
    
}
- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm
{ NSXMLElement *newConfig = [configForm copy];
    NSArray* fields = [newConfig elementsForName:@"field"];
    for (NSXMLElement *field in fields){
        NSString *var = [field attributeStringValueForName:@"var"];
        if ([var isEqualToString:@"muc#roomconfig_persistentroom"])
        {
            [field removeChildAtIndex:0];
            [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
        }
    }
    [sender configureRoomUsingOptions:newConfig];
}
- (BOOL)configureWithParent:(XMPPRoom *)aParent queue:(dispatch_queue_t)queue
{
    
    return YES;
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
