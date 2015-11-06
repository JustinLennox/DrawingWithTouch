//
//  DrawView.m
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import "DrawView_PreliminaryPath.h"
#import <WILLCore/WILLCore.h>
#import "MainViewController.h"

@implementation DrawView_PreliminaryPath
{
    WCMRenderingContext * willContext;
    WCMLayer* viewLayer;
    WCMLayer * strokesLayer;
    
    WCMStrokeRenderer * strokeRenderer;
    
    WCMSpeedPathBuilder * pathBuilder;
    int pathStride;
    WCMStrokeBrush * pathBrush;
    
    WCMMultiChannelSmoothener * pathSmoothener;
    WCMFloatVectorPointer * _points;
}

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initWillContext];
        
        [willContext setTarget:strokesLayer];
        [willContext clearColor:[UIColor clearColor]];
        
        [self refreshViewInRect:viewLayer.bounds];
        
        self.grayView = [UIButton buttonWithType:UIButtonTypeCustom];
        self.grayView.frame = self.frame;
        [self.grayView addTarget:self action:@selector(hideTableView) forControlEvents:UIControlEventTouchUpInside];
        self.grayView.backgroundColor = [UIColor blackColor];
        [self addSubview:self.grayView];
        
        self.tableHolder = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * 0.1, self.frame.size.height * 0.2, self.frame.size.width * 0.8, self.frame.size.height * 0.6)];
        self.tableHolder.layer.masksToBounds = true;
        self.tableHolder.layer.cornerRadius = 8.0f;
        [self addSubview:self.tableHolder];
        
        UILabel *holderTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableHolder.frame.size.width, self.tableHolder.frame.size.height * 0.1)];
        holderTitle.text = @"Draw UI";
        holderTitle.font = [UIFont fontWithName:@"Helvetica" size:20.0f];
        holderTitle.adjustsFontSizeToFitWidth = true;
        holderTitle.layer.masksToBounds = true;
        holderTitle.textColor = [UIColor whiteColor];
        holderTitle.backgroundColor = [UIColor colorWithRed: 128.0/255.0 green: 222.0/255.0 blue: 234.0/255.0 alpha: 1.0];
