import 'dart:math';

class DiceLogic {
  static int getRandomDice() {
    return Random().nextInt(6) + 1;
  }
}