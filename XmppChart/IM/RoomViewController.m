//
//  RoomViewController.m
//  XmppChart
//
//  Created by classjing on 14-4-11.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "RoomViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "ChatViewController.h"
@interface RoomViewController ()<NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *_fetchedResultsController;

}

@end

@implementation RoomViewController



- (void)viewDidLoad
{
    [super viewDidLoad];

//    18612318135 丰台区马家堡动力9号，北京联通客服呼叫中心 982
//    18612318913
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self loadData];
}

-(void)loadData
{
    //1.获取花名册上下文
    NSManagedObjectContext *context = xmppDelegate.xmppRoomCoreDataStorage.mainThreadManagedObjectContext;
    //2.查询请求
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPRoomOccupantCoreDataStorageObject"];
    
    
    
    
    
    
    //3.排序
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
    
    request.sortDescriptors = @[sort];
    
//    // 4. 需要过滤查询条件，谓词，过滤当前对话双发的聊天记录，将“lisi”的聊天内容取出来
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"roomJIDStr = %@", @"chat@conference.zhengjing.local"];
//    [request setPredicate:predicate];

    
    //4.实例化查询控制器
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> info = _fetchedResultsController.sections[section];
    return [info numberOfObjects];;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    XMPPRoomOccupantCoreDataStorageObject *message = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text =message.roomJIDStr;
   // NSLog(@"%@",message.nickname);
    // Configure the cell...
    //cell.textLabel.text = @"xxx";
    return cell;
}
#pragma mark 表格代理方法

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    
    [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
    
    if ([identifier isEqualToString:@"ChatSegue"]) {
        // 将选中用户的jid传递给聊天视图控制器，以便提取聊天记录
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        XMPPRoomOccupantCoreDataStorageObject *user = [_fetchedResultsController objectAtIndexPath:indexPath];
        
        ChatViewController *controller = segue.destinationViewController;
        controller.bareJID = user.jid;
        //controller.bareImage = user.photo;
        // 取出对话方的头像数据
        NSData *barePhoto = [[xmppDelegate xmppvCardAvatarModule] photoDataForJID:user.jid];
        if (barePhoto) {
            controller.bareImage = [UIImage imageWithData:barePhoto];
        } else {
            controller.bareImage = [UIImage imageNamed:@"DefaultProfileHead"];
        }
                
        NSData *myPhoto = [[xmppDelegate xmppvCardAvatarModule] photoDataForJID:xmppDelegate.xmppStream.myJID];
        controller.myImage = [UIImage imageWithData:myPhoto];
    }
}
#pragma mark 选中表格行
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self performSegueWithIdentifier:@"ChatSegue" sender:indexPath];
}


//#pragma mark 提示，此方法一实现，即可删除
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // 判断修改表格的方式，是否为删除
//    if (UITableViewCellEditingStyleDelete == editingStyle) {
//        // 要找出需要删除的用户jid，需要知道对应的行
//        XMPPUserCoreDataStorageObject *user = [_fetchedResultsController objectAtIndexPath:indexPath];
//        
//        _toRemovedJID = user.jid;
//        
//        // 实际运行发现，有点小粗暴，最好提示一下用户
//        NSString *msg = [NSString stringWithFormat:@"是否确认删除%@?", user.jidStr];
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
//        
//        [alertView show];
//    }
//}


//新人加入群聊
- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}
//有人退出群聊
- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}
//有人在群里发言
- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