//        [self.tableHolder addSubview:holderTitle];
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.tableHolder.frame.size.width, self.tableHolder.frame.size.height)];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.grayView.alpha = 0.0f;
        self.tableHolder.alpha = 0.0f;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [self.tableHolder addSubview:self.tableView];
        self.tableView.layer.masksToBounds = true;
        
        self.closeTableButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeTableButton.frame = CGRectMake(self.tableHolder.frame.origin.x - 25, self.tableHolder.frame.origin.y - 25, 50, 50);
        [self.closeTableButton addTarget:self action:@selector(hideTableView) forControlEvents:UIControlEventTouchUpInside];
        [self.closeTableButton setBackgroundImage:[UIImage imageNamed:@"closeIcon.png"] forState:UIControlStateNormal];
        self.closeTableButton.alpha = 0.0f;
        [self addSubview:self.closeTableButton];
        
        UITapGestureRecognizer *addUI = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addUI:)];
        addUI.numberOfTouchesRequired = 2;
        [self addGestureRecognizer:addUI];
        
        UITapGestureRecognizer *optionTouch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showEmail:)];
        optionTouch.numberOfTouchesRequired = 3;
        [self addGestureRecognizer:optionTouch];
        
        self.drawing = false;
        self.canDraw = false;
        
        self.tableUIArray = @[@{@"title":@"View", @"description":@" - Represents a rectangular region in which it draws and receives events."},
                              @{@"title":@"Label", @"description":@" - A variably sized amount of static text"},
                              @{@"title":@"Button", @"description":@" - Intercepts touch events and sends an action message to a target object when it's tapped."}];
        
        self.UIArray = [[NSMutableArray alloc] init];
        
        CGSize size = self.bounds.size;
        
        CGSize wheelSize = CGSizeMake(size.width * .8, size.width * .8);
        
        self.colorPicker = [[ISColorWheel alloc] initWithFrame:CGRectMake(size.width / 2 - wheelSize.width / 2,
                                                                     size.height * .3,
                                                                     wheelSize.width,
                                                                     wheelSize.height)];
        self.colorPicker.alpha = 0.0f;
        self.colorPicker.delegate = self;
       self.colorPicker.continuous = true;
        [self addSubview:self.colorPicker];
        
        self.closeColorPickerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeColorPickerButton.frame = CGRectMake(0, 0, 50, 50);
        [self.closeColorPickerButton addTarget:self action:@selector(hideColorWheel) forControlEvents:UIControlEventTouchUpInside];
        [self.closeColorPickerButton setBackgroundImage:[UIImage imageNamed:@"closeIcon.png"] forState:UIControlStateNormal];
        [self.colorPicker addSubview:self.closeColorPickerButton];
        
        self.attributesScrollView = [[TPKeyboardAvoidingScrollView alloc] initWithFrame:self.frame];
        [self addSubview:self.attributesScrollView];
        self.attributesScrollView.backgroundColor = [UIColor whiteColor];
        self.attributesScrollView.alpha = 0.0f;
        
        self.attributesView = [[UIView alloc] initWithFrame:CGRectMake(25, CGRectGetMidX(self.frame), self.frame.size.width - 50, self.frame.size.height * 0.5f)];
        self.attributesView.layer.borderColor = [UIColor grayColor].CGColor;
        self.attributesView.layer.borderWidth = 1.0f;
        self.attributesView.alpha = 0.0f;
        self.attributesView.backgroundColor = [UIColor whiteColor];
        self.attributesView.layer.cornerRadius = 4.0f;
        self.attributesView.layer.masksToBounds = true;
        [self.attributesScrollView addSubview:self.attributesView];
        
        self.closeAttributesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeAttributesButton.frame = CGRectMake(0, self.attributesView.frame.origin.y - 25, 50, 50);
        [self.closeAttributesButton addTarget:self action:@selector(hideAttributesView) forControlEvents:UIControlEventTouchUpInside];
        [self.closeAttributesButton setBackgroundImage:[UIImage imageNamed:@"closeIcon.png"] forState:UIControlStateNormal];
        self.closeAttributesButton.alpha = 0.0f;
        [self.attributesScrollView addSubview:self.closeAttributesButton];
        
        self.titleAttribute = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.attributesView.frame.size.width, self.attributesView.frame.size.height * 0.2)];
        self.titleAttribute.delegate = self;
        self.titleAttribute.font = [UIFont fontWithName:@"Helvetica-Bold" size:20.0f];
        self.titleAttribute.adjustsFontSizeToFitWidth = true;
        self.titleAttribute.textColor = [UIColor blackColor];
        [self.titleAttribute addTarget:self action:@selector(titleTextChanged) forControlEvents:UIControlEventEditingChanged];
        self.titleAttribute.placeholder = @"Title Text";
        self.titleAttribute.textAlignment = NSTextAlignmentCenter;
        self.titleAttribute.returnKeyType = UIReturnKeyDone;
        [self.attributesView addSubview:self.titleAttribute];
        
        self.backgroundColorButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.backgroundColorButton.frame = CGRectMake(0, self.titleAttribute.frame.size.height, self.attributesView.frame.size.width, self.attributesView.frame.size.height * 0.2);
        [self.backgroundColorButton addTarget:self action:@selector(changeUIBackgroundColor) forControlEvents:UIControlEventTouchUpInside];
        [self.backgroundColorButton setTitle:@"Background Color" forState:UIControlStateNormal];
        [self.backgroundColorButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0f]];
        self.backgroundColorButton.titleLabel.adjustsFontSizeToFitWidth = true;
        [self.attributesView addSubview:self.backgroundColorButton];
        
        self.titleColorButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.titleColorButton.frame = CGRectMake(0, self.titleAttribute.frame.size.height + self.backgroundColorButton.frame.size.height, self.attributesView.frame.size.width, self.attributesView.frame.size.height * 0.2);
        [self.titleColorButton addTarget:self action:@selector(changeUITitleColor) forControlEvents:UIControlEventTouchUpInside];
        [self.titleColorButton setTitle:@"Title Color" forState:UIControlStateNormal];
        [self.titleColorButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0f]];
        self.titleColorButton.titleLabel.adjustsFontSizeToFitWidth = true;
        [self.attributesView addSubview:self.titleColorButton];
        
        self.fontSizeTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, self.backgroundColorButton.frame.size.height + self.titleColorButton.frame.size.height + self.titleAttribute.frame.size.height, self.attributesView.frame.size.width, self.attributesView.frame.size.height * 0.2)];
        self.fontSizeTextField.delegate = self;
        self.fontSizeTextField.font = [UIFont fontWithName:@"Helvetica-Bold" size:20.0f];
        self.fontSizeTextField.adjustsFontSizeToFitWidth = true;
        self.fontSizeTextField.textColor = [UIColor blackColor];
        [self.fontSizeTextField addTarget:self action:@selector(fontSizeChanged) forControlEvents:UIControlEventEditingChanged];
        self.fontSizeTextField.placeholder = @"Font Size";
        self.fontSizeTextField.textAlignment = NSTextAlignmentCenter;
        self.fontSizeTextField.returnKeyType = UIReturnKeyDone;
        [self.attributesView addSubview:self.fontSizeTextField];
        
        self.increaseSizeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.increaseSizeButton.frame = CGRectMake(0, self.titleAttribute.frame.size.height + self.backgroundColorButton.frame.size.height + self.titleColorButton.frame.size.height + self.fontSizeTextField.frame.size.height, self.attributesView.frame.size.width * 0.5, self.attributesView.frame.size.height * 0.2);
        [self.increaseSizeButton addTarget:self action:@selector(increaseUISize) forControlEvents:UIControlEventTouchUpInside];
        [self.increaseSizeButton setTitle:@"+" forState:UIControlStateNormal];
        [self.increaseSizeButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0f]];
        self.increaseSizeButton.titleLabel.adjustsFontSizeToFitWidth = true;
        [self.attributesView addSubview:self.increaseSizeButton];
