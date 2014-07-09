//
//  ChatViewController.m
//  XmppChart
//
//  Created by classjing on 14-4-3.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "ChatViewController.h"
#import "ChatMessageCell.h"
#import "AFNetworking.h"
#import "SoundTool.h"
#import "AddRoomChatViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
@interface ChatViewController ()<UITableViewDataSource, NSFetchedResultsControllerDelegate, UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    // 查询结果控制器
    NSFetchedResultsController *_fetchResultsController;
    SoundTool *_soundTool;
    
    MBProgressHUD *_HUD;
    
}


// 输入视图的底部约束
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputViewConstraint;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *sendMsgButton;
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;


@end




@implementation ChatViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardStateChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    
    //将字符串切割成数组
//    NSArray *bareArr = [_bareJID.user componentsSeparatedByString:@"@"];
//    cell.textLabel.text = bareArr[0];
    self.title = _bareJID.user;
    
    // 绑定数据
    [self dataBinding];

    [self scrollToTableBottom];
    
    
    
    //判断是群聊天还是单聊
    NSRange range = [_bareJID.domain rangeOfString:@"conference"];
    //如果是群聊，右边加上添加好友进入群的功能
    if (range.location != NSNotFound) {
        UIBarButtonItem *addFriend = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFriendAction)];
        self.navigationItem.rightBarButtonItem = addFriend;
    }
    
}
/**
 *  如果是群群组聊天就可以去添加好用进入群
 */
-(void)addFriendAction
{
    AddRoomChatViewController *roster = [[AddRoomChatViewController alloc] init];
    
    NSString *roomId = [NSString stringWithFormat:@"%@@%@",_bareJID.user,_bareJID.domain];
    
    roster.roomId = roomId;
    
    [self.navigationController pushViewController:roster animated:YES];

}

#pragma mark - 文本框代理方法
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // 回车发送消息
    // 1. 检查是否有内容
    NSString *str = [textField.text trimString];
    
    if (str) {
        [self chat:str];
    }
   
    return YES;
}
#pragma mark 判断文本框是否有文字，然后显示影藏发送按钮
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // 1. 检查是否有内容
    if (string.length > 0) {
        _sendMsgButton.hidden = NO;
        //[_sendMsgButton setTitle:@"xianshi" forState:UIControlStateNormal];
    }else{
        _sendMsgButton.hidden = YES;
        //s [_sendMsgButton setTitle:@"ccc" forState:UIControlStateNormal];
    }
    
    return YES;
}

#pragma mark 发送消息
- (IBAction)sendMsgAction {
    
    NSString *str = [_inputTextField.text trimString];
    
    if (str) {
        [self chat:str];
    }
    
}


-(void)chat:(NSString*)str
{

    NSString *type = @"chat";
    //判断是群聊天还是单聊
    NSRange range = [_bareJID.domain rangeOfString:@"conference"];
    
    if (range.location != NSNotFound) {
        type = @"groupchat";
    }
    
    if (str.length > 0) {
        // 2. 实例化一个XMPPMessage（XML一个节点），发送出去即可
        XMPPMessage *message = [XMPPMessage messageWithType:type to:_bareJID];
        
        [message addBody:str];
        
        
        
        [xmppDelegate.xmppStream sendElement:message];
        
    }
    _inputTextField.text = @"";
    
    _sendMsgButton.hidden = YES;
}


