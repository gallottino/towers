import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ChessBoardPosition {
  final int row;
  final int col;

  const ChessBoardPosition({required this.row, required this.col});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChessBoardPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

enum CheckerColor { white, black }

class CheckerPiece {
  final CheckerColor color;
  final ChessBoardPosition position;

  const CheckerPiece({required this.color, required this.position});
}

class ChessBoard extends StatefulWidget {
  final int size;
  final double cellSize;
  final List<CheckerPiece> pieces;
  final Function(ChessBoardPosition)? onLeftTap;
  final Function(ChessBoardPosition)? onRightTap;
  final Color lightCellColor;
  final Color darkCellColor;

  const ChessBoard({
    super.key,
    this.size = 8,
    this.cellSize = 40.0,
    this.pieces = const [],
    this.onLeftTap,
    this.onRightTap,
    this.lightCellColor = const Color(0xFFF0D9B5),
    this.darkCellColor = const Color(0xFFB58863),
  });

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

// ... keep existing imports and code up to the _ChessBoardState class

class _ChessBoardState extends State<ChessBoard> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * widget.cellSize,
      height: widget.size * widget.cellSize,
      child: Column(
        children: List.generate(widget.size, (row) {
          return Row(
            children: List.generate(widget.size, (col) {
              final isEvenCell = (row + col) % 2 == 0;
              final cellColor =
                  isEvenCell ? widget.lightCellColor : widget.darkCellColor;
              final position = ChessBoardPosition(row: row, col: col);

              // Get all pieces at this position
              final piecesAtPosition =
                  widget.pieces
                      .where((piece) => piece.position == position)
                      .toList();

              final hasPieces = piecesAtPosition.isNotEmpty;

              // If there are pieces, use the first one's color for display
              final displayColor =
                  hasPieces ? piecesAtPosition.first.color : null;
              final pieceCount = piecesAtPosition.length;

              return GestureDetector(
                onTap: () {
                  if (widget.onLeftTap != null) {
                    widget.onLeftTap!(position);
                  }
                },
                onSecondaryTap: () {
                  if (widget.onRightTap != null) {
                    widget.onRightTap!(position);
                  }
                },
                child: Container(
                  width: widget.cellSize,
                  height: widget.cellSize,
                  color: cellColor,
                  child:
                      hasPieces
                          ? _buildChecker(displayColor!, pieceCount)
                          : null,
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildChecker(CheckerColor color, int count) {
    return Padding(
      padding: EdgeInsets.all(widget.cellSize * 0.1),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The checker piece
          Container(
            decoration: BoxDecoration(
              color: color == CheckerColor.white ? Colors.white : Colors.black,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),

          // Only display the count if there's more than one checker
          if (count > 1)
            Text(
              '$count',
              style: TextStyle(
                color:
                    color == CheckerColor.white ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: widget.cellSize * 0.4,
              ),
            ),
        ],
      ),
    );
  }
}
