import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(FlowerGardenApp());
}

class FlowerGardenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flower Garden Game',
      theme: ThemeData(primarySwatch: Colors.green),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int score = 0;
  int lives = 3;
  int timeRemaining = 60;
  bool gameRunning = true;
  bool gameOver = false;
  
  Timer? gameTimer;
  List<Flower> flowers = [];
  List<Mushroom> mushrooms = [];
  Offset? playerPosition = Offset(200, 200);
  
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    // 延遲一幀再開始遊戲，確保 context 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startGame();
    });
  }

  void startGame() {
    // 生成初始蘑菇
    generateMushrooms();
    
    // 開始計時器
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          endGame("時間到！");
        }
      });
    });
  }

  void generateMushrooms() {
    mushrooms.clear();
    for (int i = 0; i < 5; i++) {
      mushrooms.add(Mushroom(
        x: 50 + random.nextDouble() * 300,
        y: 50 + random.nextDouble() * 500,
      ));
    }
  }

  void onTapDown(TapDownDetails details) {
    if (!gameRunning) return;

    final tapPosition = details.localPosition;
    
    // 移動玩家角色
    setState(() {
      playerPosition = tapPosition;
    });

    // 檢查是否碰到蘑菇
    bool hitMushroom = false;
    for (int i = mushrooms.length - 1; i >= 0; i--) {
      if (checkCollision(tapPosition, mushrooms[i])) {
        setState(() {
          lives--;
          mushrooms.removeAt(i);
          hitMushroom = true;
        });
        
        if (lives <= 0) {
          endGame("遊戲結束！");
          return;
        }
        break;
      }
    }

    // 如果沒碰到蘑菇，種花加分
    if (!hitMushroom) {
      setState(() {
        flowers.add(Flower(x: tapPosition.dx, y: tapPosition.dy));
        score++;
      });
    }

    // 重新生成蘑菇
    generateMushrooms();
  }

  bool checkCollision(Offset tapPos, Mushroom mushroom) {
    double distance = sqrt(
      pow(tapPos.dx - mushroom.x, 2) + pow(tapPos.dy - mushroom.y, 2)
    );
    return distance < 30; // 碰撞範圍
  }

  void endGame(String message) {
    setState(() {
      gameRunning = false;
      gameOver = true;
    });
    gameTimer?.cancel();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          content: Text('最終得分: $score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                restartGame();
              },
              child: Text('重新開始'),
            ),
          ],
        );
      },
    );
  }

  void restartGame() {
    setState(() {
      score = 0;
      lives = 3;
      timeRemaining = 60;
      gameRunning = true;
      gameOver = false;
      flowers.clear();
      mushrooms.clear();
      playerPosition = Offset(200, 200);
    });
    startGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('種花遊戲'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // 遊戲資訊欄
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.green[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('得分: $score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('生命: $lives', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('時間: $timeRemaining', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // 遊戲說明
          Container(
            padding: EdgeInsets.all(8),
            child: Text(
              '點擊種花得分！避免點到紅色蘑菇，否則會失去生命！',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 遊戲區域
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.lightGreen[50],
              child: GestureDetector(
                onTapDown: onTapDown,
                child: CustomPaint(
                  painter: GamePainter(
                    flowers: flowers,
                    mushrooms: mushrooms,
                    playerPosition: playerPosition,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final List<Flower> flowers;
  final List<Mushroom> mushrooms;
  final Offset? playerPosition;

  GamePainter({
    required this.flowers,
    required this.mushrooms,
    this.playerPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 畫花朵
    for (Flower flower in flowers) {
      drawFlower(canvas, flower);
    }

    // 畫蘑菇
    for (Mushroom mushroom in mushrooms) {
      drawMushroom(canvas, mushroom);
    }

    // 畫玩家角色
    if (playerPosition != null) {
      drawPlayer(canvas, playerPosition!);
    }
  }

  void drawFlower(Canvas canvas, Flower flower) {
    final paint = Paint();
    
    // 花瓣
    paint.color = Colors.pink;
    canvas.drawCircle(Offset(flower.x - 10, flower.y), 8, paint);
    canvas.drawCircle(Offset(flower.x + 10, flower.y), 8, paint);
    canvas.drawCircle(Offset(flower.x, flower.y - 10), 8, paint);
    canvas.drawCircle(Offset(flower.x, flower.y + 10), 8, paint);
    
    // 花心
    paint.color = flower.centerColor;
    canvas.drawCircle(Offset(flower.x, flower.y), 6, paint);
  }

  void drawMushroom(Canvas canvas, Mushroom mushroom) {
    final paint = Paint();
    
    // 蘑菇帽
    paint.color = Colors.red;
    canvas.drawCircle(Offset(mushroom.x, mushroom.y - 10), 15, paint);
    
    // 蘑菇柄
    paint.color = Colors.brown[100]!;
    canvas.drawRect(
      Rect.fromLTWH(mushroom.x - 5, mushroom.y, 10, 20),
      paint,
    );
  }

  void drawPlayer(Canvas canvas, Offset position) {
    final paint = Paint()..color = Colors.blue;
    canvas.drawCircle(position, 8, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class Flower {
  final double x;
  final double y;
  final Color centerColor;

  Flower({required this.x, required this.y})
      : centerColor = _getRandomColor();

  static Color _getRandomColor() {
    final colors = [
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.red,
    ];
    return colors[Random().nextInt(colors.length)];
  }
}

class Mushroom {
  final double x;
  final double y;

  Mushroom({required this.x, required this.y});
}