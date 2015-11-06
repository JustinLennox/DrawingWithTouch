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
#import "UIDownPicker.h"

@class MainViewController;

@interface DrawView_PreliminaryPath : UIView <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, ISColorWheelDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) BOOL drawing;
@property (nonatomic) BOOL canDraw;
@property (nonatomic) BOOL canMove;
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
@property (strong, nonatomic) UIButton *closeColorPickerButton;

//AttributesView
@property (strong, nonatomic) UIView *currentView;
@property (strong, nonatomic) TPKeyboardAvoidingScrollView *attributesScrollView;
@property (strong, nonatomic) UIView *attributesView;
@property (strong, nonatomic) UIButton *closeAttributesButton;
@property (strong, nonatomic) UITextField *titleAttribute;
@property (strong, nonatomic) UIButton *backgroundColorButton;
@property (strong, nonatomic) UIButton *titleColorButton;
@property (strong, nonatomic) UITextField *fontSizeTextField;
@property (strong, nonatomic) UIButton *increaseSizeButton;
@property (strong, nonatomic) UIButton *decreaseSizeButton;
@property (nonatomic) BOOL changingTitle;
@property (nonatomic) BOOL changingBackground;


@end
