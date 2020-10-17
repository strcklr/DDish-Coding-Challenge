import 'package:flutter/material.dart';

class ScanRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScanPage(
        title: 'Bluetooth Scan'
    );
  }
}

class ScanPage extends StatefulWidget {
  ScanPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: new FloatingActionButton(
        onPressed: () {Navigator.pop(context);},
        backgroundColor: ThemeData.dark().bottomAppBarColor,
        child: new Icon(
          Icons.arrow_back,
          color: Colors.blue,
        ),
      ),
    );
  }
}