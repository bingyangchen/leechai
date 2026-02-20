import 'package:flutter/material.dart';

const List<({String name, IconData icon})> expenseMainCategories = [
  (name: '飲食', icon: Icons.restaurant),
  (name: '交通', icon: Icons.directions_car),
  (name: '居家', icon: Icons.home),
  (name: '娛樂', icon: Icons.movie),
  (name: '購物', icon: Icons.shopping_bag),
  (name: '其他', icon: Icons.more_horiz),
];

const Map<int, List<String>> expenseSubCategories = {
  0: ['早餐', '午餐', '晚餐', '飲料', '零食', '超市'],
  1: ['捷運', '公車', '計程車', '油費', '停車'],
  2: ['房租', '水電', '瓦斯', '網路', '傢俱'],
  3: ['電影', '遊戲', '運動', '旅遊'],
  4: ['服飾', '日用品', '3C'],
  5: ['其他'],
};
