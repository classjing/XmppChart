//
//  PNEmojiPageView.h
//  PNWeiBoClient
//
//  Created by mac on 13-10-22.
//  Copyright (c) 2013年 zhangsf. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmojiViewDelegate

-(void)didSelectedEmojiItemView:(NSString*)str;

@end

@interface PNEmojiPageView : UIView

@property (nonatomic, assign) id<EmojiViewDelegate>delegate;
- (void)loadEmojiItem:(int)page size:(CGSize)size;

@end
