import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmojiSelectionScreen extends StatefulWidget {
  final String currentEmojiPath;
  final Function(String) onEmojiSelected;
  final VoidCallback? onBack;

  const EmojiSelectionScreen({
    super.key,
    required this.currentEmojiPath,
    required this.onEmojiSelected,
    this.onBack,
  });

  @override
  State<EmojiSelectionScreen> createState() => _EmojiSelectionScreenState();
}

class _EmojiSelectionScreenState extends State<EmojiSelectionScreen> {
  String _selectedEmojiPath = '';

  @override
  void initState() {
    super.initState();
    _selectedEmojiPath = widget.currentEmojiPath;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 36),
          // 이모지 그리드
          Expanded(child: _buildEmojiGrid()),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid() {
    // 모든 이모지 파일명 리스트
    final List<String> emojiFiles = [
      'Avocado.png',
      'Baby_Bottle.png',
      'Bacon.png',
      'Bagel.png',
      'Baguette_Bread.png',
      'Banana.png',
      'Beer_Mug.png',
      'Bell_Pepper.png',
      'Bento_Box.png',
      'Beverage_Box.png',
      'Birthday_Cake.png',
      'Blueberries.png',
      'Bone.png',
      'Bottle_With_Popping_Cork.png',
      'Bowl_With_Spoon.png',
      'Bread.png',
      'Broccoli.png',
      'Bubble_Tea.png',
      'Burrito.png',
      'Butter.png',
      'Candy.png',
      'Canned_Food.png',
      'Carrot.png',
      'Cheese_Wedge.png',
      'Cherries.png',
      'Chestnut.png',
      'Chocolate_Bar.png',
      'Chopsticks.png',
      'Clinking_Beer_Mugs.png',
      'Clinking_Glasses.png',
      'Cocktail_Glass.png',
      'Coconut.png',
      'Cooked_Rice.png',
      'Cookie.png',
      'Cooking.png',
      'Croissant.png',
      'Cucumber.png',
      'Cup_With_Straw.png',
      'Cupcake.png',
      'Curry_Rice.png',
      'Custard.png',
      'Cut_Of_Meat.png',
      'Dango.png',
      'Doughnut.png',
      'Dumpling.png',
      'Ear_Of_Corn.png',
      'Egg.png',
      'Eggplant.png',
      'Falafel.png',
      'Flatbread.png',
      'Fondue.png',
      'Fork_And_Knife.png',
      'Fork_And_Knife_With_Plate.png',
      'Fortune_Cookie.png',
      'French_Fries.png',
      'Fried_Shrimp.png',
      'Garlic.png',
      'Glass_Of_Milk.png',
      'Grapes.png',
      'Green_Apple.png',
      'Green_Salad.png',
      'Hamburger.png',
      'Honey_Pot.png',
      'Hot_Beverage.png',
      'Hot_Dog.png',
      'Hot_Pepper.png',
      'Ice.png',
      'Ice_Cream.png',
      'Kitchen_Knife.png',
      'Kiwi_Fruit.png',
      'Leafy_Green.png',
      'Lemon.png',
      'Lollipop.png',
      'Mango.png',
      'Mate.png',
      'Meat_On_Bone.png',
      'Melon.png',
      'Moon_Cake.png',
      'Mushroom.png',
      'Oden.png',
      'Olive.png',
      'Onion.png',
      'Oyster.png',
      'Pancakes.png',
      'Peach.png',
      'Peanuts.png',
      'Pear.png',
      'Pie.png',
      'Pineapple.png',
      'Pizza.png',
      'Popcorn.png',
      'Pot_Of_Food.png',
      'Potato.png',
      'Poultry_Leg.png',
      'Pretzel.png',
      'Red_Apple.png',
      'Rice_Ball.png',
      'Rice_Cracker.png',
      'Roasted_Sweet_Potato.png',
      'Sake.png',
      'Salt.png',
      'Sandwich.png',
      'Shallow_Pan_Of_Food.png',
      'Shaved_Ice.png',
      'Shortcake.png',
      'Soft_Ice_Cream.png',
      'Spaghetti.png',
      'Spoon.png',
      'Steaming_Bowl.png',
      'Strawberry.png',
      'Stuffed_Flatbread.png',
      'Sushi.png',
      'Taco.png',
      'Takeout_Box.png',
      'Tamale.png',
      'Tangerine.png',
      'Teacup_Without_Handle.png',
      'Tomato.png',
      'Tropical_Drink.png',
      'Tumbler_Glass.png',
      'Waffle.png',
      'Watermelon.png',
      'Wine_Glass.png',
    ];

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1, // 60x60 정사각형
      ),
      itemCount: emojiFiles.length,
      itemBuilder: (context, index) {
        final emojiPath = 'assets/images/food_images/${emojiFiles[index]}';
        final isSelected = _selectedEmojiPath == emojiPath;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedEmojiPath = emojiPath;
            });
            // 이모지 선택 시 바로 적용하고 음식 디테일 페이지로 돌아가기
            widget.onEmojiSelected(emojiPath);
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF814083)
                  : const Color(0xFFEAECF0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Image.asset(
                emojiPath,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.error,
                    size: 40,
                    color: Color(0xFF686C75),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
