//
//  DrawView.h
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import <UIKit/UIKit.h>
#import "UIElementTableViewCell.h"
#import <MessageUI/MessageUI.h>
#import "ISColorWheel.h"
#import "TPKeyboardAvoidingScrollView.h"

@class MainViewController;

@interface DrawView_PreliminaryPath : UIView <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, ISColorWheelDelegate, UITextFieldDelegate>

@property (nonatomic) BOOL drawing;
@property (nonatomic) BOOL canDraw;
@property (nonatomic) int elementNumber;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) CAShapeLayer *currentShapeLayer;
@property (strong, nonatomic) MainViewController *mainController;
@property (strong, nonatomic) UIView *tableHolder;
@property (strong, nonatomic) UIButton *closeTableButton;
@property (strong, nonatomic) NSArray *tableUIArray;
@property (strong, nonatomic) NSMutableArray *UIArray;
@property (strong, nonatomic) UIButton *grayView;
@property (strong, nonatomic) ISColorWheel *colorPicker;

//AttributesView
@property (strong, nonatomic) UIView *currentView;
@property (strong, nonatomic) TPKeyboardAvoidingScrollView *attributesScrollView;
@property (strong, nonatomic) UIView *attributesView;
@property (strong, nonatomic) UIButton *closeAttributesButton;
@property (strong, nonatomic) UITextField *titleAttribute;

@end