#pragma mark - 绑定数据
- (void)dataBinding
{
    //判断是群聊天还是单聊
    NSRange range = [_bareJID.domain rangeOfString:@"conference"];
    
    if (range.location != NSNotFound) {
        //1.获取花名册上下文
        NSManagedObjectContext *context = xmppDelegate.xmppRoomCoreDataStorage.mainThreadManagedObjectContext;
        //2.查询请求
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPRoomMessageCoreDataStorageObject"];
 
        //3.排序
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"localTimestamp" ascending:YES];
        
        request.sortDescriptors = @[sort];
         NSString *roomJIDStr = [NSString stringWithFormat:@"%@@%@",_bareJID.user,_bareJID.domain];
        // 4. 需要过滤查询条件，谓词，过滤当前对话双发的聊天记录，将“lisi”的聊天内容取出来
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"roomJIDStr = %@", roomJIDStr];
        [request setPredicate:predicate];
        
        //4.实例化查询控制器
        
        _fetchResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        //5.设置代理
        _fetchResultsController.delegate = self;
        //6.控制器查询
        NSError *error = nil;
        if (![_fetchResultsController performFetch:&error]) {
            NSLog(@"%@",error);
        }
    }else{
        // 1. 数据库的上下文
        NSManagedObjectContext *context = xmppDelegate.xmppMessageArchivingCoreDataStorage.mainThreadManagedObjectContext;
        // 2. 定义查询请求
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];
        // 3. 定义排序
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
        [request setSortDescriptors:@[sort]];
        // 4. 需要过滤查询条件，谓词，过滤当前对话双发的聊天记录，将“lisi”的聊天内容取出来
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr = %@", _bareJID.bare];
        [request setPredicate:predicate];
        //4.实例化查询控制器
        _fetchResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        //5.设置代理
        _fetchResultsController.delegate = self;
        //6.控制器查询
        NSError *error = nil;
        if (![_fetchResultsController performFetch:&error]) {
            NSLog(@"%@",error);
        }
    }
}
#pragma mark - 键盘监听方法
- (void)keyboardStateChanged:(NSNotification *)notifcation
{
    // 通过跟踪发现使用UIKeyboardFrameEndUserInfoKey可以知道键盘的高度
    CGRect rect = [notifcation.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // 2. 根据rect的orgion.y可以判断键盘是开启还是关闭
    if (rect.origin.y == [UIScreen mainScreen].bounds.size.height) {
        // 关闭键盘
        _inputViewConstraint.constant = 0.0;
    } else {
        // 打开键盘
        _inputViewConstraint.constant = rect.size.height;
    }
    
    // 取出动画时长
    NSTimeInterval duration = [notifcation.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    // 在使用自动布局后，所有的对象位置都是由自动布局系统控制的
    // 程序员，不在需要指定控件的frame，如果需要动画，设定完属性之后，调用layoutIfNeeded即可。
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
    
    [self scrollToTableBottom];
}
#pragma mark - 查询结果控制器代理方法
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [_tableView reloadData];
    
    [self scrollToTableBottom];
}

#pragma mark - 数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info = _fetchResultsController.sections[section];
    return [info numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *FromID = @"ChatFromCell";
    static NSString *ToID = @"ChatToCell";
    
    NSString *CellIdentifier;
    
    ChatMessageCell *cell = nil;
    
    BOOL flag;
    
    //判断是群聊天还是单聊
    NSRange range = [_bareJID.domain rangeOfString:@"conference"];
    
    if (range.location != NSNotFound) {
        XMPPRoomMessageCoreDataStorageObject  *message = [_fetchResultsController objectAtIndexPath:indexPath];
        NSLog(@"----->%@",message.body);
        flag = message.isFromMe;
        if (flag) {
            CellIdentifier = FromID;
            if ([message.body hasPrefix:@"img:"]) {
                CellIdentifier = @"ImageChatFromCell";
                //MusicChatFromCell
            }
            if ([message.body hasPrefix:@"mp3:"]) {
                CellIdentifier = @"MusicChatFromCell";
                //MusicChatFromCell
            }
            
        } else {
            CellIdentifier = ToID;
            if ([message.body hasPrefix:@"img:"]) {
                CellIdentifier = @"ImageChatToCell";
                //MusicChatFromCell
            }
            if ([message.body hasPrefix:@"mp3:"]) {
                CellIdentifier = @"MusicChatToCell";
                //MusicChatFromCell
            }
        }
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setMessage:message.body isOutgoing:flag isImageTag:indexPath.row];
        
        if (flag) {
            cell.headImageView.image = self.myImage;
        } else {
            NSLog(@"%@---%@",message.nickname,xmppDelegate.xmppStream.myJID.domain);
            if ([message.message.type isEqual:@"groupchat"] || message.nickname) {
               // 聊天成员的头像
                XMPPJID *myJID = [XMPPJID jidWithUser:message.nickname domain:xmppDelegate.xmppStream.myJID.domain resource:nil];
             
                NSData *photoData = [xmppDelegate.xmppvCardAvatarModule photoDataForJID:myJID];
                
                if (photoData) {
                    cell.headImageView.image = [UIImage imageWithData:photoData];

                }else{
                    cell.headImageView.image = self.bareImage;
                }
                
            }
            
        }

    }else{
        XMPPMessageArchiving_Message_CoreDataObject *message = [_fetchResultsController objectAtIndexPath:indexPath];
         //NSLog(@"---%@",xmppDelegate.xmppStream.myJID.domain);
        flag = message.isOutgoing;
        if (flag) {
            CellIdentifier = FromID;
            if ([message.body hasPrefix:@"img:"]) {
                CellIdentifier = @"ImageChatFromCell";
                //MusicChatFromCell
            }
            if ([message.body hasPrefix:@"mp3:"]) {
                CellIdentifier = @"MusicChatFromCell";
                //MusicChatFromCell
            }
            
        } else {
            CellIdentifier = ToID;
            if ([message.body hasPrefix:@"img:"]) {
                CellIdentifier = @"ImageChatToCell";
                //MusicChatFromCell
            }
            if ([message.body hasPrefix:@"mp3:"]) {
                CellIdentifier = @"MusicChatToCell";
                //MusicChatFromCell
            }
        }

        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setMessage:message.body isOutgoing:flag isImageTag:indexPath.row];
        
        if (flag) {
            cell.headImageView.image = self.myImage;
        } else {
       
            cell.headImageView.image = self.bareImage;
        }
    }
    
    return cell;
}
#pragma mark - 滚动到表格的末尾
- (void)scrollToTableBottom
{
    // 让表格滚动到末尾
    // 计算出所有的数据行数，直接定位到最末一行即可
    id <NSFetchedResultsSectionInfo> info = _fetchResultsController.sections[0];
    // 所有记录行数
    NSInteger count = [info numberOfObjects];
    // 判断是否有数据
    if (count <= 0) {
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(count - 1) inSection:0];
    
    [_tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
}
#pragma mark 表格行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 提示，在此不能直接调用表格行控件的高度，否则会死循环
    // 1. 取出显示行的文本
    XMPPMessageArchiving_Message_CoreDataObject *message = [_fetchResultsController objectAtIndexPath:indexPath];
    NSString *str = message.body;
    
    // 2. 计算文本的占用空间
    CGSize size = [str sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(180, 10000.0)];
    
    //如果是图片的话，就显示图片高度，固定120
    //NSLog(@"----->%@",message.body);
    if ([message.body hasPrefix:@"img:"]) {
        return 120;
    }
    if ([message.body hasPrefix:@"mp3:"]) {
        return 60;
    }
    
    
    // 3. 根据文本空间计算行高
    if (size.height + 50.0 > 80.0) {
        return size.height + 50.0;
    }
   
    return 80;
}


