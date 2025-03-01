import 'package:flutter/material.dart';

class TableEditor extends StatefulWidget {
  final List<List<String>> cells;
  final bool hasHeader;
  final Function(List<List<String>>, bool) onChanged;

  const TableEditor({
    super.key,
    required this.cells,
    required this.hasHeader,
    required this.onChanged,
  });

  @override
  State<TableEditor> createState() => _TableEditorState();
}

class _TableEditorState extends State<TableEditor> {
  late List<List<String>> _cells;
  late bool _hasHeader;

  @override
  void initState() {
    super.initState();
    _cells = List.from(widget.cells.map((row) => List<String>.from(row)));
    _hasHeader = widget.hasHeader;
  }

  @override
  void didUpdateWidget(TableEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cells != widget.cells || oldWidget.hasHeader != widget.hasHeader) {
      _cells = List.from(widget.cells.map((row) => List<String>.from(row)));
      _hasHeader = widget.hasHeader;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table controls
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_box_outlined, size: 20),
              tooltip: 'Add Row',
              onPressed: _addRow,
            ),
            IconButton(
              icon: const Icon(Icons.table_rows_outlined, size: 20),
              tooltip: 'Add Column',
              onPressed: _addColumn,
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Switch(
                  value: _hasHeader,
                  onChanged: (value) {
                    setState(() {
                      _hasHeader = value;
                      widget.onChanged(_cells, _hasHeader);
                    });
                  },
                ),
                const Text('Header Row'),
              ],
            ),
          ],
        ),

        // Table cells
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          margin: const EdgeInsets.only(top: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTable(),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_cells.isEmpty || _cells[0].isEmpty) {
      return const SizedBox(
        height: 100,
        width: 200,
        child: Center(
          child: Text('Empty table. Add rows and columns to get started.'),
        ),
      );
    }

    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: _buildTableRows(),
    );
  }

  List<TableRow> _buildTableRows() {
    final rows = <TableRow>[];

    for (var i = 0; i < _cells.length; i++) {
      final isHeader = i == 0 && _hasHeader;

      rows.add(
        TableRow(
          decoration: isHeader
              ? BoxDecoration(color: Colors.grey.shade200)
              : null,
          children: List.generate(
            _cells[i].length,
            (j) => TableCell(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: IntrinsicWidth(
                  child: TextField(
                    controller: TextEditingController(text: _cells[i][j]),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      isDense: true,
                    ),
                    style: isHeader
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                    onChanged: (value) {
                      _cells[i][j] = value;
                      widget.onChanged(_cells, _hasHeader);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return rows;
  }

  void _addRow() {
    setState(() {
      if (_cells.isEmpty) {
        // If table is empty, add a row with one cell
        _cells.add(['']);
      } else {
        // Add a row with the same number of columns
        final newRow = List<String>.filled(_cells[0].length, '');
        _cells.add(newRow);
      }
      widget.onChanged(_cells, _hasHeader);
    });
  }

  void _addColumn() {
    setState(() {
      if (_cells.isEmpty) {
        // If table is empty, add a row with one cell
        _cells.add(['']);
      } else {
        // Add a column to each row
        for (final row in _cells) {
          row.add('');
        }
      }
      widget.onChanged(_cells, _hasHeader);
    });
  }

  void _removeRow(int index) {
    if (_cells.length <= 1) return; // Don't remove the last row

    setState(() {
      _cells.removeAt(index);
      widget.onChanged(_cells, _hasHeader);
    });
  }

  void _removeColumn(int index) {
    if (_cells.isEmpty || _cells[0].length <= 1) return; // Don't remove the last column

    setState(() {
      for (final row in _cells) {
        row.removeAt(index);
      }
      widget.onChanged(_cells, _hasHeader);
    });
  }
}