//
//        self.fontSizePicker = [[UIDownPicker alloc] initWithData:[NSMutableArray arrayWithArray:@[@"0", @"5", @"10", @"15", @"20", @"25", @"30", @"35", @"40", @"45", @"50"]]];
//        self.fontSizePicker.frame = CGRectMake(0, self.titleAttribute.frame.size.height + self.backgroundColorButton.frame.size.height + self.titleColorButton.frame.size.height, self.attributesView.frame.size.width, self.attributesView.frame.size.height * 0.2);
//        self.fontSizePicker.font = [UIFont fontWithName:@"Helvetica-Bold" size:20.0f];
//        self.fontSizePicker.placeholder = @"Font Size";
//        [self.fontSizePicker addTarget:self action:@selector(dp_Selected:) forControlEvents:UIControlEventValueChanged];
//        [self.fontSizePicker addTarget:self action:@selector(dp_Selected:) forControlEvents:UIControlEventTouchUpInside];
//        [self.attributesView addSubview:self.fontSizePicker];
        
    }
    return self;
}

- (void) initWillContext
{
    if (!willContext)
    {
        self.contentScaleFactor = [UIScreen mainScreen].scale;
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        EAGLContext* eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!eaglContext || ![EAGLContext setCurrentContext:eaglContext])
        {
            NSLog(@"Unable to create EAGLContext!");
            return;
        }
        
        willContext = [WCMRenderingContext contextWithEAGLContext:eaglContext];
        
        viewLayer = [willContext layerFromEAGLDrawable:(id<EAGLDrawable>)self.layer withScaleFactor:self.contentScaleFactor];
        
        strokesLayer = [willContext layerWithWidth:viewLayer.bounds.size.width andHeight:viewLayer.bounds.size.height andScaleFactor:viewLayer.scaleFactor andUseTextureStorage:YES];
        
        pathBrush = [willContext solidColorBrush];
        
        pathBuilder = [[WCMSpeedPathBuilder alloc] init];
        [pathBuilder setNormalizationConfigWithMinValue:0 andMaxValue:7000];
        [pathBuilder setPropertyConfigWithName:WCMPropertyNameWidth andMinValue:2 andMaxValue:15 andInitialValue:NAN andFinalValue:NAN andFunction:WCMPropertyFunctionPower andParameter:1 andFlip:NO];
        
        pathStride = [pathBuilder calculateStride];
        
        pathSmoothener = [[WCMMultiChannelSmoothener alloc] initWithChannelsCount:pathStride];
        
        strokeRenderer =  [willContext strokeRendererWithSize:viewLayer.bounds.size andScaleFactor:viewLayer.scaleFactor];
        
        strokeRenderer.brush = pathBrush;
        strokeRenderer.stride = pathStride;
        strokeRenderer.color = [UIColor blackColor];
    }
}

-(void) refreshViewInRect:(CGRect)rect
{
    [willContext setTarget:viewLayer andClipRect:rect];
    [willContext clearColor:[UIColor whiteColor]];
    
    [willContext drawLayer:strokesLayer withSourceRect:rect andDestinationRect:rect andBlendMode:WCMBlendModeNormal];
    
    
    [strokeRenderer blendStrokeUpdatedAreaInLayer:viewLayer withBlendMode:WCMBlendModeNormal];
    
    [viewLayer present];
    
    [willContext setTarget:viewLayer andClipRect:rect];
    
    
    
}

