import 'package:flutter/material.dart';
import 'ui.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: ClipRect( // Add ClipRect to clip content outside the Container
          child: Container(
            width: 360, // Mobile width (e.g., Galaxy S20)
            height: 640, // Mobile height
            color: Colors.black,
            child: BasketballGame(),
          ),
        ),
      ),
    ),
  ));
}