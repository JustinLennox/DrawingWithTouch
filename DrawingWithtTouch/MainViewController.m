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
    
    self.view.backgroundColor = [UIColor colorWithRed:(52.0/255.0) green:(152.0/255.0) blue:(219.0/255.0) alpha:1.0];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor =  [UIColor colorWithRed:(52.0/255.0) green:(152.0/255.0) blue:(219.0/255.0) alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    self.addChillBackground = [[UIView alloc] init];
    self.addChillBackground.frame = self.view.frame;
    self.addChillBackground.alpha = 0.0f;
    self.addChillBackground.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self.view addSubview:self.addChillBackground];
    
    self.addChillView = [[UIView alloc] init];
    self.addChillView.frame = CGRectMake(self.view.frame.size.width * 0.1, self.view.frame.size.height * 0.33, self.view.frame.size.width * 0.8, self.view.frame.size.height * 0.1);
    self.addChillView.alpha = 0.0f;
    self.addChillView.backgroundColor = [UIColor grayColor];
    self.addChillView.layer.cornerRadius = 8.0;
    self.addChillView.layer.masksToBounds = true;
    [self.view addSubview:self.addChillView];
    
    self.addChillTitle = [[UITextField alloc] init];
    self.addChillTitle.frame = CGRectMake(0, 0, self.addChillView.frame.size.width, self.addChillView.frame.size.height);
    self.addChillTitle.backgroundColor = [UIColor colorWithRed:(128.0/255.0) green: (222.0/255.0) blue: (234.0/255.0) alpha: 1.0];
    self.addChillTitle.textColor = [UIColor whiteColor];
    self.addChillTitle.returnKeyType = UIReturnKeyDone;
    self.addChillTitle.layer.masksToBounds = true;
    self.addChillTitle.delegate = self;
    self.addChillTitle.textAlignment = NSTextAlignmentCenter;
    self.addChillTitle.placeholder = @"Title Your InkUp";
    self.addChillTitle.font = [UIFont fontWithName:@"Helvetica-Bold" size:25.0f];
    self.addChillTitle.tintColor = [UIColor whiteColor];
    [self.addChillView addSubview:self.addChillTitle];
    
    drawViewClasses = @[
                         [DrawView_PreliminaryPath class],

                         ];
}

- (IBAction) partButtonPressed:(id)sender
{
    drawView = [[DrawView_PreliminaryPath alloc] initWithFrame:self.view.frame];
     drawView.mainController = self;
     [self.view addSubview:drawView];
     
     _backButton.hidden = YES;
     [self.view bringSubviewToFront:_backButton];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    [self.tableView reloadData];

}

- (IBAction) back:(id)sender
{
    [drawView removeFromSuperview];
    _backButton.hidden = YES;
}
- (IBAction)gnuInkPressed:(id)sender {
    self.addChillBackground.alpha = 1.0f;
    self.addChillView.alpha = 1.0f;
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    self.addChillBackground.alpha = 0.0f;
    self.addChillView.alpha = 0.0f;
    if(self.addChillTitle.text.length > 0){
        [[NSUserDefaults standardUserDefaults] setObject:self.addChillTitle.text forKey:@"CurrentTitle"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        drawView = [[DrawView_PreliminaryPath alloc] initWithFrame:self.view.frame];
        drawView.mainController = self;
        [self.view addSubview:drawView];
        
        _backButton.hidden = YES;
        [self.view bringSubviewToFront:_backButton];
        
    }
    self.addChillTitle.text = @"";

    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


#pragma mark - Table View

#pragma mark- Table View Methods


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"InkUps"]){
        NSArray *inkUpArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"InkUps"];
        return inkUpArray.count + 1;
    }else{
        return 1;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //    NSLog(@"Height:%f",(self.view.frame.size.height - 93)/5.0f);
    //    NSLog(@"View height:%f", self.view.frame.size.height);
    return 320.0f;
}


-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellIdentifier = @"cell";
    
    InkUpTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil){
        cell = [[InkUpTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        if(indexPath.row == 0){
            cell.titleLabel.text = @"Create New";
        }
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"InkUps"] && indexPath.row > 0){
            NSArray *inkUpArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"InkUps"];
            NSDictionary *inkUp = [inkUpArray objectAtIndex:indexPath.row - 1];
            cell.titleLabel.text = [inkUp objectForKey:@"title"];
            cell.imageView.image = [UIImage imageWithData:[inkUp objectForKey:@"image"]];
        }
        int rand = arc4random() % 4;
        if(rand == 0){
            cell.backgroundColor = [UIColor colorWithRed:(52.0/255.0) green:(152.0/255.0) blue:(219.0/255.0) alpha:1.0f];
        }else if(rand == 1){
            cell.backgroundColor = [UIColor colorWithRed:(231.0/255.0) green:(76.0/255.0) blue:(60.0/255.0) alpha:1.0f];
        }else if(rand == 2){
            cell.backgroundColor = [UIColor colorWithRed:(26.0/255.0) green:(188.0/255.0) blue:(156.0/255.0) alpha:1.0f];
        }else if(rand == 3){
            cell.backgroundColor = [UIColor colorWithRed:(241.0/255.0) green:(196.0/255.0) blue:(15.0/255.0) alpha:1.0f];
        }
 }
    
    return cell;
}

-(void)reloadT{
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row == 0){
        self.addChillBackground.alpha = 1.0f;
        self.addChillView.alpha = 1.0f;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}


@end
