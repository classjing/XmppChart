//
//  PNEmojiPageView.m
//  PNWeiBoClient
//
//  Created by mac on 13-10-22.
//  Copyright (c) 2013年 zhangsf. All rights reserved.
//

#import "PNEmojiPageView.h"
#import "Emoji.h"

@interface PNEmojiPageView ()
@property (nonatomic, retain) NSArray *allEmojis;
@end

@implementation PNEmojiPageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _allEmojis = [Emoji allEmoji];
    }
    return self;
}

//一个界面上表情布局是三行七列
- (void)loadEmojiItem:(int)page size:(CGSize)size
{
    //row number
	for (int i=0; i<4; i++) {
		//column numer
		for (int y=0; y<9; y++) {
			UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
            [button setBackgroundColor:[UIColor clearColor]];
            [button setFrame:CGRectMake(y*size.width, i*size.height, size.width, size.height)];
//           每个界面的右下角是一个删除键
            if (i==3 && y==8) {
                [button setImage:[UIImage imageNamed:@"emojiDelete"] forState:UIControlStateNormal];
                button.tag=10000;
                
            }else{
                [button.titleLabel setFont:[UIFont fontWithName:@"AppleColorEmoji" size:29.0]];
                [button setTitle: [_allEmojis objectAtIndex:i*3+y+(page*19)]forState:UIControlStateNormal];
                button.tag=i*3+y+(page*19);
            }
			[button addTarget:self action:@selector(selected:) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:button];
		}
	}

}

- (void)selected:(UIButton*)emojiBtn
{
    if (emojiBtn.tag==10000) {
        [_delegate didSelectedEmojiItemView:@"删除"];
    }else{
        NSString *str=[_allEmojis objectAtIndex:emojiBtn.tag];
        [_delegate didSelectedEmojiItemView:str];
    }
}
@end
