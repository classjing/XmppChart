//
//  MainViewController.m
//  XmppChart
//
//  Created by classjing on 14-4-8.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "MainViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "ChatViewController.h"
@interface MainViewController ()<NSFetchedResultsControllerDelegate>
{
    // 查询结果控制器
    NSFetchedResultsController  *_fetchedResultsController;
}

@end

@implementation MainViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tabBarController.tabBarItem.badgeValue = @"3";

    // Uncomment the following line to preserve selection between presentations.
    
    [self setupFetchedResultsController];
}
#pragma mark - 设置查询结果控制器
- (void)setupFetchedResultsController
{
    // 1. 上下文对象，在使用CoreData时，上下文对象要在主线程中实例化
    // 因为针对数据的增删查改操作通常会与界面UI绑定
    NSManagedObjectContext *context = [[xmppDelegate xmppMessageArchivingCoreDataStorage] mainThreadManagedObjectContext];
    
    // 2. 定义查询请求
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageArchiving_Contact_CoreDataObject"];
    
    // 3. 定义排序，最后一次聊天记录显示在表格的第一行
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"mostRecentMessageTimestamp" ascending:NO];
    [request setSortDescriptors:@[sort]];
    
    // 4. 实例化查询结果控制器
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    
    // 5. 设置控制器代理，以便内容变化时刷新表格数据
    [_fetchedResultsController setDelegate:self];
    
    // 6. 执行查询
    NSError *error = nil;
    if ([_fetchedResultsController performFetch:&error]) {
        NSLog(@"查询数据出错 - %@", error.localizedDescription);
    }
}
#pragma mark 查询结果控制器代理
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // 刷新表格数据
    [self.tableView reloadData];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

#pragma mark - 数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info = _fetchedResultsController.sections[section];
    NSLog(@"%d",[info numberOfObjects]);
    return [info numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"ContactCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID forIndexPath:indexPath];
    
    // 设置单元格
    // 1. 取出当前行对应的联系人记录
    XMPPMessageArchiving_Contact_CoreDataObject *contact = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    // 设置头像
    NSData *photoData = [[xmppDelegate xmppvCardAvatarModule] photoDataForJID:contact.bareJid];
    
    if (photoData) {
        cell.imageView.image = [UIImage imageWithData:photoData];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"DefaultProfileHead"];
    }
    
    // 设置用户账号名
    //将字符串切割成数组
    NSArray *bareArr = [contact.bareJidStr componentsSeparatedByString:@"@"];
    cell.textLabel.text = bareArr[0];
  
    // 最近聊天内容
    if ([contact.mostRecentMessageBody hasPrefix:@"img:"]) {
       cell.detailTextLabel.text = @"[图片]";
    }else if ([contact.mostRecentMessageBody hasPrefix:@"mp3:"]){
        cell.detailTextLabel.text = @"[语音]";
    }else{
        cell.detailTextLabel.text = contact.mostRecentMessageBody;
    }
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"ChatSegue" sender:indexPath];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath
{
    ChatViewController *controller = segue.destinationViewController;
    
    // 设置聊天视图控制器的属性
    // 0. 取出联系人
    XMPPMessageArchiving_Contact_CoreDataObject *contact = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    // 1. 账号
    controller.bareJID = contact.bareJid;
    
    // 2. 头像
    // 设置头像
    NSData *photoData = [[xmppDelegate xmppvCardAvatarModule] photoDataForJID:contact.bareJid];
    
    if (photoData) {
        controller.bareImage = [UIImage imageWithData:photoData];
    } else {
        controller.bareImage = [UIImage imageNamed:@"DefaultProfileHead"];
    }
    
    
    // 3. 我的头像
    XMPPJID *myJID = [[xmppDelegate xmppStream] myJID];
    NSData *myPhotoData = [[xmppDelegate xmppvCardAvatarModule] photoDataForJID:myJID];
    
    controller.myImage = [UIImage imageWithData:myPhotoData];
}
@end
