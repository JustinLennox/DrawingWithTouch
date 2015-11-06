//
//  ViewController.h
//  DrawingWithtTouch
//
//  Created by Plamen Petkov on 11/28/14.
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface MainViewController : UIViewController <MFMailComposeViewControllerDelegate>

- (IBAction) partButtonPressed:(id)sender;

- (IBAction) back:(id)sender;
@property (nonatomic) IBOutlet UIButton *backButton;

@end

