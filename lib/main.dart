import 'package:flutter/material.dart';
import 'chessboard.dart';
import 'package:universal_html/html.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
      databaseURL: dotenv.env['FIREBASE_DATABASE_URL']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGE_SENDER_ID']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
    ),
  );
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
    _setupFirebaseSync();
  }

  @override
  void dispose() {
    _firebaseListener?.cancel();
    super.dispose();
  }

  // Firebase variables
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(
    'checkerboards',
  );
  String _boardId = 'default';
  StreamSubscription? _firebaseListener;
  bool _isLocalUpdate = false;
  TextEditingController _boardIdController = TextEditingController(
    text: 'default',
  );

  void _setupFirebaseSync() {
    // Load initial state
    _loadBoardFromFirebase();

    // Set up real-time listener
    _firebaseListener = _dbRef.child(_boardId).onValue.listen((event) {
      if (_isLocalUpdate) {
        _isLocalUpdate = false;
        return;
      }

      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _updateBoardFromFirebase(data);
      }
    });
  }

  void _loadBoardFromFirebase() async {
    final snapshot = await _dbRef.child(_boardId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      _updateBoardFromFirebase(data);
    }
  }

  void _updateBoardFromFirebase(Map<dynamic, dynamic> data) {
    setState(() {
      _boardSize = data['boardSize'] ?? 8;
      final piecesData = data['pieces'] as List<dynamic>?;

      _pieces.clear();

      if (piecesData != null) {
        for (var piece in piecesData) {
          final pieceData = piece as Map<dynamic, dynamic>;
          _pieces.add(
            CheckerPiece(
              color:
                  pieceData['color'] == 'white'
                      ? CheckerColor.white
                      : CheckerColor.black,
              position: ChessBoardPosition(
                row: pieceData['row'],
                col: pieceData['col'],
              ),
            ),
          );
        }
      }
    });
  }

  void _saveBoardToFirebase() {
    _isLocalUpdate = true;

    final piecesData =
        _pieces.map((piece) {
          return {
            'color': piece.color == CheckerColor.white ? 'white' : 'black',
            'row': piece.position.row,
            'col': piece.position.col,
          };
        }).toList();

    _dbRef.child(_boardId).set({
      'boardSize': _boardSize,
      'pieces': piecesData,
      'lastUpdated': ServerValue.timestamp,
    });
  }

  void _changeBoardId(String newId) {
    if (newId.isEmpty || newId == _boardId) return;

    setState(() {
      // Cleanup old listener
      _firebaseListener?.cancel();
      _boardId = newId;
      _boardIdController.text = newId;
      _pieces.clear();

      // Setup new listener
      _setupFirebaseSync();
    });
  }

  final List<CheckerPiece> _pieces = [];
  CheckerColor _selectedColor = CheckerColor.white;
  int _boardSize = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Firebase board ID input
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _boardIdController,
                    decoration: const InputDecoration(
                      labelText: 'Board ID',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    onSubmitted: _changeBoardId,
                  ),
                ),
                const SizedBox(width: 8),

                // Join button
                ElevatedButton(
                  onPressed: () => _changeBoardId(_boardIdController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[100],
                  ),
                  child: const Text('Join Board'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _pieces.clear();
                      _saveBoardToFirebase();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                  ),
                  child: const Text('Reset Board'),
                ),
                const SizedBox(width: 16),

                const SizedBox(width: 30),

                // White color selector
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
                        _pieces.clear();
                        _saveBoardToFirebase();
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text("Right click to remove a piece")],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text("Left click to add a piece")],
            ),
          ),

          Expanded(
            child: Center(
              child: ChessBoard(
                size: _boardSize,
                cellSize: 45,
                pieces: _pieces,
                onLeftTap: (position) {
                  setState(() {
                    final piecesAtPosition =
                        _pieces
                            .where((piece) => piece.position == position)
                            .toList();

                    final hasOppositeColor =
                        piecesAtPosition.isNotEmpty &&
                        piecesAtPosition.first.color != _selectedColor;

                    if (!hasOppositeColor) {
                      _pieces.add(
                        CheckerPiece(color: _selectedColor, position: position),
                      );
                      _saveBoardToFirebase();
                    }
                  });
                },
                onRightTap: (position) {
                  setState(() {
                    final index = _pieces.indexWhere(
                      (piece) => piece.position == position,
                    );

                    if (index >= 0) {
                      _pieces.removeAt(index);
                      _saveBoardToFirebase();
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
