//
//  RosterViewController.m
//  XmppChart
//
//  Created by classjing on 14-4-2.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "RosterViewController.h"
#import <CoreData/CoreData.h>
#import "ChatViewController.h"
#import "AppDelegate.h"
#import "LoginUser.h"
@interface RosterViewController ()<NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *_fetchedResultsController;
    XMPPJID                     *_toRemovedJID;
}

@end

@implementation RosterViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

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
// 指定分组的内容
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info = _fetchedResultsController.sections[section];
    
    // [info name]对应的是sectionNum的字段内容文本
    int state = [[info name] intValue];
    
    NSString *title = nil;
    switch (state) {
        case 0:
            title = @"在线";
            break;
        case 1:
            title = @"离开";
            break;
        case 2:
            title = @"离线";
            break;
        default:
            title = @"未知";
            break;
    }
    
    return title;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RosterCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    XMPPUserCoreDataStorageObject *user = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = user.displayName;
    
    // 显示用户的实际状态
    cell.detailTextLabel.text = user.primaryResource.status;
    
    return cell;
}

#pragma mark 表格代理方法
#pragma mark 选中表格行
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"ChatSegue" sender:indexPath];
}
#pragma mark 提示，此方法一实现，即可删除
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 判断修改表格的方式，是否为删除
    if (UITableViewCellEditingStyleDelete == editingStyle) {
        // 要找出需要删除的用户jid，需要知道对应的行
        XMPPUserCoreDataStorageObject *user = [_fetchedResultsController objectAtIndexPath:indexPath];
        
        _toRemovedJID = user.jid;
        
        // 实际运行发现，有点小粗暴，最好提示一下用户
        NSString *msg = [NSString stringWithFormat:@"是否确认删除%@?", user.jidStr];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        
        [alertView show];
    }
}

#pragma mark - AlertView的代理方法
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // 在64位的平台上开发时的注意：NSInteger
    // 在参数返回或者传递时，尽量用NSInteger，这样可以保证不同平台的数据传输准确
    // 提示：不要使用NSInteger类型去拼接字符串，在拼接字符串的时候，最好使用int
    if (1 == buttonIndex) {
        [xmppDelegate.xmppRoster removeUser:_toRemovedJID];
        
        // 注意清理_toRemovedJID
        _toRemovedJID = nil;
        // 提示：indexPathForSelectedRow方法对表格的编辑操作无效
        //        [self.tableView indexPathForSelectedRow]
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
