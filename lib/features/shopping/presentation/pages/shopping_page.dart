import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_app_bar.dart';

class ShopItem {
  final String id;
  final String title;
  final String description;
  final int price;
  final String imageUrl; // For now we will use colors or icons as placeholders

  const ShopItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
  });
}

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final int _itemsPerPage = 8;
  int _currentPage = 0;

  final List<ShopItem> _allItems = [
    const ShopItem(
      id: '1',
      title: '펫로스 증후군',
      description: '반려동물과의 이별, 그 슬픔을 치유하는 여정. 상실감을 이해하고 건강하게 애도하는 방법을 배웁니다.',
      price: 15000,
      imageUrl: 'assets/images/pet_loss.png', // Placeholder
    ),
    const ShopItem(
      id: '2',
      title: '번아웃 극복하기',
      description: '지친 마음을 다시 일으키는 에너지 충전법. 업무 스트레스와 무기력증에서 벗어나 나를 되찾는 시간입니다.',
      price: 12000,
      imageUrl: 'assets/images/burnout.png',
    ),
    const ShopItem(
      id: '3',
      title: '자기주장 훈련',
      description: '나를 지키면서 건강하게 소통하는 방법. 거절이 어렵거나 주눅 드는 당신을 위한 실전 대화 가이드입니다.',
      price: 10000,
      imageUrl: 'assets/images/assertiveness.png',
    ),
    // Dummy Data
    ...List.generate(
      15,
      (index) => ShopItem(
        id: '${index + 4}',
        title: '테스트 콘텐츠 ${index + 1}',
        description: '이것은 테스트 콘텐츠 ${index + 1}의 설명입니다. 여기에 긴 설명글이 들어갑니다. 두 줄 이상으로 표시될 수 있도록 충분히 길게 작성합니다.',
        price: 5000 + (index * 1000),
        imageUrl: 'placeholder',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final totalPages = (_allItems.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < _allItems.length)
        ? startIndex + _itemsPerPage
        : _allItems.length;
    final currentItems = _allItems.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: const CommonAppBar(title: '콘텐츠 마켓'),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: currentItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildShopItemCard(currentItems[index]);
              },
            ),
          ),
          _buildPagination(totalPages),
        ],
      ),
    );
  }

  Widget _buildShopItemCard(ShopItem item) {
    return Container(
      height: 120, // Fixed height for list item
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image / Icon Placeholder
          Container(
            width: 100, // Fixed width for image
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(
                Icons.psychology,
                size: 40,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Text Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '₩${item.price}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          final isActive = index == _currentPage;
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentPage = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppTheme.primaryColor : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
