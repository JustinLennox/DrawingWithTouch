//
//  UIElementTableViewCell.m
//  DrawingWithTouch
//
//  Created by Justin Lennox on 8/20/15.
//
//

#import "UIElementTableViewCell.h"

@implementation UIElementTableViewCell

@synthesize elementImageView;
@synthesize elementLabel;

- (void)awakeFromNib {
    // Initialization code
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"UIElementTableViewCell" owner:self options:nil];
        
        self = [nibArray objectAtIndex:0];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