- (void) processTouches:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    
    if (touch.phase != UITouchPhaseStationary)
    {
        CGPoint location = [touch locationInView:self];
        WCMInputPhase wcmInputPhase;
        
        if (touch.phase == UITouchPhaseBegan)
        {
            wcmInputPhase = WCMInputPhaseBegin;
            
            [pathSmoothener reset];
            
            strokeRenderer.color = [UIColor colorWithRed:(float)rand()/RAND_MAX green:(float)rand()/RAND_MAX blue:(float)rand()/RAND_MAX alpha:0.5];
            [strokeRenderer resetAndClearBuffers];
        }
        else if (touch.phase == UITouchPhaseMoved)
        {
            wcmInputPhase = WCMInputPhaseMove;
        }
        else if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled)
        {
            wcmInputPhase = WCMInputPhaseEnd;
        }
        
        WCMFloatVectorPointer *points = [pathBuilder addPointWithPhase:wcmInputPhase andX:location.x andY:location.y andTimestamp:touch.timestamp];
        WCMFloatVectorPointer * smoothedPoints = [pathSmoothener smoothValues:points reachFinalValues:wcmInputPhase == WCMInputPhaseEnd];
        WCMPathAppendResult* pathAppendResult = [pathBuilder addPathPart:smoothedPoints];
        
        WCMFloatVectorPointer * prelimPoints = [pathBuilder createPreliminaryPath];
        WCMFloatVectorPointer * smoothedPrelimPoints = [pathSmoothener smoothValues:prelimPoints reachFinalValues:YES];
        _points = [pathBuilder finishPreliminaryPath:smoothedPrelimPoints];
        [strokeRenderer drawPoints:pathAppendResult.addedPath finishStroke:wcmInputPhase == WCMInputPhaseEnd];
        [strokeRenderer drawPreliminaryPoints:_points];

//        [self createClosedCGPath];
        if (wcmInputPhase == WCMInputPhaseEnd)
        {
            [strokeRenderer blendStrokeInLayer:strokesLayer withBlendMode:WCMBlendModeNormal];
            [self generateBezierPath:pathAppendResult.wholePath];
            
        }
        
        [self refreshViewInRect:strokeRenderer.updatedArea];
    }
}

-(void) generateBezierPath:(WCMFloatVectorPointer*)points
{
    
    WCMBezierPathUtils * pathUtils = [[WCMBezierPathUtils alloc] init];
    [pathUtils addPathPoints:points andStride:[pathBuilder calculateStride] andWidth:NAN];
    UIBezierPath * bezierPath = [pathUtils createUIBezierPath];
    
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    [shapeLayer setPath:bezierPath.CGPath];
    shapeLayer.fillColor = [UIColor redColor].CGColor;
    shapeLayer.position = CGPointMake(0, 0);
    [[self layer] addSublayer:shapeLayer];
    self.currentShapeLayer = shapeLayer;
    
    [self addUIElementWithFrame:CGRectMake(bezierPath.bounds.origin.x, bezierPath.bounds.origin.y, bezierPath.bounds.size.width, bezierPath.bounds.size.height)];
    
    
    //    NSLog(@"%@", points);
    //    NSLog(@"%@", bezierPath);
}


- (UIImage *)imageFromLayer:(CALayer *)layer
{
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions([layer frame].size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext([layer frame].size);
    
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return outputImage;
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(self.canDraw == true){
        self.drawing = true;
    }
    if(self.drawing == true){
        NSLog(@"Process touch began");
        [self processTouches:touches withEvent:event];
    }
    
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(self.drawing == true){
        [self processTouches:touches withEvent:event];
    }
    
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    if(self.drawing == true){
        NSLog(@"Process touch ended");
        [self processTouches:touches withEvent:event];
        self.drawing = false;
        self.canDraw = false;
    }
    
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(self.drawing == true){
        
        [self processTouches:touches withEvent:event];
    }
    
}


-(CGPathRef) createClosedCGPath
{
    UIGraphicsBeginImageContext([[UIScreen mainScreen] bounds].size);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    int n = self.pointsCount;
    NSLog(@"Point counts: %d", n);
    for (int i = 1; i<n-2; i++)
    {
        NSLog(@"POints!");
        if (i==1)
        {
            CGPathMoveToPoint(path, NULL, [self pointAtIndex:i].x, [self pointAtIndex:i].y);
        }
        
        if (i<n-3)
        {
            //CatmullRom to bezier
            float bufferX[] = {[self pointAtIndex:i+0].x, [self pointAtIndex:i+1].x, [self pointAtIndex:i+2].x, [self pointAtIndex:i+3].x};
            float bufferY[] = {[self pointAtIndex:i+0].y, [self pointAtIndex:i+1].y, [self pointAtIndex:i+2].y, [self pointAtIndex:i+3].y};
            
            static float one6th = 0.166666666666f;
            
            float bx1 = -one6th * bufferX[0] + bufferX[1] + one6th * bufferX[2];
            float bx2 = +one6th * bufferX[1] + bufferX[2] - one6th * bufferX[3];
            float bx3 = bufferX[2];
            
            float by1 = -one6th * bufferY[0] + bufferY[1] + one6th * bufferY[2];
            float by2 = +one6th * bufferY[1] + bufferY[2] - one6th * bufferY[3];
            float by3 = bufferY[2];
            
            CGPathAddCurveToPoint(path, NULL, bx1, by1, bx2, by2, bx3, by3);
        }
        
        if (i==n-3)
        {
            CGPathCloseSubpath(path);
        }
    }
    
    CGContextAddPath(ctx, path);
    CGContextSetStrokeColorWithColor(ctx,[UIColor whiteColor].CGColor);
    CGContextStrokePath(ctx);
    UIGraphicsEndImageContext();
    return path;
}

-(int) pointsCount
{
    size_t count = _points.size / 1;
    return (int)count;
}

-(CGPoint) pointAtIndex:(int)index
{
    float * iter = _points.begin + index*1;
    return  CGPointMake(iter[0], iter[1]);
}


#pragma mark- Table View Methods


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.tableUIArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //    NSLog(@"Height:%f",(self.view.frame.size.height - 93)/5.0f);
    //    NSLog(@"View height:%f", self.view.frame.size.height);
    return 100.0f;
}


