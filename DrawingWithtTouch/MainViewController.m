//
//  ViewController.m
//  DrawingWithtTouch
//
//  Created by Plamen Petkov on 11/28/14.
//
//

#import "MainViewController.h"

#import "DrawView_InkEngineSetup.h"
#import "DrawView_BuildingPaths.h"
#import "DrawView_Smoothing.h"
#import "DrawView_TransparentStrokes.h"
#import "DrawView_PreliminaryPath.h"
#import "DrawView_GenerateBezierPath.h"
#import "DrawView_ParticleBrush.h"

@interface MainViewController ()

@end


@implementation MainViewController
{
    NSArray* drawViewClasses;
    DrawView_PreliminaryPath * drawView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    drawViewClasses = @[ [DrawView_InkEngineSetup class],
                         [DrawView_BuildingPaths class],
                         [DrawView_Smoothing class],
                         [DrawView_TransparentStrokes class],
                         [DrawView_PreliminaryPath class],
                         [DrawView_ParticleBrush class],
                         [DrawView_GenerateBezierPath class]
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
