import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// TODO: need to add internet permissions
// https://stackoverflow.com/questions/64197752/bad-state-insecure-http-is-not-allowed-by-platform

// TODO: implement stream.listen instead of StreamBuilder, because the latter skips values?
// https://stackoverflow.com/questions/54169848/streambuilder-not-receiving-some-snapshot-data?rq=1
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebSocketChannel _channel; // initialize channel
  HashMap<String, dynamic> _steamData; // initialize stream data

  @override
  void initState() {
    super.initState();

    // connect to private websocket. This websocket delivers a new value every 100 milliseconds
    _channel = IOWebSocketChannel.connect(
      'ws://142.93.238.122:8000/ws-3bebdd64-4f6f-4c62-a50b-5271bb06084c',
    );
  }

  @override // need this to close if we kill the homepage
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebSocket'),
      ),
      body: SafeArea(
        child: Container(
          child: StreamBuilder(
            stream: _channel.stream,
            initialData:
                HashMap<String, dynamic>(), //initialize with empty data
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) {
                // if errors return empty container?
                return Container(width: 0.0, height: 0.0);
              } else if (!snapshot.hasData) {
                // if no data return empty container?
                return Container(width: 0.0, height: 0.0);
              } else {
                try {
                  // convert incoming JSON object :
                  // the json object looks like this: {"players" :[[x, y], [x, y]]}
                  _steamData = new HashMap<String, dynamic>.from(
                    json.decode(snapshot.data),
                  );
                  return CustomPaint(
                    // if we have values use DotPainter to draw the dots on the canvas
                    painter: DotPainter(
                      playerCoords: _steamData['players'],
                    ),
                  );
                } catch (e) {
                  return Container(width: 0.0, height: 0.0);
                }
              }
            },
          ),
        ),
      ),

      // These buttons don't do much right now, but that's fine
      bottomNavigationBar: Row(
        children: [
          Expanded(
            child: FlatButton(
              color: Colors.blueAccent,
              child: Text('Play'),
              onPressed: () {},
            ),
          ),
          Expanded(
            child: FlatButton(
              color: Colors.redAccent,
              child: Text('Pause'),
              onPressed: () {
                _channel.sink.close();
              },
            ),
          )
        ],
      ),
    );
  }
}

class DotPainter extends CustomPainter {
  final List<dynamic> playerCoords;

  DotPainter({this.playerCoords});

  @override
  void paint(Canvas canvas, Size size) {
    final pointMode = ui.PointMode.points;

    // convert list of list to list of Offset()'s
    final points = playerCoords.map((dynamic player) {
      player = new List<dynamic>.from(player);
      return Offset(player[0], player[1]);
    }).toList();

    print(points);
    final spotPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(pointMode, points, spotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    throw true;
  }
}
