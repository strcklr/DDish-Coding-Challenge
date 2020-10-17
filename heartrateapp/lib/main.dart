import 'package:flutter/material.dart';
import 'blescan.dart';

void main() {
  runApp(HomeRoute());
}

class HomeRoute extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Rate Tracker',
      theme: ThemeData.dark(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted
      ),
      home: HomePage(title: 'Heart Rate Tracker'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentHeartRate = 0;
  int _maxHeartRate = 0;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _buildInfoColumn("Current heart rate", _currentHeartRate, Icons.favorite),
            _buildInfoColumn("Max heart rate", _maxHeartRate, Icons.whatshot),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ScanRoute())
          );
        },
        tooltip: 'Increment',
        child: new Icon(
            Icons.bluetooth,
            color: Colors.blueAccent
        ),
        backgroundColor: ThemeData.dark().bottomAppBarColor,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildInfoColumn(String label, int value, IconData icon) => Container(
    margin: const EdgeInsets.all(5),
    padding: const EdgeInsets.all(5) ,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
            ),
            Text(
              value == 0 ? "N/A" : value.toString(),
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
        Icon(
            icon,
            color: Colors.redAccent
        ),
      ],
    )
  );
}