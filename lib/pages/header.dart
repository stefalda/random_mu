import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String title;
  const Header({super.key, this.title = "Random Muu(sic)"});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
          height: 40,
          width: 40,
          child: Image.asset(
            "assets/icon_white.png",
            color: Colors.white,
            height: 50,
            width: 50,
            fit: BoxFit.contain,
          )),
      SizedBox(width: 20),
      Text(title)
    ]);
  }
}
