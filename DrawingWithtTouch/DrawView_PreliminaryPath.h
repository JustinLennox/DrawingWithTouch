//
//  DrawView.h
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import <UIKit/UIKit.h>
#import "UIElementTableViewCell.h"

@interface DrawView_PreliminaryPath : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) BOOL drawing;
@property (nonatomic) BOOL canDraw;
@property (nonatomic) int elementNumber;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) CAShapeLayer *currentShapeLayer;

@end
