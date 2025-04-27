// Updated example in your main.dart file
import 'package:flutter/material.dart';
import 'chessboard.dart';
import 'package:universal_html/html.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checkers Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: const CheckersBoardPage(title: 'Checkers Board'),
    );
  }
}

class CheckersBoardPage extends StatefulWidget {
  const CheckersBoardPage({super.key, required this.title});

  final String title;

  @override
  State<CheckersBoardPage> createState() => _CheckersBoardPageState();
}

class _CheckersBoardPageState extends State<CheckersBoardPage> {
  @override
  void initState() {
    super.initState();
    document.onContextMenu.listen((event) => event.preventDefault());
  }

  final List<CheckerPiece> _pieces = [];
  // Track the currently selected checker color
  CheckerColor _selectedColor = CheckerColor.white;
  // Default board size
  int _boardSize = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Color selector and Reset button row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _pieces.clear(); // Reset the board by clearing all pieces
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                  ),
                  child: const Text('Reset Board'),
                ),
                const SizedBox(width: 30),
                // White color option
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = CheckerColor.white;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            _selectedColor == CheckerColor.white
                                ? Colors.deepOrange
                                : Colors.grey,
                        width: _selectedColor == CheckerColor.white ? 3 : 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Black color option
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = CheckerColor.black;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            _selectedColor == CheckerColor.black
                                ? Colors.deepOrange
                                : Colors.grey,
                        width: _selectedColor == CheckerColor.black ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Board size selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Board Size: '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _boardSize,
                  items:
                      [4, 6, 8, 10, 12].map((size) {
                        return DropdownMenuItem<int>(
                          value: size,
                          child: Text('$size × $size'),
                        );
                      }).toList(),
                  onChanged: (newSize) {
                    if (newSize != null) {
                      setState(() {
                        _boardSize = newSize;
                        _pieces
                            .clear(); // Clear pieces when changing board size
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Chessboard
          Expanded(
            child: Center(
              child: ChessBoard(
                size: _boardSize, // Use the selected board size
                cellSize: 45, // Size in logical pixels
                pieces: _pieces,
                onLeftTap: (position) {
                  // Handle cell tap - add piece with selected color
                  setState(() {
                    // Get all pieces at this position
                    final piecesAtPosition =
                        _pieces
                            .where((piece) => piece.position == position)
                            .toList();

                    // Check if there's at least one piece and the first piece has the opposite color
                    final hasOppositeColor =
                        piecesAtPosition.isNotEmpty &&
                        piecesAtPosition.first.color != _selectedColor;

                    // Only add a piece if there's no opposite color at this position
                    if (!hasOppositeColor) {
                      _pieces.add(
                        CheckerPiece(color: _selectedColor, position: position),
                      );
                    }
                  });
                },
                onRightTap: (position) {
                  // Handle cell tap - remove piece
                  setState(() {
                    // Find the index of the first piece at the position
                    final index = _pieces.indexWhere(
                      (piece) => piece.position == position,
                    );

                    // Only remove if a piece was found
                    if (index >= 0) {
                      _pieces.removeAt(index);
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