-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellIdentifier = @"cell";
    
    UIElementTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil){
        NSDictionary *currentUIDict = [self.tableUIArray objectAtIndex:indexPath.row];
        UIFont *font_regular=[UIFont fontWithName:@"Helvetica" size:13.0f];
        UIFont *font_bold=[UIFont fontWithName:@"Helvetica-Bold" size:16.0f];
        NSString *myString = [NSString stringWithFormat:@"%@%@", [currentUIDict objectForKey:@"title"], [currentUIDict objectForKey:@"description"]];
        NSString *titleString = [currentUIDict objectForKey:@"title"];
        NSRange boldedRange = NSMakeRange(0, titleString.length);
        NSRange notBoldedRange = NSMakeRange(titleString.length, myString.length - titleString.length);
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:myString];
        [attrString addAttribute:NSFontAttributeName value:font_bold range:boldedRange];
        [attrString addAttribute:NSFontAttributeName value:font_regular range:notBoldedRange];
    
        cell = [[UIElementTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.elementLabel.adjustsFontSizeToFitWidth = true;
        cell.elementLabel.attributedText = attrString;
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    self.elementNumber = (int)indexPath.row;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hideTableView];
    self.canDraw = true;
    
}

-(void)hideTableView{
    self.tableHolder.alpha = 0.0f;
    self.grayView.alpha = 0.0f;
    self.closeTableButton.alpha = 0.0f;
}



#pragma mark- Gesture Recognizers

-(void)addUI : (UITapGestureRecognizer *) sender{
    self.drawing = false;
    if(sender.state == UIGestureRecognizerStateEnded){
        [self bringSubviewToFront:self.grayView];
        [self bringSubviewToFront:self.tableHolder];
        [self bringSubviewToFront:self.closeTableButton];
        self.grayView.alpha = 0.5f;
        self.tableHolder.alpha = 1.0f;
        self.closeTableButton.alpha = 1.0f;
    }
}

#pragma mark- Add UI Element

