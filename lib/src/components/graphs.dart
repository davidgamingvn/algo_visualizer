import 'package:flutter/material.dart';

import 'dart:math';

class BarGraph extends StatelessWidget {
  final List<int> numbers;

  const BarGraph({super.key, required this.numbers});

  @override
  Widget build(BuildContext context) {
    double maxValue = numbers.reduce(max).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: numbers
          .map((number) => Expanded(
                child: Container(
                  height: (number / maxValue) * 300,
                  color: Colors.blue,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                ),
              ))
          .toList(),
    );
  }
  
}

class MazeVisualizer extends StatelessWidget {
  final List<List<bool>> maze;
  final List<Point<int>> path;
  final Point<int> start;
  final Point<int> end;
  final Set<Point<int>> visited;

  const MazeVisualizer({
    super.key,
    required this.maze,
    required this.path,
    required this.start,
    required this.end,
    required this.visited,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MazePainter(maze: maze, path: path, start: start, end: end, visited: visited),
      child: Container(),
    );
  }
}

class MazePainter extends CustomPainter {
  final List<List<bool>> maze;
  final List<Point<int>> path;
  final Point<int> start;
  final Point<int> end;
  final Set<Point<int>> visited;

  MazePainter({
    required this.maze,
    required this.path,
    required this.start,
    required this.end,
    required this.visited,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / maze.length;
    final wallPaint = Paint()..color = Colors.black;
    final visitedPaint = Paint()..color = Colors.yellow.withOpacity(0.3);
    final pathPaint = Paint()..color = Colors.red;
    final startPaint = Paint()..color = Colors.green;
    final endPaint = Paint()..color = Colors.blue;

    for (int y = 0; y < maze.length; y++) {
      for (int x = 0; x < maze[y].length; x++) {
        if (!maze[y][x]) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            wallPaint,
          );
        }
      }
    }

    for (var point in visited) {
      canvas.drawRect(
        Rect.fromLTWH(
            point.x * cellSize, point.y * cellSize, cellSize, cellSize),
        visitedPaint,
      );
    }

    for (var point in path) {
      canvas.drawCircle(
        Offset(point.x * cellSize + cellSize / 2,
            point.y * cellSize + cellSize / 2),
        cellSize / 4,
        pathPaint,
      );
    }

    canvas.drawCircle(
      Offset(
          start.x * cellSize + cellSize / 2, start.y * cellSize + cellSize / 2),
      cellSize / 3,
      startPaint,
    );

    canvas.drawCircle(
      Offset(end.x * cellSize + cellSize / 2, end.y * cellSize + cellSize / 2),
      cellSize / 3,
      endPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
