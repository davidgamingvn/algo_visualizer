import 'package:algo_visualizer/src/components/graphs.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class AlgorithmSimulator extends StatefulWidget {
  const AlgorithmSimulator({super.key});

  @override
  _AlgorithmSimulatorState createState() => _AlgorithmSimulatorState();
}

class _AlgorithmSimulatorState extends State<AlgorithmSimulator> {
  List<int> numbers = [];
  String selectedAlgorithm = 'Bubble Sort';
  List<List<bool>> maze = [];
  int mazeSize = 20;
  Point<int>? start;
  Point<int>? end;
  List<Point<int>> path = [];
  bool isSorting = true;
  bool isSidebarOpen = false;
  String performanceMetrics = '';

  @override
  void initState() {
    super.initState();
    generateRandomNumbers();
    generateMaze();
  }

  void generateRandomNumbers() {
    final random = Random();
    numbers = List.generate(20, (_) => random.nextInt(100) + 1);
    setState(() {});
  }

  void generateMaze() {
    final random = Random();
    maze = List.generate(mazeSize,
        (_) => List.generate(mazeSize, (_) => random.nextDouble() > 0.3));
    start = const Point(0, 0);
    end = Point(mazeSize - 1, mazeSize - 1);
    maze[start!.y][start!.x] = true;
    maze[end!.y][end!.x] = true;
    path = [];
    setState(() {});
  }

  Future<void> runAlgorithm() async {
    final stopwatch = Stopwatch()..start();
    setState(() {
      performanceMetrics = 'Running...';
    });

    if (isSorting) {
      switch (selectedAlgorithm) {
        case 'Bubble Sort':
          await bubbleSort();
          break;
        case 'Quick Sort':
          await quickSort(0, numbers.length - 1);
          break;
      }
    } else {
      switch (selectedAlgorithm) {
        case 'Dijkstra':
          await dijkstra();
          break;
        case 'A*':
          await aStar();
          break;
      }
    }

    stopwatch.stop();
    setState(() {
      performanceMetrics =
          'Time: ${stopwatch.elapsedMilliseconds} ms\nMemory: Approx. ${_calculateMemoryUsage()} bytes';
    });
  }

  int _calculateMemoryUsage() {
    int memoryUsage = 0;
    memoryUsage += numbers.length * 4; // int is 4 bytes
    memoryUsage += mazeSize * mazeSize * 1; // bool is 1 byte
    memoryUsage += path.length * (2 * 4); // Point<int> has 2 ints
    return memoryUsage;
  }

  Future<void> bubbleSort() async {
    for (int i = 0; i < numbers.length; i++) {
      for (int j = 0; j < numbers.length - i - 1; j++) {
        if (numbers[j] > numbers[j + 1]) {
          int temp = numbers[j];
          numbers[j] = numbers[j + 1];
          numbers[j + 1] = temp;
          await Future.delayed(const Duration(milliseconds: 50));
          setState(() {});
        }
      }
    }
  }

  Future<void> quickSort(int low, int high) async {
    if (low < high) {
      int pi = await partition(low, high);
      await quickSort(low, pi - 1);
      await quickSort(pi + 1, high);
    }
  }

  Future<int> partition(int low, int high) async {
    int pivot = numbers[high];
    int i = low - 1;
    for (int j = low; j < high; j++) {
      if (numbers[j] < pivot) {
        i++;
        int temp = numbers[i];
        numbers[i] = numbers[j];
        numbers[j] = temp;
        await Future.delayed(const Duration(milliseconds: 50));
        setState(() {});
      }
    }
    int temp = numbers[i + 1];
    numbers[i + 1] = numbers[high];
    numbers[high] = temp;
    await Future.delayed(const Duration(milliseconds: 50));
    setState(() {});
    return i + 1;
  }

  Future<void> dijkstra() async {
    final pq =
        HeapPriorityQueue<_Node>((a, b) => a.distance.compareTo(b.distance));
    final distances =
        List.generate(mazeSize, (_) => List.filled(mazeSize, double.infinity));
    final visited =
        List.generate(mazeSize, (_) => List.filled(mazeSize, false));
    final previous = List.generate(
        mazeSize, (_) => List.filled(mazeSize, const Point(-1, -1)));

    distances[start!.y][start!.x] = 0;
    pq.add(_Node(start!, 0));

    while (pq.isNotEmpty) {
      final node = pq.removeFirst();
      final x = node.position.x;
      final y = node.position.y;

      if (visited[y][x]) continue;
      visited[y][x] = true;

      setState(() {
        path = _reconstructPath(previous, node.position);
      });
      await Future.delayed(const Duration(milliseconds: 50));

      if (node.position == end) break;

      for (final neighbor in _getNeighbors(node.position)) {
        final nx = neighbor.x;
        final ny = neighbor.y;

        if (!maze[ny][nx] || visited[ny][nx]) continue;

        final newDist = distances[y][x] + 1;
        if (newDist < distances[ny][nx]) {
          distances[ny][nx] = newDist;
          previous[ny][nx] = node.position;
          pq.add(_Node(neighbor, newDist));
        }
      }
    }

    setState(() {
      path = _reconstructPath(previous, end!);
    });
  }

