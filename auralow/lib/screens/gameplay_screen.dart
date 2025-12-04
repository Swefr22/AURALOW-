// lib/screens/gameplay_screen.dart (MODIFIED)

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/breath_detector.dart';
import '../utils/storage.dart';
import '../models/level_theme.dart'; // Must be imported for allThemes

class GameplayScreen extends StatefulWidget {
  
  final int levelId; // Which maze structure to load (1-5)
  final LevelTheme theme; // Which visual theme to apply

  const GameplayScreen({Key? key, required this.levelId, required this.theme}) : super(key: key);

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class Cell {
    final int x;
    final int y;
    final Cell? parent;

    Cell(this.x, this.y, {this.parent});

    @override
    bool operator ==(Object other) => other is Cell && other.x == x && other.y == y;

    @override
    int get hashCode => Object.hash(x, y);

    Point<int> toPoint() => Point(x, y);
}

class _GameplayScreenState extends State<GameplayScreen> {
    late int _mazeWidth;
    late int _mazeHeight;

    late Point<double> _startPos;
    late Point<double> _endPos;

    final BreathDetector _detector = BreathDetector(); 
    StreamSubscription<double>? _ampSub;

    double _currentAmp = 0.0;
    double _baselineAmp = 0.0; 
    bool _detectorFailed = false;
    bool _calibrating = true;
    
    // --- Calm Time Tracking Variables ---
    int _calmTimeMilliseconds = 0;
    Timer? _calmTimer;
    final double CALM_THRESHOLD = 0.1; 
    // --- END Calm Time ---

    // Maze Data
    static const int WALL = 1;
    static const int PATH = 0;
    List<List<int>> currentMaze = [];
    late int MAZE_SIZE; 
   

    // Player position in maze grid coordinates (1.0 to MAZE_SIZE-2.0)
    double _playerX = 1.0;
    double _playerY = 1.0;

    Timer? _moveTimer;
    double _horizontalVelocity = 0.0; 
    double _verticalCorrection = 0.0; 
    

    // ⭐ NEW PATH-BASED VARIABLES ⭐
    List<Point<int>> _currentPath = []; 
    int _currentPathIndex = 0;
    double _pathProgress = 0.0;
    // ----------------------------------

