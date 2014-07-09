//
//  VCardViewController.m
//  XmppChart
//
//  Created by classjing on 14-4-2.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "VCardViewController.h"
#import "AppDelegate.h"
#import "XMPPvCardTemp.h"
#import "EditVCardViewController.h"
@interface VCardViewController ()<UIActionSheetDelegate,EditVCardViewContrllerDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *headerImagerView;
@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *JidLabel;
@property (weak, nonatomic) IBOutlet UILabel *orgNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *orgUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *telLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@end

@implementation VCardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //加载名片数据
    [self loadCard];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell*)cell
{
    EditVCardViewController *editContrller = segue.destinationViewController;
    
    [cell.contentView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
       
        
        if ([obj isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel*)obj;
            if (label.tag == 1) {
                NSLog(@"%@",label.text);
                editContrller.contentTitle = label.text;
            }else{
                editContrller.contentLabel = label;
            }
        }
        
        
    }];
    editContrller.delegate = self;
    
}
#pragma mark 编辑视图控制器代理方法
-(void)editVCardControllerDidFinished
{
   [self savevCard];
    
}

-(void)savevCard
{
    XMPPvCardTemp *myCard = [xmppDelegate xmppvCardTempModule].myvCardTemp;
    
    myCard.photo = UIImagePNGRepresentation(_headerImagerView.image);
    myCard.nickname = _nickNameLabel.text;
    myCard.orgName = _orgNameLabel.text;
    
    DDLogCInfo(@"%@",_orgUnitLabel.text);
    
    myCard.orgUnits = @[_orgUnitLabel.text]?@[_orgUnitLabel.text]:nil;
    myCard.title = _titleLabel.text;
    myCard.note = _telLabel.text;
    myCard.mailer = _emailLabel.text;
    
    // 保存名片
    [[xmppDelegate xmppvCardTempModule] updateMyvCardTemp:myCard];
    
}



#pragma mark 退出
- (IBAction)logout:(id)sender {
    [xmppDelegate logout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark 加载电子名片数据
-(void)loadCard
{
    XMPPvCardTemp *myCard  = xmppDelegate.xmppvCardTempModule.myvCardTemp;
    // 1. 如果本地没有数据，myCard == nil，myCard
    if (myCard == nil) {
        // 实例化工作本身，并没有根底层的数据库建立关系
        myCard = [XMPPvCardTemp vCardTemp];
        
        // 实例化完成之后，保存到数据库
        [xmppDelegate.xmppvCardTempModule updateMyvCardTemp:myCard];
    }
    if (myCard.photo) {
        
        _headerImagerView.image = [UIImage imageWithData:myCard.photo];
    }else{
        
        // 在其他客户端上如果设置了头像，使用vCardAvatarModule可以更新到最新的头像
        // 使用此模块后，能够保证头像传输的及时性。
        
        NSData *photoData = [xmppDelegate.xmppvCardAvatarModule photoDataForJID:xmppDelegate.xmppStream.myJID];
        if (photoData) {
            _headerImagerView.image = [UIImage imageWithData:photoData];
        }
        
    }
    
    _nickNameLabel.text = myCard.nickname;
    _JidLabel.text = xmppDelegate.xmppStream.myJID.bare;
    
    NSLog(@"%@",myCard.orgUnits);
    
    if (![_orgUnitLabel.text isEqualToString:@""]) {
        _orgUnitLabel.text = myCard.orgUnits[0];
    }
    
    _orgNameLabel.text = myCard.orgName;
    _titleLabel.text = myCard.title;
    _telLabel.text = myCard.note;
    _emailLabel.text = myCard.mailer;
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 如果单元格的tag==0再跳转
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.tag == 0) {
        [self performSegueWithIdentifier:@"EditVCardSegue" sender:cell];
    }else if (cell.tag == 2) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"拍照" otherButtonTitles:@"选择照片", nil];
        
        [sheet showInView:self.view];
    }
    
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%d", buttonIndex);
    if (buttonIndex == 2) {
        return;
    }
    
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    
    if (buttonIndex == 0) {
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
    }else{
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    controller.allowsEditing = YES;
    controller.delegate = self;
    
    [self presentViewController:controller animated:YES completion:nil];
    
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    _headerImagerView.image = image;
    
    // 将名片保存至数据库
    [self savevCard];
    
    // 关闭视图控制器
    [self dismissViewControllerAnimated:YES completion:nil];

}

@end
