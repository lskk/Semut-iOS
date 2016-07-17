//
//  TiledMenuContainer.m
//  Skata
//
//  Created by Asep Mulyana on 4/6/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "TiledMenuContainer.h"

@implementation TiledMenuContainer{
    CGSize defaultSize;
}

-(void)layoutSubviews{
    NSInteger count = self.subviews.count;
    CGSize mySize = CGSizeEqualToSize(CGSizeZero, defaultSize)?self.frame.size:defaultSize;
    
    CGFloat maxWidth = 0;
    CGFloat maxHeight = 0;
    for(UIView *v in self.subviews){
        maxWidth = MAX(maxWidth, v.frame.size.width);
        maxHeight = MAX(maxHeight, v.frame.size.height);
    }
    
    // 1, 2 => satu kolom
    // 4 => dua kolom
    // sisanya => 3 kolom
    NSInteger colNum = (count <= 2)?1:(count==4)?2:3;
    CGFloat rowNum = ceilf((float)count / (float)colNum);
    
    CGFloat spaceY = (mySize.height - rowNum * maxHeight) / (rowNum + 1);
    spaceY = MAX(spaceY, 5);
    CGFloat spaceX = (mySize.width - colNum * maxWidth) / (colNum + 1);
    
    for(int y=0; y<rowNum; y++){
        for(int x=0; x<colNum; x++){
            NSInteger index = x+y * colNum;
            
            if(index < count){
                UIView *v = [self.subviews objectAtIndex:index];
                
                if((colNum == 3) && (count % colNum == 1) && (index == count-1)){
                    x++;
                }
                
                CGRect frame = v.frame;
                frame.origin.x = (x+1) * spaceX + x * maxWidth;
                frame.origin.y = (y+1) * spaceY + y * maxHeight;
                v.frame = frame;
            }
        }
    }
    
    CGFloat totalHeight = rowNum * maxHeight + (rowNum + 1)*spaceY;
    UIScrollView *scroll = (UIScrollView *)self.superview;
    if(![scroll isKindOfClass:[UIScrollView class]]){
        scroll = [[[UIScrollView alloc] initWithFrame:self.frame] autorelease];
        self.frame = self.bounds;
        [self.superview addSubview:scroll];
        [self removeFromSuperview];
        [scroll addSubview:self];
    }
    scroll.contentSize = CGSizeMake(mySize.width, totalHeight);
    
    if(totalHeight > mySize.height){
        if(CGSizeEqualToSize(CGSizeZero, defaultSize)){
            defaultSize = mySize;
        }
        
        mySize.height = totalHeight;
        CGRect f = self.frame;
        f.size = mySize;
        self.frame = f;
    }else if(totalHeight < defaultSize.height){
        mySize.height = totalHeight;
        CGRect f = self.frame;
        f.size = defaultSize;
        self.frame = f;
    }
}

@end
