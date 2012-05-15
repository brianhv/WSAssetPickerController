//
//  W5AssetTableViewController.m
//  W5AssetPickerController
//
//  Created by Wesley Smith on 5/12/12.
//  Copyright (c) 2012 Wesley D. Smith. All rights reserved.
//

// Tips from:
// ELC iCodeBlog - 
// NSScreencast - http://nsscreencast.com/episodes/8-automatic-uitableview-paging

#import "W5AssetTableViewController.h"
#import "W5AssetsTableViewCell.h"
#import "W5AssetPickerController.h"


#define FETCH_SIZE 25
#define ASSETS_PER_ROW_V 4
#define ASSETS_PER_ROW_H 6

@interface W5AssetTableViewController ()
@property (nonatomic, strong) NSMutableArray *fetchedAssets;
@property (nonatomic, readonly) NSInteger assetsPerRow;
@property (nonatomic) NSInteger currentPage;
@property (nonatomic) NSInteger totalPages;
@end


@implementation W5AssetTableViewController

@synthesize assetsGroup = _assetsGroup;
@synthesize fetchedAssets = _fetchedAssets;
@synthesize assetsPerRow =_assetsPerRow;
@synthesize currentPage = _currentPage;
@synthesize totalPages = _totalPages;

#pragma mark - View Lifecycle

#define TABLEVIEW_INSETS UIEdgeInsetsMake(2, 0, 2, 0);

- (void)viewDidLoad
{
    self.navigationItem.title = @"Loading";
    
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                                                           target:self 
                                                                                           action:@selector(doneButtonAction:)];
    
    // TableView configuration.
    self.tableView.contentInset = TABLEVIEW_INSETS;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.allowsSelection = NO;
    
    
    // Setup paging info.
    self.totalPages = ceil(((double)self.assetsGroup.numberOfAssets / (double)self.assetsPerRow) / (double)FETCH_SIZE);
    self.currentPage = 0;   
}


#pragma mark - Getters

- (NSMutableArray *)fetchedAssets
{
    if (!_fetchedAssets) {
        _fetchedAssets = [NSMutableArray arrayWithCapacity:FETCH_SIZE];
    }
    return _fetchedAssets;
}

- (NSInteger)assetsPerRow
{
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || 
        self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        
        return ASSETS_PER_ROW_H;
    } else {
        return ASSETS_PER_ROW_V;
    }
}


#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}


#pragma mark - Fetching Code

- (void)fetchAssets
{
    DLog(@"PAGE: %d", self.currentPage);
    
    NSRange fetchRange;
    fetchRange.location = (self.currentPage * FETCH_SIZE) * self.assetsPerRow;
    fetchRange.length = FETCH_SIZE * self.assetsPerRow; // TODO: Change this to work with orientation changes.
 
    // Prevent fetching beyond numberOfAssets.
    if (fetchRange.length > self.assetsGroup.numberOfAssets - fetchRange.location) {
        fetchRange.length = self.assetsGroup.numberOfAssets - fetchRange.location;
    }
    
    DLog(@"New fetch: %d -> %d (of %d)", fetchRange.location, fetchRange.length, self.assetsGroup.numberOfAssets);
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:fetchRange];    
    [self.assetsGroup enumerateAssetsAtIndexes:indexSet 
                                       options:NSEnumerationConcurrent
                                    usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                        
                                        if (result) {
                                            //DLog(@"Fetched asset: %@", result);
                                            [self.fetchedAssets addObject:result];
                                        }
                                        
                                        if (!result || index == NSNotFound) {
                                            DLog(@"Done fetching.");
                                        }
                                    }];

    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
}

#pragma mark - Actions

- (void)doneButtonAction:(id)sender
{        
    // The navigationController is actually a subclass of W5AssetPickerController. It's delegate conforms to the
    // W5AssetPickerControllerDelegate protocol, an extended version of the UINavigationControllerDelegate protocol.
    id <W5AssetPickerControllerDelegate> delegate = (id <W5AssetPickerControllerDelegate>)self.navigationController.delegate;
    
    if ([delegate respondsToSelector:@selector(assetPickerController:didFinishPickingMediaWithInfo:)]) {
        
        [delegate assetPickerController:(W5AssetPickerController *)self.navigationController didFinishPickingMediaWithInfo:nil];
    }
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Show a loading cell.
    if (self.currentPage == 0) {
        
        return 1;
    } else if (self.currentPage  < self.totalPages) {
        
        return (self.fetchedAssets.count / self.assetsPerRow) + 1; // TODO: Change this to work with orientation changes.
    } else {
        
        return self.fetchedAssets.count / self.assetsPerRow;
    }   
}

- (NSArray *)assetsForIndexPath:(NSIndexPath *)indexPath
{    
    NSRange assetRange;
    assetRange.location = indexPath.row * self.assetsPerRow;
    assetRange.length = self.assetsPerRow;
    
    // Prevent the range from exceeding the array length.
    if (assetRange.length > self.fetchedAssets.count - assetRange.location) {
        assetRange.length = self.fetchedAssets.count - assetRange.location;
    }
    
    DLog(@"Getting assets: %d -> %d (of %d) --- for row: %d", assetRange.location, assetRange.length, self.fetchedAssets.count, indexPath.row);
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:assetRange];
    
    return [self.fetchedAssets objectsAtIndexes:indexSet];
}

- (UITableViewCell *)assetCellForIndexPath:(NSIndexPath *)indexPath
{
    static NSString *AssetCellIdentifier = @"W5AssetCell";
    W5AssetsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:AssetCellIdentifier];
    
    if (cell == nil) {
        
        cell = [[W5AssetsTableViewCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:AssetCellIdentifier];
        
    } else {
        
        cell.cellAssetViews = [self assetsForIndexPath:indexPath];
    }
    
    return cell;
}

- (UITableViewCell *)loadingCell
{
    static NSString *LoadingCellIdentifier = @"W5LoadingCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:LoadingCellIdentifier];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadingCellIdentifier];
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityView.center = cell.center;
        activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | 
        UIViewAutoresizingFlexibleRightMargin | 
        UIViewAutoresizingFlexibleTopMargin | 
        UIViewAutoresizingFlexibleBottomMargin;
        
        [cell addSubview:activityView];
        [activityView startAnimating];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < (self.fetchedAssets.count / self.assetsPerRow)) {
               
        return [self assetCellForIndexPath:indexPath];
    } else {
        
        return [self loadingCell];
    }
}


#pragma mark - Table view delegate

#define ROW_HEIGHT 79.0f

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{ 
	return ROW_HEIGHT;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell.reuseIdentifier isEqualToString:@"W5LoadingCell"]) {
        [self fetchAssets];
        self.currentPage++;
    }
}

@end
