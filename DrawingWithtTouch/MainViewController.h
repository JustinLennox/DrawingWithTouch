//
//  ViewController.h
//  DrawingWithtTouch
//
//  Created by Plamen Petkov on 11/28/14.
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "InkUpTableViewCell.h"

@interface MainViewController : UIViewController <MFMailComposeViewControllerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

- (IBAction) partButtonPressed:(id)sender;

- (IBAction) back:(id)sender;
@property (nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) UIView *addChillBackground;
@property (strong, nonatomic) UIView *addChillView;
@property (strong, nonatomic) UITextField *addChillTitle;

@property (strong, nonatomic) UITableView *tableView;

@end

