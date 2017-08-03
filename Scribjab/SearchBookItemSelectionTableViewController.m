//
//  SearchBookItemSelectionTableViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 13-01-08.
//
//

#import "SearchBookItemSelectionTableViewController.h"
#import "AgeGroup.h"

@interface SearchBookItemSelectionTableViewController ()

@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation SearchBookItemSelectionTableViewController

@synthesize tag;
@synthesize delegate;
@synthesize parentPopover;

// ======================================================================================================================================
// Data Sourse
@synthesize dataSource = _dataSource;
-(void)setDataSource:(NSArray *)dataSource
{
    if (_dataSource != dataSource)
    {
        _dataSource = dataSource;
        [self.tableView reloadData];
    }
}

// ======================================================================================================================================
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}
// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark - Table view data source

// Return the number of sections.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_dataSource == nil)
        return 0;
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Search Item choice cell"];
    
    // Configure the cell...
    cell.textLabel.text = [[_dataSource objectAtIndex:indexPath.row] objectForKey:@"name"];
    return cell;
}

#pragma-mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate searchItemSelected:[_dataSource objectAtIndex:indexPath.row]];
}

@end
