//
//  SelectPhotoViewController.m
//  SelectPhoto
//
//  Created by wangtian on 15/7/23.
//  Copyright (c) 2015年 wangtian. All rights reserved.
//

#import "SelectPhotoViewController.h"

#define PopKeyWinow  [[UIApplication sharedApplication] keyWindow]

@interface SelectPhotoViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UIView *bgView;
@property (weak, nonatomic) IBOutlet UIButton *firstBtn;

@end

@implementation SelectPhotoViewController

- (UIView *)bgView
{
    if (_bgView == nil)
    {
        _bgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _bgView.backgroundColor = [UIColor blackColor];
        _bgView.alpha = 0.0f;
    }
    return _bgView;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpView];
    // Do any additional setup after loading the view from its nib.
}

- (void)setUpView
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGRect viewFrame = self.view.frame;
    viewFrame.size.width = screenSize.width;
    viewFrame.origin.y = screenSize.height;
    
    self.view.frame = viewFrame;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCell" bundle:nil] forCellWithReuseIdentifier:PhotoCell_Identifier];
}

- (void)configueDataSource
{
    if (self.dataSource == nil)
    {
        __weak typeof(self) weakSelf = self;
        [NSObject beginCountTime];
        [SPhotoModel getLocalVideoWithFinishBlock:^(RequestResult *result) {
            
            weakSelf.dataSource = [NSMutableArray arrayWithArray:result.dataDic];
            [weakSelf updateFirstBtnState];
            [weakSelf.collectionView reloadData];
            NSLog(@"最终用时%.2f",[NSObject endConutTime]);
        }];
    }
    else
    {
        [self.dataSource enumerateObjectsUsingBlock:^(SPhotoModel *obj, NSUInteger idx, BOOL *stop) {
            
            obj.isSelect = NO;
        }];
        [self.collectionView reloadData];
        [self updateFirstBtnState];
    }
}

- (void)showOrHiddenSelectPhotoView
{
    CGFloat viewY = self.view.frame.origin.y;
    CGFloat bgViewAlpla;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat changeY;
    if (viewY == screenSize.height)
    {
        changeY = screenSize.height - self.view.frame.size.height;
        bgViewAlpla = 0.6;
        [self configueDataSource];//重新加载
    }
    else
    {
        changeY = screenSize.height;
        bgViewAlpla = 0.0;
    }
    if (![self.bgView isDescendantOfView:PopKeyWinow])
    {
        [PopKeyWinow addSubview:self.bgView];
    }
    if (![self.view isDescendantOfView:PopKeyWinow])
    {
        [PopKeyWinow addSubview:self.view];
    }
    [UIView animateWithDuration:0.3f animations:^{
        
        CGRect viewFrame = self.view.frame;
        viewFrame.origin.y = changeY;
        self.view.frame = viewFrame;
        
        self.bgView.alpha = bgViewAlpla;
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SPhotoModel *model = self.dataSource[indexPath.row];
    
    CGSize defaultSize = PhotoCell_Size;
    defaultSize.width = defaultSize.height * model.bili;
   
    return defaultSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PhotoCell_Identifier forIndexPath:indexPath];
    
    [cell configueCellWithModel:self.dataSource[indexPath.row]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SPhotoModel *model = self.dataSource[indexPath.row];
    model.isSelect = !model.isSelect;
    [self updateFirstBtnState];
    NSIndexPath *path = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    [self.collectionView reloadItemsAtIndexPaths:@[path]];
}

#pragma mark - 更新第一个按钮的状态
- (void)updateFirstBtnState
{
    NSMutableArray *selectModelArray = [self getSelectModelArray];
    UIColor *btnTextColor;
    NSString *btnTitle;
    if (selectModelArray.count > 0)
    {
        btnTitle = [NSString stringWithFormat:@"发送（%lu张）",(unsigned long)selectModelArray.count];
        btnTextColor = [UIColor greenColor];
    }
    else
    {
        btnTitle = @"拍摄";
        btnTextColor = [UIColor blackColor];
    }
    [self.firstBtn setTitleColor:btnTextColor forState:(UIControlStateNormal)];
    [self.firstBtn setTitle:btnTitle forState:(UIControlStateNormal)];
}

#pragma mark - 获得被选中的照片model数组
- (NSMutableArray *)getSelectModelArray
{
    NSMutableArray *selectArray = [[NSMutableArray alloc] init];
    
    [self.dataSource enumerateObjectsUsingBlock:^(SPhotoModel *obj, NSUInteger idx, BOOL *stop) {
        
        if (obj.isSelect)
        {
            [selectArray addObject:obj];
        }
    }];
    return selectArray;
}

#pragma mark - 下面几个按钮被点击
- (IBAction)btnClick:(UIButton *)sender
{
    NSMutableArray *photoArray = [SPhotoModel getImagesWithModelArray:[self getSelectModelArray]];
    switch (sender.tag)
    {
        case 0://取消
        {
            [self showOrHiddenSelectPhotoView];
            break;
        }
        case 1://拍摄
        {
            if (self.selectPhotoBlock && photoArray.count > 0)
            {
                self.selectPhotoBlock(photoArray);
            }
            else
            {
                if (self.setClickBtnBlock)
                {
                    self.setClickBtnBlock(1);
                }
            }
            [self showOrHiddenSelectPhotoView];
            break;
        }
        case 2://从相册选择
        {
            self.setClickBtnBlock(2);
            [self showOrHiddenSelectPhotoView];
            break;
        }
            
        default:
            break;
    }
}

- (void)releaseSelf
{
    [self.bgView removeFromSuperview];
    [self.view removeFromSuperview];
    [SPhotoModel releaseResource];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
