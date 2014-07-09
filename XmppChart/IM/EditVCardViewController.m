//
//  EditVCardViewController.m
//  XmppChart
//
//  Created by classjing on 14-4-2.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "EditVCardViewController.h"
#import "NSString+Helper.h"
@interface EditVCardViewController ()
@property (weak, nonatomic) IBOutlet UITextField *contextLabel;

@end

@implementation EditVCardViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = _contentTitle;
    
    _contextLabel.placeholder = [NSString stringWithFormat:@"请输入%@",_contentTitle];
    
    _contextLabel.text = _contentLabel.text;
    
    //获取焦点
    [_contextLabel becomeFirstResponder];
    
    
}

- (IBAction)save:(id)sender {
    _contentLabel.text = [_contextLabel.text trimString];
    [_delegate editVCardControllerDidFinished];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self save:nil];
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
