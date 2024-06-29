import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shooting Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ShootingGame(),
    );
  }
}

class ShootingGame extends StatefulWidget {
  const ShootingGame({Key? key}) : super(key: key);

  @override
  _ShootingGameState createState() => _ShootingGameState();
}

class _ShootingGameState extends State<ShootingGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Target> _targets = [];
  int _score = 0;
  int _timeLeft = 60;
  int _currentRound = 1;
  double _targetSpeed = 2.5;
  int _maxVisibleTargets = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), // 1 minute game duration
    );

    _controller.forward();

    _controller.addListener(_controllerListener);

    // Start adding targets immediately
    _addTargets();

    // Start the countdown timer
    _startTimer();
  }

  void _startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          _showResultDialog();
        }
      });
    });
  }

  void _showResultDialog() {
    String message = (_score >= 70) ? 'Congratulations, you passed!' : 'Sorry, you lost!';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score: $_score'),
              Text('Message: $message'),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _nextRound();
                },
                child: Text('Next Round'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _nextRound() {
    setState(() {
      _currentRound++;
      _targetSpeed += 0.2;
      _score = 0;
      _timeLeft = 60;
      _targets.clear();
      _addTargets();
      _controller.reset();
      _controller.forward();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _controllerListener() {
    setState(() {
      _targets.forEach((target) {
        target.updatePosition();
        if (target.isOut()) {
          _resetTarget(target);
        }
      });
    });
  }

  void _resetTarget(Target target) {
    Size screenSize = MediaQuery.of(context).size;
    target.reset(screenSize);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Round $_currentRound'),
            Text('$_score/70'),
            Row(
              children: [
                Icon(Icons.timer),
                SizedBox(width: 4),
                Text('$_timeLeft s'),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 50,
            bottom: 70,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTapDown: (details) {
                _shoot(details.localPosition);
              },
              child: Stack(
                children: [
                  for (var target in _targets.take(_maxVisibleTargets))
                    Positioned(
                      left: target.offset.dx,
                      top: target.offset.dy,
                      child: TargetWidget(target: target),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTargets() {
    const targetSize = Size(50, 50);

    Timer.periodic(const Duration(milliseconds: 750), (timer) {
      if (_controller.isCompleted) {
        timer.cancel();
      } else {
        Size screenSize = MediaQuery.of(context).size;

        // Only add a new target if the visible count is less than max visible targets
        if (_targets.length < _maxVisibleTargets) {
          _targets.add(Target(
            offset: Offset(
              screenSize.width + targetSize.width,
              Random().nextDouble() * (screenSize.height - targetSize.height - 100) + 50,
            ),
            size: targetSize,
            speed: _targetSpeed,
            onHit: () {
              setState(() {
                _score++;
              });
            },
          ));
        }
      }
    });
  }

  void _shoot(Offset position) {
    setState(() {
      for (var target in _targets) {
        if (!target.isHit && target.hitTest(position)) {
          target.isHit = true;
          target.onHit();
          break;
        }
      }
    });
  }
}

class Target {
  late Offset offset;
  final Size size;
  final double speed;
  bool isHit = false;
  final Function() onHit;

  Target({
    required this.offset,
    required this.size,
    required this.speed,
    required this.onHit,
  });

  void updatePosition() {
    offset = Offset(
      offset.dx - speed,
      offset.dy,
    );
  }

  bool hitTest(Offset position) {
    return !isHit &&
        position.dx >= offset.dx &&
        position.dx <= offset.dx + size.width &&
        position.dy >= offset.dy &&
        position.dy <= offset.dy + size.height;
  }

  bool isOut() {
    return offset.dx + size.width < 0;
  }

  void reset(Size screenSize) {
    offset = Offset(
      screenSize.width + size.width,
      Random().nextDouble() * (screenSize.height - size.height - 100) + 50,
    );
    isHit = false;
  }
}

class TargetWidget extends StatelessWidget {
  final Target target;

  const TargetWidget({Key? key, required this.target}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: target.size.width,
      height: target.size.height,
      decoration: BoxDecoration(
        color: target.isHit ? Colors.grey : Colors.brown,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