-(void)addUIElementWithFrame : (CGRect) uiFrame{
    
    float adjustedX = uiFrame.origin.x/self.frame.size.width;
    float adjustedY = uiFrame.origin.y/self.frame.size.height;
    float adjustedWidth = uiFrame.size.width/self.frame.size.width;
    float adjustedHeight = uiFrame.size.height/self.frame.size.height;
    
    
    UITapGestureRecognizer *attributesTouch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAttributesView:)];
    attributesTouch.numberOfTapsRequired = 2;
    attributesTouch.delegate = self;
    
    UIPanGestureRecognizer *panTouch = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panTouch.delegate = self;
    
    
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longGesture.minimumPressDuration = 0.4f;
    longGesture.delegate = self;
    
    
    switch (self.elementNumber) {
            
            //View
        case 0:{
            UIView *drawView = [[UIView alloc] init];
            [drawView setFrame:uiFrame];
            [drawView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
            CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
            [drawView.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
            drawView.tag = self.UIArray.count;
            [drawView addGestureRecognizer:attributesTouch];
            [drawView addGestureRecognizer:panTouch];
            [drawView addGestureRecognizer:longGesture];
            [self addSubview:drawView];
            NSDictionary *uiView = @{@"name":[NSString stringWithFormat:@"view%lu",(unsigned long)self.UIArray.count],
                                     @"type":@"UIView",
                                     @"backgroundColor":[NSString stringWithFormat:@"[UIColor colorWithRed:%f green:%f blue:%f alpha:%f]", red,green,blue,alpha],
                                     @"frame":[NSString stringWithFormat:@"CGRectMake(%f*self.view.frame.size.width,%f*self.view.frame.size.height,%f*self.view.frame.size.width,%f*self.view.frame.size.height)", adjustedX, adjustedY, adjustedWidth, adjustedHeight],
                                     @"tag":[NSNumber numberWithInteger:self.UIArray.count]};
            [self.UIArray addObject:uiView];
            break;
        }
            
            //Label
        case 1:{
            UILabel *drawLabel = [[UILabel alloc] initWithFrame:uiFrame];
            drawLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
            [drawLabel addGestureRecognizer:panTouch];
            [drawLabel addGestureRecognizer:longGesture];
            drawLabel.text = @"Label";
            drawLabel.userInteractionEnabled = true;
            drawLabel.adjustsFontSizeToFitWidth = true;
            drawLabel.textAlignment = NSTextAlignmentCenter;
            drawLabel.textColor = [UIColor whiteColor];
            drawLabel.tag = self.UIArray.count;
            [drawLabel addGestureRecognizer:attributesTouch];
            [self addSubview:drawLabel];

            NSDictionary *uiView = @{@"name":[NSString stringWithFormat:@"label%lu",(unsigned long)self.UIArray.count],
                                     @"type":@"UILabel",
                                     @"frame":[NSString stringWithFormat:@"CGRectMake(%f*self.view.frame.size.width,%f*self.view.frame.size.height,%f*self.view.frame.size.width,%f*self.view.frame.size.height)", adjustedX, adjustedY, adjustedWidth, adjustedHeight],
                                     @"backgroundColor":@"[UIColor colorWithRed:0.2 green:0.3 blue:0.2 alpha:1.0]",
                                     @"tag":[NSNumber numberWithInteger:self.UIArray.count],
                                     @"text":@"Label"};
            [self.UIArray addObject:uiView];
            break;
        }
            
            //Button
        case 2:{
            UIButton *drawButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [drawButton setTitle:@"Button" forState:UIControlStateNormal];
            [drawButton addGestureRecognizer:panTouch];
            [drawButton addGestureRecognizer:longGesture];
            drawButton.adjustsImageWhenHighlighted = true;
            [drawButton setBackgroundImage:[self imageFromLayer:self.currentShapeLayer] forState:UIControlStateNormal];
            [drawButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [drawButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
            [drawButton setFrame:uiFrame];
            [drawButton setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
            drawButton.tag = self.UIArray.count;
            [drawButton addGestureRecognizer:attributesTouch];
            [self addSubview:drawButton];
            
            NSDictionary *uiView = @{@"name":[NSString stringWithFormat:@"button%lu",(unsigned long)self.UIArray.count],
                                     @"type":@"UIButton",
                                     @"frame":[NSString stringWithFormat:@"CGRectMake(%f*self.view.frame.size.width,%f*self.view.frame.size.height,%f*self.view.frame.size.width,%f*self.view.frame.size.height)", adjustedX, adjustedY, adjustedWidth, adjustedHeight],
                                     @"backgroundColor":@"[UIColor colorWithRed:0.2 green:0.3 blue:0.2 alpha:1.0]",
                                     @"text":@"Button",
                                     @"tag":[NSNumber numberWithInteger:self.UIArray.count]};
            NSLog(@"%@",uiView);
            [self.UIArray addObject:uiView];
            break;
        }
        default:
            break;
    }
}

-(void)handleLongPress: (UILongPressGestureRecognizer *)sender{
    if(sender.state == UIGestureRecognizerStateBegan) {
        NSLog(@"Long press");
        self.canMove = true;
    }else if(sender.state == UIGestureRecognizerStateEnded) {
        self.canMove = false;
    }

}

#pragma mark- Writing and Saving Text File

-(void)createHeader{
    
    NSString *headerString =
    @"#import <UIKit/UIKit.h>\n\n@interface InkUpViewController : UIViewController\n\n\n@end";
    [self writeStringToFile:headerString named:@"InkUpViewController.h"];
}

-(void)createImplementation{
    
    NSString *mainUIString = @"";
    
    for(NSDictionary *ui in self.UIArray){
        NSString *type = [ui objectForKey:@"type"];
        NSString *name = [ui objectForKey:@"name"];
        NSString *frame = [ui objectForKey:@"frame"];
        NSString *backColor = [ui objectForKey:@"backgroundColor"];
        NSString *initLine = [NSString stringWithFormat:@"    %@ *%@ = [[%@ alloc] init];", type, name, type];
        NSString *frameLine = [NSString stringWithFormat:@"    %@.frame = %@;", name, frame];
        NSString *backgroundColorLine = [NSString stringWithFormat:@"    %@.backgroundColor = %@;", name, backColor];
        NSString *combinedLines = [NSString stringWithFormat:@"%@\n%@\n%@\n", initLine, frameLine, backgroundColorLine];

        
        if([type isEqualToString:@"UILabel"]){
            if([ui objectForKey:@"text"]){
                NSString *textLine = [NSString stringWithFormat:@"    %@.text = @\"%@\";", name, [ui objectForKey:@"text"]];
                combinedLines = [NSString stringWithFormat:@"%@%@\n", combinedLines, textLine];
            }
        }else if([type isEqualToString:@"UIButton"]){
            if([ui objectForKey:@"text"]){
                NSString *textLine = [NSString stringWithFormat:@"    [%@ setTitle:@\"%@\" forState:UIControlStateNormal];", name, [ui objectForKey:@"text"]];
                combinedLines = [NSString stringWithFormat:@"%@%@\n", combinedLines, textLine];

            }
        }
        NSString *finalLine = [NSString stringWithFormat:@"    [self.view addSubview:%@];", name];
        combinedLines = [NSString stringWithFormat:@"%@%@\n", combinedLines, finalLine];
        mainUIString = [NSString stringWithFormat:@"%@\n\n%@",mainUIString,combinedLines];
    }
    
    NSString *implementationString =[NSString stringWithFormat:
    @"#import \"InkUpViewController.h\"\n\n@interface InkUpViewController ()\n\n@end\n\n@implementation InkUpViewController\n\n- (void)viewDidLoad {\n    [super viewDidLoad];\n%@}\n\n@end", mainUIString];
    [self writeStringToFile:implementationString named:@"InkUpViewController.m"];

    
}

- (void)writeStringToFile:(NSString*)stringContent named:(NSString *)fileName {
    
    // Build the path, and create if needed.
    NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath]) {
        [[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
    }
    
    // The main act...
    [[stringContent dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileAtPath atomically:NO];
}

- (NSString*)readStringFromFileNamed:(NSString*)stringName {
    
    // Build the path...
    NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* fileName = stringName;
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:fileName];
    
    // The main act...
    return [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:fileAtPath] encoding:NSUTF8StringEncoding];
}

#pragma mark- Send Mail Attachment

- (void)showEmail:(NSString*)file {
    
    [self createHeader];
    [self createImplementation];

    NSString *emailTitle = @"InkUp Prototype";
    NSString *messageBody = @"Here's the InkUp for my prototype.";
    NSArray *toRecipents = [NSArray arrayWithObject:@""];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    NSString* headerFilePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* headerFileName = @"InkUpViewController.h";
    NSString* headerFileAtPath = [headerFilePath stringByAppendingPathComponent:headerFileName];
    NSData *headerFileData = [NSData dataWithContentsOfFile:headerFileAtPath];
    
    NSString* impFilePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* impFileName = @"InkUpViewController.m";
    NSString* impFileAtPath = [impFilePath stringByAppendingPathComponent:impFileName];
    NSData *impFileData = [NSData dataWithContentsOfFile:impFileAtPath];
    
    // Determine the MIME type
    NSString *mimeType = @"text/plain";
    // Add attachment
    [mc addAttachmentData:headerFileData mimeType:mimeType fileName:headerFileName];
    [mc addAttachmentData:impFileData mimeType:mimeType fileName:impFileName];
    
    // Present mail view controller on screen
    [_mainController presentViewController:mc animated:YES completion:NULL];
    
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [_mainController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Attributes

-(void)showAttributesView:(UIGestureRecognizer *)sender{
    self.currentView = sender.view;
    self.currentView.tag = sender.view.tag;
    for(NSDictionary *ui in self.UIArray){
        if(self.currentView.tag ==  [[ui objectForKey:@"tag"] intValue]){
            if([ui objectForKey:@"text"]){
                self.titleAttribute.text = [ui objectForKey:@"text"];
            }else{
                self.titleAttribute.text = @"No Title";
            }
        }
    }
    self.attributesView.frame = CGRectMake(self.attributesView.frame.origin.x, CGRectGetMaxY(self.frame), self.attributesView.frame.size.width, self.attributesView.frame.size.height);
    self.closeAttributesButton.frame = CGRectMake(0, CGRectGetMaxY(self.frame), self.frame.size.width - 50, self.frame.size.height * 0.5f);
    self.attributesScrollView.alpha = 0.7;
    self.attributesScrollView.backgroundColor = [UIColor blackColor];
    self.attributesView.alpha = 1.0f;
    [self bringSubviewToFront:self.attributesScrollView];
    [self bringSubviewToFront:self.attributesView];
    [self bringSubviewToFront:self.closeAttributesButton];
    self.closeAttributesButton.alpha = 1.0f;
    [UIView animateWithDuration:0.3 animations:^{
        self.attributesView.frame = CGRectMake(25, CGRectGetMidY(self.frame), self.frame.size.width - 50, self.frame.size.height * 0.5f);
        self.closeAttributesButton.frame = CGRectMake(0, self.attributesView.frame.origin.y - 25, 50, 50);
    }];
}

-(void)hideAttributesView{
    self.attributesScrollView.alpha = 0.0f;
    self.colorPicker.alpha = 0.0f;
    [UIView animateWithDuration:0.3 animations:^{
        self.attributesView.frame = CGRectMake(self.attributesView.frame.origin.x, CGRectGetMaxY(self.frame), self.attributesView.frame.size.width, self.attributesView.frame.size.height);
        self.closeAttributesButton.frame = CGRectMake(0, self.attributesView.frame.origin.y + 25, 50, 50);
    }];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return true;
}

-(void)titleTextChanged{
    for(NSDictionary *ui in self.UIArray){
        if(self.currentView.tag ==  [[ui objectForKey:@"tag"] intValue]){
            if([[ui objectForKey:@"type"] isEqualToString:@"UILabel"]){
                UILabel *tempLabel = self.currentView;
                tempLabel.text = self.titleAttribute.text;
            }
            if([[ui objectForKey:@"type"] isEqualToString:@"UIButton"]){
                UIButton *tempButton = self.currentView;
                [tempButton setTitle:self.titleAttribute.text forState:UIControlStateNormal];
            }
        }
    }
}

-(void)changeUIBackgroundColor{
    [self showColorWheel];
    self.attributesView.alpha = 0.0f;
    self.changingBackground = true;
    self.changingTitle = false;
}

-(void)changeUITitleColor{
    [self showColorWheel];
    self.attributesView.alpha = 0.0f;
    self.changingTitle = true;
    self.changingBackground = false;
}

-(void)fontSizeChanged{
    for(NSDictionary *ui in self.UIArray){
        if(self.currentView.tag ==  [[ui objectForKey:@"tag"] intValue]){
            if([[ui objectForKey:@"type"] isEqualToString:@"UILabel"]){
                UILabel *tempLabel = self.currentView;
                tempLabel.font = [UIFont fontWithName:@"Helvetica" size:[self.fontSizeTextField.text floatValue]];
            }
            if([[ui objectForKey:@"type"] isEqualToString:@"UIButton"]){
                UIButton *tempButton = self.currentView;
                tempButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:[self.fontSizeTextField.text floatValue]];
            }
        }
    }
}

-(void)increaseUISize{
    NSDictionary *ui = @{};
    for(NSDictionary *uiDict in self.UIArray){
        if(self.currentView.tag ==  [[uiDict objectForKey:@"tag"] intValue]){
            ui = uiDict;
        }
    }
    float gnuWidth = self.currentView.frame.size.width *1.10;
    float gnuHeight = self.currentView.frame.size.height * 1.10;
    self.currentView.frame = CGRectMake(self.currentView.frame.origin.x, self.currentView.frame.origin.y, gnuWidth,gnuHeight);
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    if(self.canMove){
        CGPoint translation = [recognizer translationInView:self];
        recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                             recognizer.view.center.y + translation.y);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self];
    }
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return true;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && ! self.canMove) {
        return NO;
    }
    return YES;
}

#pragma mark- Color Wheel

- (void)colorWheelDidChangeColor:(ISColorWheel *)colorWheel
{
    NSDictionary *ui = @{};
    for(NSDictionary *uiDict in self.UIArray){
         if(self.currentView.tag ==  [[uiDict objectForKey:@"tag"] intValue]){
             ui = uiDict;
         }
    }
    NSLog(@"UI:%@", ui);
    if([[ui objectForKey:@"type"] isEqualToString:@"UIView"]){
        NSLog(@"View");
        UIView *tempView = self.currentView;
        if(self.changingBackground == true){
            tempView.backgroundColor = self.colorPicker.currentColor;
            
        }
    }

    if([[ui objectForKey:@"type"] isEqualToString:@"UILabel"]){
        NSLog(@"Label");
        UILabel *tempLabel = self.currentView;
        if(self.changingBackground == true){
            tempLabel.backgroundColor = self.colorPicker.currentColor;
        }else{
            tempLabel.textColor = self.colorPicker.currentColor;
        }
    }
    
    if([[ui objectForKey:@"type"] isEqualToString:@"UIButton"]){
        UIButton *tempButton = self.currentView;
        if(self.changingBackground == true){
            tempButton.backgroundColor = self.colorPicker.currentColor;
        
        }else{
            tempButton.titleLabel.textColor = self.colorPicker.currentColor;
        }
    }

    
}

-(void)hideColorWheel{
    self.colorPicker.alpha = 0.0f;
    self.attributesView.alpha = 0.7f;
    self.closeAttributesButton.alpha = 1.0f;
}

-(void)showColorWheel{
    self.colorPicker.alpha = 1.0f;
    self.closeAttributesButton.alpha = 0.0f;
    [self.colorPicker bringSubviewToFront:self.closeColorPickerButton];
    [self bringSubviewToFront:self.closeColorPickerButton];
    [self bringSubviewToFront:self.colorPicker];
}

@end