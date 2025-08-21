import 'package:get/get.dart';

class NavbarController extends GetxController{
  var currentIndex = 0.obs;

  void changTab(int index){
    currentIndex.value=index;
  }
}