#pragma mark - 添加照片
- (IBAction)addPhoto {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark UIImagePickerController代理方法
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 提示：UIImage不能为空
    // NSData *data = UIImagePNGRepresentation(self.imageView.image);
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSData *data = UIImagePNGRepresentation(image);
   
    // 1) 使用系统时间生成一个文件名
    NSString *sysTime = [@"" appendDateTime];
    
     NSString *fileName = [sysTime appendStr:@".png"];
    // 将图像数据写入沙盒，在消息中，还需要记录沙盒的存放路径
    // 所谓baseURL就是此后所有的请求都基于此地址
   
    
    NSURL *url = [NSURL URLWithString:kFileServerURL];
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:url];
    
    // 2. 根据httpClient生成post请求
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/upload.php" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data name:@"file" fileName:fileName mimeType:@"image/png"];
    }];
    // 准备做上传的工作！
    // 3. operation
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
      
        
        NSString *uploadPath = [[kFileServerURL appendStr:@"/upload/"] appendStr:fileName];
        NSString *msg = [@"img:" appendStr:uploadPath];
        [self chat:msg];
        
        [_inputTextField resignFirstResponder];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"上传文件失败 %@", error);
    }];
    
    // 4. operation start
    [op start];
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - 语音聊天操作
#pragma mark 开始录影
- (IBAction)startRecord:(UIButton*)sender {
    [sender setTitle:@"松开结束" forState:UIControlStateHighlighted];
    _soundTool = [[SoundTool alloc] init];
    [_soundTool startRecord];
    
}

- (IBAction)stopRecord {
    [_soundTool stopRecord];
    //判断录音时间是否太短
    if (_soundTool.currentTime < 1.0 ) {
        _HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.navigationController.view addSubview:_HUD];
        _HUD.labelText = @"录音时间太短！";
        [_HUD show:YES];
        [_HUD hide:YES afterDelay:0.3];
        return;
    }
    NSString *mp3Path =  [_soundTool mp3Path];
    
   
    NSURL *fileUrl = [NSURL fileURLWithPath:mp3Path isDirectory:YES];
  
    NSURL *url = [NSURL URLWithString:kFileServerURL];
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:url];
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/upload.php" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:fileUrl name:@"file" error:nil];

    }];
    // 准备做上传的工作！
    // 3. operation
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        //时长
        NSString *soundTime = [NSString stringWithFormat:@"%.0f",_soundTool.currentTime];
        NSString *uploadPath = [NSString stringWithFormat:@"%@/upload/%@?%@",kFileServerURL,[[SoundTool sharedSoundTool] fileName],soundTime];
//        // 发送消息给好友，通知发送了图像
          // 设置消息的正文
        NSString *msg = [NSString stringWithFormat:@"mp3:%@", uploadPath];
        [self chat:msg];
   
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"1上传文件失败 %@", error);
    }];
    // 4. operation start
    [op start];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
