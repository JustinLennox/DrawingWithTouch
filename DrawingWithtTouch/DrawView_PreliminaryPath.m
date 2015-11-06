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
        
        self.tableView = [[UITableView alloc] initWithFrame:self.frame];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.alpha = 0.0f;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [self addSubview:self.tableView];
        
        UITapGestureRecognizer *addUI = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addUI:)];
        addUI.numberOfTouchesRequired = 2;
        [self addGestureRecognizer:addUI];
        
        UITapGestureRecognizer *optionTouch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showEmail:)];
        optionTouch.numberOfTapsRequired = 3;
        [self addGestureRecognizer:optionTouch];
        self.drawing = false;
        self.canDraw = false;
        
        
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
    return 2;
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
        cell = [[UIElementTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    self.elementNumber = (int)indexPath.row;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.tableView.alpha = 0.0f;
    self.canDraw = true;
    
}



#pragma mark- Gesture Recognizers

-(void)addUI : (UITapGestureRecognizer *) sender{
    self.drawing = false;
    if(sender.state == UIGestureRecognizerStateEnded){
        NSLog(@"Can draw");
        [self bringSubviewToFront:self.tableView];
        self.tableView.alpha = 1.0f;
    }
}

#pragma mark- Add UI Element

-(void)addUIElementWithFrame : (CGRect) uiFrame{
    switch (self.elementNumber) {
        case 0:{
            UIButton *drawButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [drawButton setTitle:@"Button" forState:UIControlStateNormal];
            drawButton.adjustsImageWhenHighlighted = true;
            [drawButton setBackgroundImage:[self imageFromLayer:self.currentShapeLayer] forState:UIControlStateNormal];
            [drawButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [drawButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
            [drawButton setFrame:uiFrame];
            [drawButton setBackgroundColor:[UIColor colorWithRed:0.33f green:0.20f blue:0.9f alpha:0.5f]];
            [self addSubview:drawButton];
            break;
        }
            
        case 1:{
            UILabel *drawLabel = [[UILabel alloc] initWithFrame:uiFrame];
            drawLabel.backgroundColor = [UIColor lightGrayColor];
            drawLabel.text = @"Label";
            drawLabel.alpha = 0.5f;
            drawLabel.textAlignment = NSTextAlignmentCenter;
            drawLabel.textColor = [UIColor whiteColor];
            [self addSubview:drawLabel];
        }
        default:
            break;
    }
}

#pragma mark- Writing and Saving Text File

-(void)createHeader{
    
    NSString *headerString =
    @"#import <UIKit/UIKit.h>\n\n@interface InkUpViewController : UIViewController\n\n\n@end";
    [self writeStringToFile:headerString named:@"InkUpViewController.h"];
}

-(void)createImplementation{
    
    NSArray *uiArray = @[@{@"name":@"button1",@"type":@"UIButton",@"frame":@"CGRectMake(0,0,100,100)", @"text":@"Hello!"}, @{@"name":@"label2",@"type":@"UILabel",@"frame":@"CGRectMake(100,100,100,100)", @"text":@"Hi!"}];
    NSString *mainUIString = @"";
    
    for(NSDictionary *ui in uiArray){
        NSString *type = [ui objectForKey:@"type"];
        NSString *name = [ui objectForKey:@"name"];
        NSString *frame = [ui objectForKey:@"frame"];
        NSString *line1 = [NSString stringWithFormat:@"    %@ *%@ = [[%@ alloc] init];", type, name, type];
        NSString *line2 = [NSString stringWithFormat:@"    %@.frame = %@;", name, frame];
        NSString *line3 = @"";
        if([type isEqualToString:@"UILabel"] && [ui objectForKey:@"text"]){
            line3 = [NSString stringWithFormat:@"    %@.text = @\"%@\";", name, [ui objectForKey:@"text"]];
        }else if([type isEqualToString:@"UIButton"] && [ui objectForKey:@"text"]){
            line3 = [NSString stringWithFormat:@"    [%@ setTitle:@\"%@\" forState:UIControlStateNormal];", name, [ui objectForKey:@"text"]];
        }
        NSString *line4 = [NSString stringWithFormat:@"    [self.view addSubview:%@];", name];
        NSString *combinedLines = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n", line1, line2, line3, line4];
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
    NSString *messageBody = @"Here's the InkUp for my prototype";
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


@end