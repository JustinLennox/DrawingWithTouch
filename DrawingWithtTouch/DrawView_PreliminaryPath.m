//
//  DrawView.m
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import "DrawView_PreliminaryPath.h"
#import <WILLCore/WILLCore.h>

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
        [self addSubview:self.tableView];
        
        UITapGestureRecognizer *addUI = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addUI:)];
        addUI.numberOfTouchesRequired = 2;
        [self addGestureRecognizer:addUI];
        
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
        WCMFloatVectorPointer * prelimPath = [pathBuilder finishPreliminaryPath:smoothedPrelimPoints];
        [strokeRenderer drawPoints:pathAppendResult.addedPath finishStroke:wcmInputPhase == WCMInputPhaseEnd];
        [strokeRenderer drawPreliminaryPoints:prelimPath];
        
        
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

#pragma mark- Table View Methods

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
            UIButton *drawButton = [UIButton buttonWithType:UIButtonTypeCustom];
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


@end