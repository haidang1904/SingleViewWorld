//
//  PhotoListViewController.m
//  SingleViewWorld
//
//  Created by samsung on 8/26/15.
//  Copyright (c) 2015 samsung. All rights reserved.
//

#import "PhotoListViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

@interface PhotoListViewController ()
{
    PHAsset *phLibrary;
    ALAssetsLibrary* library;
    NSMutableArray *gallery;
}
@end

@implementation PhotoListViewController
static NSString *cellID = @"PhotoListViewCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //   collection view init
    self.PhotoListCollectionView.scrollEnabled =YES;
    self.PhotoListCollectionView.delegate = self;
    self.PhotoListCollectionView.dataSource = self;
    self.PhotoListCollectionView.backgroundColor = [UIColor whiteColor];
    [self.PhotoListCollectionView registerNib:[UINib nibWithNibName:cellID bundle:nil] forCellWithReuseIdentifier:cellID];
 
    // Asset Lib Initialization - 사용하기 위하여 초기화
    library = [[ALAssetsLibrary alloc] init];
    phLibrary = [[PHAsset alloc] init];
    gallery = [NSMutableArray array];
    
    
    //그룹 정보를 얻어 오는 메소드
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
         if (group)
         {
             //해당 그룹 정보를 ALAsset 타입으로 읽어 들여 오기
             [self loadGroup:group];
         }
     }
    failureBlock:^(NSError *error){}
     ];
    
    /*
     ALAssetsLibrary         * assetsLibrary;
     
     void(^loadPhotosBlock)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset * photo, NSUInteger index, BOOL * stop){
     if( photo ){
     SVLogTEST(@"%@", [photo valueForProperty:ALAssetPropertyURLs]);
     }
     };
     void(^loadGroupsSucceedBlock)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup * group, BOOL * stop){
     if( group ){
     SVLogTEST(@"[%@]", [group valueForProperty:ALAssetsGroupPropertyName]);
     SVLogTEST(@"- Type : %@", [group valueForProperty:ALAssetsGroupPropertyType]);
     SVLogTEST(@"- PersistentID : %@", [group valueForProperty:ALAssetsGroupPropertyPersistentID]);
     SVLogTEST(@"- URL : %@", [group valueForProperty:ALAssetsGroupPropertyURL]);
     SVLogTEST(@"- NumberOfAssets : %d", [group numberOfAssets]);
     [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:loadPhotosBlock];
     }
     };
     void(^loadGroupsFailedBlock)(NSError *) = ^(NSError * error){
     SVLogTEST(@"Failed to load groups");
     SVLogTEST(@"%@", error);
     };
     assetsLibrary = [[ALAssetsLibrary alloc] init];
     [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
     usingBlock:loadGroupsSucceedBlock
     failureBlock:loadGroupsFailedBlock];
     */
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)loadGroup:(ALAssetsGroup *)group
{
    [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop)
     {
         if (asset)
         {
             //SVLogTEST(@"%d-%@",(int)index,asset);
             [gallery addObject:asset];
         }
     }];
    
    if (gallery.count > 0)
    {
        SVLogTEST(@"Reload");
        [self.PhotoListCollectionView reloadData];
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return gallery.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    _cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    if (_cell == nil) {
        _cell = [[PhotoListViewCell alloc] init];
    }
    ALAsset *asset = [[ALAsset alloc] init];
    //_cell.image.image = [UIImage imageNamed:@"test"];
    //_cell.filename.text = [NSString stringWithFormat:@"test-%ld",indexPath.row];
    _cell.backgroundColor = [UIColor greenColor];
    
    asset = gallery[indexPath.row];
    _cell.labelview.text = asset.defaultRepresentation.filename;
    _cell.imageview.image = [UIImage imageWithCGImage:asset.thumbnail];
    
    
    //CGImageRef *refimg = asset.defaultRepresentation.dimensions;
    SVLogTEST(@"%@:%f-%f",asset.defaultRepresentation.filename,asset.defaultRepresentation.dimensions.width,asset.defaultRepresentation.dimensions.height);
    
    return _cell;
}

-(void)findLargeImage
{
}

@end
