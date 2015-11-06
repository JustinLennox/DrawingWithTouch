//
//  InkUpTableViewCell.m
//  InkUp
//
//  Created by Justin Lennox on 11/6/15.
//
//

#import "InkUpTableViewCell.h"

@implementation InkUpTableViewCell

@synthesize titleLabel;
@synthesize imageView;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"InkUpTableViewCell" owner:self options:nil];
        
        self = [nibArray objectAtIndex:0];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