  Future<void> aStar() async {
    final pq = HeapPriorityQueue<_Node>((a, b) => a.fScore.compareTo(b.fScore));
    final gScore =
        List.generate(mazeSize, (_) => List.filled(mazeSize, double.infinity));
    final fScore =
        List.generate(mazeSize, (_) => List.filled(mazeSize, double.infinity));
    final cameFrom = List.generate(
        mazeSize, (_) => List.filled(mazeSize, const Point(-1, -1)));

    gScore[start!.y][start!.x] = 0;
    fScore[start!.y][start!.x] = _heuristic(start!, end!).toDouble();
    pq.add(_Node(start!, fScore[start!.y][start!.x]));

    while (pq.isNotEmpty) {
      final current = pq.removeFirst();

      setState(() {
        path = _reconstructPath(cameFrom, current.position);
      });
      await Future.delayed(const Duration(milliseconds: 50));

      if (current.position == end) {
        setState(() {
          path = _reconstructPath(cameFrom, end!);
        });
        return;
      }

      for (final neighbor in _getNeighbors(current.position)) {
        final nx = neighbor.x;
        final ny = neighbor.y;

        if (!maze[ny][nx]) continue;

        final tentativeGScore =
            gScore[current.position.y][current.position.x] + 1;

        if (tentativeGScore < gScore[ny][nx]) {
          cameFrom[ny][nx] = current.position;
          gScore[ny][nx] = tentativeGScore;
          fScore[ny][nx] =
              gScore[ny][nx] + _heuristic(neighbor, end!).toDouble();
          pq.add(_Node(neighbor, fScore[ny][nx]));
        }
      }
    }
  }

  double _heuristic(Point<int> a, Point<int> b) {
    return (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();
  }

  List<Point<int>> _getNeighbors(Point<int> position) {
    final x = position.x;
    final y = position.y;
    return [
      Point(x + 1, y),
      Point(x - 1, y),
      Point(x, y + 1),
      Point(x, y - 1),
    ]
        .where((p) => p.x >= 0 && p.x < mazeSize && p.y >= 0 && p.y < mazeSize)
        .toList();
  }

  List<Point<int>> _reconstructPath(
      List<List<Point<int>>> cameFrom, Point<int> current) {
    final totalPath = [current];
    while (current != start) {
      current = cameFrom[current.y][current.x];
      if (current.x == -1 && current.y == -1) break;
      totalPath.insert(0, current);
    }
    return totalPath;
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSidebarOpen ? 200 : 0,
      child: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Algorithm Settings',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('Sorting'),
              leading: Radio<bool>(
                value: true,
                groupValue: isSorting,
                onChanged: (bool? value) {
                  setState(() {
                    isSorting = value!;
                    selectedAlgorithm = isSorting ? 'Bubble Sort' : 'Dijkstra';
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Pathfinding'),
              leading: Radio<bool>(
                value: false,
                groupValue: isSorting,
                onChanged: (bool? value) {
                  setState(() {
                    isSorting = value!;
                    selectedAlgorithm = isSorting ? 'Bubble Sort' : 'Dijkstra';
                  });
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Algorithm'),
              subtitle: DropdownButton<String>(
                value: selectedAlgorithm,
                items: isSorting
                    ? <String>['Bubble Sort', 'Quick Sort'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList()
                    : <String>['Dijkstra', 'A*'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedAlgorithm = newValue!;
                  });
                },
              ),
            ),
            ElevatedButton(
              onPressed: runAlgorithm,
              child: const Text('Run Algorithm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Algorithm Simulator'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              isSidebarOpen = !isSidebarOpen;
            });
          },
        ),
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    selectedAlgorithm,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(performanceMetrics,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isSorting
                        ? Center(child: BarGraph(numbers: numbers))
                        : MazeVisualizer(
                            maze: maze,
                            path: path,
                            start: start!,
                            end: end!,
                            visited: const {},
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: runAlgorithm,
            tooltip: 'Run Algorithm',
            child: const Icon(Icons.play_arrow),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              generateRandomNumbers();
              generateMaze();
            },
            tooltip: 'Generate New Data',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _Node {
  final Point<int> position;
  final double fScore;

  _Node(this.position, this.fScore);

  double get distance => fScore;
}

class HeapPriorityQueue<E> {
  final Comparator<E> comparison;
  final List<E> _heap = [];

  HeapPriorityQueue(this.comparison);

  void add(E element) {
    _heap.add(element);
    _siftUp(_heap.length - 1);
  }

  E removeFirst() {
    if (_heap.isEmpty) throw StateError('HeapPriorityQueue is empty');
    if (_heap.length == 1) return _heap.removeLast();
    final E result = _heap.first;
    _heap[0] = _heap.removeLast();
    _siftDown(0);
    return result;
  }

  void _siftUp(int index) {
    E element = _heap[index];
    while (index > 0) {
      int parentIndex = (index - 1) ~/ 2;
      E parent = _heap[parentIndex];
      if (comparison(element, parent) >= 0) break;
      _heap[index] = parent;
      index = parentIndex;
    }
    _heap[index] = element;
  }

  void _siftDown(int index) {
    E element = _heap[index];
    int childIndex = 2 * index + 1;
    while (childIndex < _heap.length) {
      if (childIndex + 1 < _heap.length &&
          comparison(_heap[childIndex + 1], _heap[childIndex]) < 0) {
        childIndex++;
      }
      if (comparison(element, _heap[childIndex]) <= 0) break;
      _heap[index] = _heap[childIndex];
      index = childIndex;
      childIndex = 2 * index + 1;
    }
    _heap[index] = element;
  }

  bool get isEmpty => _heap.isEmpty;
  bool get isNotEmpty => _heap.isNotEmpty;
}
