//
//  EditVCardViewController.h
//  XmppChart
//
//  Created by classjing on 14-4-2.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditVCardViewContrllerDelegate <NSObject>

-(void)editVCardControllerDidFinished;

@end


@interface EditVCardViewController : UIViewController

@property(nonatomic,weak) id<EditVCardViewContrllerDelegate> delegate;


@property(nonatomic,strong) NSString *contentTitle;

@property(nonatomic,weak) UILabel *contentLabel;

@end
