//
//  AddRoomRosterCell.m
//  XmppChart
//
//  Created by classjing on 14-4-16.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "AddRoomRosterCell.h"

@implementation AddRoomRosterCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [[[NSBundle mainBundle]loadNibNamed:@"AddRoomRosterCell" owner:self options:nil]objectAtIndex:0];;
    if (self) {
        // Initialization code
    }
    return self;
}
- (NSString *)reuseIdentifier
{
    return @"AddRoomRosterCell";
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