    // --- 5 LEVEL MAZE DATA (Mazes remain the same) --- 
    final Map<int, List<List<int>>> levelMazes = {
      // Level 1: Sky Drift (11x11)
      1: [
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1],
        [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1],
        [1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1],
        [1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      ],
      // Level 2: Forest Aura (13x13)
      2: [
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1],
        [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1],
        [1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1],
        [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      ],
      // Level 3: Ocean Calm (15x15)
      3: [
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], 
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], 
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      ],
      // Level 4: Desert Star (17x17)
      4: [
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], 
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1],
        [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], 
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      ],
      // Level 5: Celestial Void (19x19)
      5: [
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], 
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], 
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      ]
    };


    @override
    void initState() {
      super.initState();
      _loadMazeData();
      _initDetector(); 
      _startMovementTimer(); // Calls the path-based logic now
      _startCalmTimer(); 
    }

    // ------------------------------------------------------------------
    // ⭐ NEW: BFS Pathfinding Utility
    // ------------------------------------------------------------------
    List<Point<int>> _findShortestPath(Point<int> start, Point<int> end) {
        if (start == end) return [start];

        final queue = <Cell>[Cell(start.x, start.y)];
        final visited = <Point<int>>{start};

        while (queue.isNotEmpty) {
            final current = queue.removeAt(0);

            final neighbors = [
                Point(current.x, current.y - 1),
                Point(current.x, current.y + 1),
                Point(current.x - 1, current.y),
                Point(current.x + 1, current.y),
            ];

            for (final next in neighbors) {
                if (_isWall(next.x, next.y) || visited.contains(next)) {
                    continue;
                }

                if (next.x == end.x && next.y == end.y) {
                    final path = <Point<int>>[end];
                    Cell? temp = current;
                    while (temp != null) {
                        path.add(temp.toPoint());
                        temp = temp.parent;
                    }
                    return path.reversed.toList();
                }

                visited.add(next);
                queue.add(Cell(next.x, next.y, parent: current));
            }
        }
        return [];
    }

    void _loadMazeData() {
        final mazeData = levelMazes[widget.levelId]; 
        
        if (mazeData != null) {
            currentMaze = mazeData;
            _mazeHeight = currentMaze.length; 
            _mazeWidth = currentMaze.isNotEmpty ? currentMaze[0].length : 0; 

            MAZE_SIZE = _mazeHeight;

            Point<double> tempEnd = Point((_mazeWidth - 2).toDouble(), (_mazeHeight - 2).toDouble());
            Point<double> tempStart = const Point(1.0, 1.0);

            if (widget.levelId == 3) {
                tempStart = Point(1.0, (_mazeHeight / 2).floorToDouble()); 
                tempEnd = Point((_mazeWidth - 2).toDouble(), (_mazeHeight / 2).floorToDouble());
            }
            
            _startPos = tempStart;
            _endPos = tempEnd;

            _playerX = _startPos.x;
            _playerY = _startPos.y;

            // ⭐ INITIALIZE PATH after loading maze data
            _currentPath = _findShortestPath(
  Point(_startPos.x.toInt(), _startPos.y.toInt()),
  Point(_endPos.x.toInt(), _endPos.y.toInt()),
);
            _currentPathIndex = 0;
            _pathProgress = 0.0;
        } 
        else {
            print('Error: Could not load maze data for level ${widget.levelId}');
        }
    }

    Future<void> _initDetector() async {
      try {
        setState(() {
          _calibrating = true;
        });
        _baselineAmp = await _detector.calibrate(durationMs: 1500); 
        
        _subscribeToDetector();
        setState(() {
          _calibrating = false;
        });
      } catch (e, st) {
        print("Detector init failed: $e\n$st");
        setState(() => _detectorFailed = true);
      }
    }

    // ------------------------------------------------------------------
    // ⭐ REWRITTEN: Path-Based Movement Timer
    // ------------------------------------------------------------------
    void _startMovementTimer() {
        _moveTimer?.cancel();
        _moveTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
            if (!mounted || _currentPath.isEmpty) return;

            const double progressIncrement = 0.05;

            // Use horizontal velocity (derived from breath amplitude) for movement speed.
            double speed = _horizontalVelocity.clamp(0.0, 1.0); 
            double advancement = speed * progressIncrement;

            // Only move if there is a next cell in the path
            if (_currentPathIndex < _currentPath.length - 1) {
                
                // Advance progress along the current segment
                _pathProgress += advancement;

                // Check if segment is complete
                if (_pathProgress >= 1.0) {
                    // Snap to the center of the next cell, and reset progress
                    _currentPathIndex++;
                    _pathProgress = 0.0; 

                    // Check if the GOAL is reached (last cell index)
                    if (_currentPathIndex >= _currentPath.length - 1) {
                        _playerX = _endPos.x;
                        _playerY = _endPos.y;
                        _onSessionComplete(true);
                        return;
                    }
                }

                // Update Orb Position using Linear Interpolation (Lerp)
                final Point<int> startCell = _currentPath[_currentPathIndex];
                final Point<int> endCell = _currentPath[_currentPathIndex + 1];

                // Lerp the X and Y coordinates between the start and end cell centers
                _playerX = startCell.x + (endCell.x - startCell.x) * _pathProgress;
                _playerY = startCell.y + (endCell.y - startCell.y) * _pathProgress;
            }

            // --- The goal check is now redundant if we handle it at path end, 
            // but we keep a final check for safety.
            final goalDistance = sqrt(pow(_playerX - _endPos.x, 2) + pow( _playerY - _endPos.y, 2));
            if (goalDistance < 0.8) { 
                _onSessionComplete(true);
            }
            // -----------------------------------------------------------------------

            setState(() {});
        });
    }

    void _startCalmTimer() { 
        // ... (Remains the same)
        _calmTimer?.cancel();
        _calmTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (!mounted) return;
          
          if (_currentAmp <= CALM_THRESHOLD) {
            _calmTimeMilliseconds += 100;
          }
          setState(() {}); 
        });
    }
    
    bool _isWall(int x, int y) {
        // ... (Remains the same)
        if (x < 0 || x >= _mazeWidth || y < 0 || y >= _mazeHeight) return true;
        return currentMaze[y][x] == WALL;
    }

    // ------------------------------------------------------------------
    // MODIFIED BREATH DETECTOR SUBSCRIPTION (Only X-velocity is used for progress)
    // ------------------------------------------------------------------
    void _subscribeToDetector() {
        _ampSub?.cancel();
        _detector.startListening();
        _ampSub = _detector.amplitudeStream.listen((val) {

            _currentAmp = val;

            const double maxHorizontalVel = 1.0;
            // Horizontal velocity now controls *progress* along the path (speed).
            _horizontalVelocity = (val * 10).clamp(0.05, maxHorizontalVel); 

            // Vertical correction is retained for future path *selection* logic (at forks).
            const double TARGET_AMPLITUDE = 0.5; 
            const double sensitivityFactor = 2.0; 
            double deviation = val - TARGET_AMPLITUDE; 
            _verticalCorrection = (deviation * sensitivityFactor).clamp(-1.0, 1.0); 

            if (mounted) setState(() {});
        }, onError: (e, st) {
            print("Amplitude stream error: $e\n$st");
        });
    }
  
    // --- Session Complete Logic remains the same ---
    void _onSessionComplete(bool mazeCompleted) async {
        // ... (Remains the same)
        if (!mounted) return;
        
        _ampSub?.cancel();
        _moveTimer?.cancel();
        _calmTimer?.cancel(); 
        _detector.stop();

        final currentLevel = widget.levelId; 
        final currentUnlockedLevel = Storage.getInt('unlockedLevel') ?? 1;

        final unlockedNew = mazeCompleted && (currentLevel == currentUnlockedLevel) && (currentLevel < 5); 
        final nextLevelIndex = unlockedNew ? (currentLevel + 1) : currentLevel;
        
        if (unlockedNew) {
          await Storage.setInt('unlockedLevel', nextLevelIndex);
          await Storage.setInt('currentLevel', nextLevelIndex);
          await Storage.setInt('selectedThemeId', nextLevelIndex);
        }

        final int seconds = (_calmTimeMilliseconds / 1000).round();
        final String timeAchieved = '${seconds ~/ 60}m ${seconds % 60}s';

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.black87,
            title: Text(
                mazeCompleted ? (unlockedNew ? 'Level Unlocked! 🔑' : 'Maze Complete!') : 'Session Ended',
                style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    (mazeCompleted ? 'You successfully completed Maze Level $currentLevel!\n' : 'You ended the session early.\n') +
                        (unlockedNew ? 'You unlocked Maze Level $nextLevelIndex! You can now select it from the menu.' : 'Keep practicing your breath control.'),
                    style: const TextStyle(color: Colors.white70)),
                const Divider(height: 20, color: Colors.white24),
                Text(
                  '✨ Calm Time Achieved: **$timeAchieved**',
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              if (unlockedNew)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    final nextLevelTheme = allThemes.firstWhere(
                      (t) => t.id == nextLevelIndex,
                      orElse: () => allThemes.first, 
                    );
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GameplayScreen(levelId: nextLevelIndex, theme: nextLevelTheme)));
                  },
                  child: Text('Play Level $nextLevelIndex!',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),

              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                },
                child: const Text('Return to Menu', style: TextStyle(color: Colors.cyanAccent)),
              ),
            ],
          ),
        );
    }

    @override
    void dispose() {
        // ... (Remains the same)
        _moveTimer?.cancel();
        _calmTimer?.cancel(); 
        _ampSub?.cancel();
        _detector.dispose();
        super.dispose();
    }

    // --- Maze Drawing logic remains the same ---
    Widget _buildMazeCell(int x, int y, double cellSize) {
        // ... (Remains the same)
        final isWall = _isWall(x, y);
        final isEnd = x == _endPos.x.round() && y == _endPos.y.round();
        final isStart = x == _startPos.x.round() && y == _startPos.y.round();

        return Positioned(
          left: x * cellSize,
          top: y * cellSize,
          width: cellSize,
          height: cellSize,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isWall ? Colors.white.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: isEnd
                ? Center(child: Icon(Icons.star, color: Colors.yellowAccent, size: cellSize * 0.6))
                : isStart
                    ? Center(child: Icon(Icons.flag, color: Colors.greenAccent, size: cellSize * 0.6))
                    : null,
          ),
        );
    }

    // ------------------------------------------------------------------
    // BUILD METHOD (Remains the same, uses the updated _playerX/_playerY)
    // ------------------------------------------------------------------
    @override
    Widget build(BuildContext context) {
        // ... (Remains the same)
        final w = MediaQuery.of(context).size.width;
        final h = MediaQuery.of(context).size.height;

        final mazeDisplaySize = min(w, h * 0.7);
        final cellSize = mazeDisplaySize / MAZE_SIZE; 
        final offsetX = (w - mazeDisplaySize) / 2;
        final offsetY = (h / 2) - (mazeDisplaySize / 2);
        
        final int seconds = (_calmTimeMilliseconds / 1000).round();
        final String calmTimeDisplay = '${seconds ~/ 60}m ${seconds % 60}s';

        final double playerPixelX = offsetX + _playerX * cellSize - (cellSize / 2);
        final double playerPixelY = offsetY + _playerY * cellSize - (cellSize / 2);

        final double dynamicSpreadRadius = 8.0 + (_currentAmp * 50.0);
        final double scaledSpreadRadius = dynamicSpreadRadius.clamp(5.0, 40.0);
        
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.theme.gradient, 
                    ),
                  ),
                ),
              ),
              
              Positioned(
                left: offsetX,
                top: offsetY,
                width: mazeDisplaySize,
                height: mazeDisplaySize,
                child: Stack(
                  children: [
                    for (int y = 0; y < MAZE_SIZE; y++)
                      for (int x = 0; x < MAZE_SIZE; x++)
                        _buildMazeCell(x, y, cellSize),
                  ],
                ),
              ),

              // Player Orb Position 
              AnimatedPositioned(
                duration: const Duration(milliseconds: 16), 
                curve: Curves.linear,
                left: playerPixelX,
                top: playerPixelY,
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.45),
                        blurRadius: 28,
                        spreadRadius: scaledSpreadRadius,
                      )
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.air_outlined, color: Colors.black87, size: cellSize * 0.5),
                  ),
                ),
              ),

              // Info Display 
              Positioned(
                top: 40,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Maze Level: ${widget.levelId} | Theme: ${widget.theme.name}",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Calm Time: $calmTimeDisplay",
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Amplitude (Raw): ${_currentAmp.toStringAsFixed(3)}",
                        style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _calibrating ? "Calibrating..." : "Velocity: ${_horizontalVelocity.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Vertical Adj: ${_verticalCorrection.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

              // End Session Button
              Positioned(
                right: 16,
                bottom: 30,
                child: ElevatedButton(
                  onPressed: () => _onSessionComplete(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  ),
                  child: const Text('End Session', style: TextStyle(color: Colors.white)),
                ),
              ),

              if (_detectorFailed)
                const Center(
                  child: Text(
                    "Microphone error.\nCheck permission.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 20),
                  ),
                ),
            ],
          ),
        );
    }
}