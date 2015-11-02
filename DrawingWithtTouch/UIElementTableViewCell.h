//
//  UIElementTableViewCell.h
//  DrawingWithTouch
//
//  Created by Justin Lennox on 8/20/15.
//
//

#import <UIKit/UIKit.h>

@interface UIElementTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *elementImageView;
@property (strong, nonatomic) IBOutlet UILabel *elementLabel;

@end
