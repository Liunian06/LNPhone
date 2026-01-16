import 'package:flutter/material.dart';
import 'app_model.dart';

/// 网格应用模型 - 支持固定位置
class GridAppModel {
  final String? appId; // null表示空位
  final int row; // 0-5
  final int column; // 0-3

  const GridAppModel({this.appId, required this.row, required this.column});

  int get index => row * 4 + column;

  bool get isEmpty => appId == null;

  GridAppModel copyWith({String? appId, int? row, int? column}) {
    return GridAppModel(
      appId: appId ?? this.appId,
      row: row ?? this.row,
      column: column ?? this.column,
    );
  }
}

/// 网格页面数据
class GridPageData {
  final List<GridAppModel> cells; // 24个单元格

  GridPageData({required this.cells});

  factory GridPageData.empty() {
    return GridPageData(
      cells: List.generate(
        24,
        (index) =>
            GridAppModel(appId: null, row: index ~/ 4, column: index % 4),
      ),
    );
  }

  GridAppModel getCellAt(int row, int column) {
    return cells.firstWhere(
      (cell) => cell.row == row && cell.column == column,
      orElse: () => GridAppModel(row: row, column: column),
    );
  }

  GridPageData setAppAt(int row, int column, String? appId) {
    final newCells = cells.map((cell) {
      if (cell.row == row && cell.column == column) {
        return cell.copyWith(appId: appId);
      }
      return cell;
    }).toList();
    return GridPageData(cells: newCells);
  }

  GridPageData swapApps(int fromRow, int fromCol, int toRow, int toCol) {
    final fromIndex = fromRow * 4 + fromCol;
    final toIndex = toRow * 4 + toCol;

    final fromAppId = cells[fromIndex].appId;
    final toAppId = cells[toIndex].appId;

    final newCells = List<GridAppModel>.from(cells);
    newCells[fromIndex] = cells[fromIndex].copyWith(appId: toAppId);
    newCells[toIndex] = cells[toIndex].copyWith(appId: fromAppId);

    return GridPageData(cells: newCells);
  }
}
