//
//  ViewController.m
//  DrawingWithtTouch
//
//  Created by Plamen Petkov on 11/28/14.
//
//

#import "MainViewController.h"
#import "DrawView_PreliminaryPath.h"

@interface MainViewController ()

@end


@implementation MainViewController
{
    NSArray* drawViewClasses;
    DrawView_PreliminaryPath * drawView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    drawViewClasses = @[
                         [DrawView_PreliminaryPath class],

                         ];
}

- (IBAction) partButtonPressed:(id)sender
{
    drawView = [[DrawView_PreliminaryPath alloc] initWithFrame:self.view.frame];
    drawView.mainController = self;
    [self.view addSubview:drawView];
    
    _backButton.hidden = NO;
    [self.view bringSubviewToFront:_backButton];
}

- (IBAction) back:(id)sender
{
    [drawView removeFromSuperview];
    _backButton.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
