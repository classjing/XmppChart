//
//  ViewController.m
//  XmppChart
//
//  Created by classjing on 14-4-1.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "LoginViewController.h"
#import "UIImage+MJ.h"
#import "NSString+Helper.h"
#import "AppDelegate.h"

extern NSString * const kXMPPLoginUserNameKey;
extern NSString * const kXMPPLoginPasswordKey;
extern NSString * const kXMPPLoginHostNameKey;

@interface LoginViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameText;
@property (weak, nonatomic) IBOutlet UITextField *passwordText;
@property (weak, nonatomic) IBOutlet UITextField *hostNameText;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 1. 屏幕适配
    // 如果屏幕是4寸屏，调整顶部的约束
    if ([UIScreen mainScreen].bounds.size.height >= 568.0) {
        _topConstraint.constant = 80.0;
    }
    
    //设置按钮图片
    UIImage *loginImage = [UIImage resizedImage:@"LoginGreenBigBtn"];
    [_loginButton setBackgroundImage:loginImage forState:UIControlStateNormal];
    //注册图片
    UIImage *registerImage = [UIImage resizedImage:@"LoginwhiteBtn"];
    [_registerButton setBackgroundImage:registerImage forState:UIControlStateNormal];
    
    // 3. 从系统偏好读取用户已经保存的信息设置UI
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    _usernameText.text = [defaults stringForKey:kXMPPLoginUserNameKey];
    _passwordText.text = [defaults stringForKey:kXMPPLoginPasswordKey];
    _hostNameText.text = [defaults stringForKey:kXMPPLoginHostNameKey];
    
    if (_usernameText.text.length == 0) {
        [_usernameText becomeFirstResponder];
    } else {
        [_passwordText becomeFirstResponder];
    }

    
}


/**
 *  textField代理方法
 *
 *  @param textField <#textField description#>
 *
 *  @return <#return value description#>
 */
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *userName = [_usernameText.text trimString];
    // 提示，有些用户是喜欢用空格当密码的，因此，此处不要截断空白字符
    NSString *password = _passwordText.text;
    NSString *hostName = [_hostNameText.text trimString];
    
    if (userName.length > 0 && password.length > 0 && hostName.length > 0) {
        [self userLogin:nil];
    } else {
        // 从上向下依次判断文本框，是否有输入内容
        if (userName.length == 0) {
            [_usernameText becomeFirstResponder];
        } else if (password.length == 0) {
            [_passwordText becomeFirstResponder];
        } else {
            [_hostNameText becomeFirstResponder];
        }
    }
    
    return YES;

}

- (IBAction)userLogin:(UIButton*)sender {
    // 1. 获取用户输入内容
    NSString *userName = [_usernameText.text trimString];
    NSString *password = _passwordText.text;
    NSString *hostName = [_hostNameText.text trimString];
    
    // 2. 系统偏好，用来存储常用的个人信息
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:userName forKey:kXMPPLoginUserNameKey];
    [defaults setObject:password forKey:kXMPPLoginPasswordKey];
    [defaults setObject:hostName forKey:kXMPPLoginHostNameKey];
    
    [defaults synchronize];
    
    
    // 3. 获取AppDelegate
    // 代理如何知道是注册还是登录呢？
    xmppDelegate.isRegisterUser = sender.tag;
    
    /**
     连接到主机的错误情况
     
     1> 连接不到服务器
     2> 用户名或者密码错误
     */
    [xmppDelegate connectOnFailed:^(kLoginErrorType type) {
        NSString *msg = nil;
        if (type == kLoginLogonError) {
            msg = @"用户名或者密码错误";
        } else if (type == kLoginNotConnection) {
            msg = @"无法连接到服务器";
        } else if (type == kLoginRegisterError) {
            msg = @"用户名重复，无法注册";
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        
        [alert show];
        
        if (type == kLoginLogonError) {
            [_passwordText becomeFirstResponder];
        } else if (type == kLoginNotConnection) {
            [_hostNameText becomeFirstResponder];
        } else {
            [_usernameText becomeFirstResponder];
        }
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
