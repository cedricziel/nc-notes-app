import 'package:flutter/material.dart';

class TableEditor extends StatefulWidget {
  final List<List<String>> initialCells;
  final bool initialHasHeader;
  final Function(List<List<String>>, bool) onChanged;

  const TableEditor({
    super.key,
    required this.initialCells,
    required this.initialHasHeader,
    required this.onChanged,
  });

  @override
  State<TableEditor> createState() => _TableEditorState();
}

class _TableEditorState extends State<TableEditor> {
  late List<List<String>> _cells;
  late bool _hasHeader;
  late List<List<TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    _cells = List.from(widget.initialCells.map((row) => List<String>.from(row)));
    _hasHeader = widget.initialHasHeader;
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = [];
    for (var i = 0; i < _cells.length; i++) {
      final rowControllers = <TextEditingController>[];
      for (var j = 0; j < _cells[i].length; j++) {
        rowControllers.add(TextEditingController(text: _cells[i][j]));
      }
      _controllers.add(rowControllers);
    }
  }

  @override
  void didUpdateWidget(TableEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCells != widget.initialCells ||
        oldWidget.initialHasHeader != widget.initialHasHeader) {

      // Store current cursor positions
      final cursorPositions = <List<TextSelection>>[];
      for (var i = 0; i < _controllers.length; i++) {
        final rowSelections = <TextSelection>[];
        for (var j = 0; j < _controllers[i].length; j++) {
          rowSelections.add(_controllers[i][j].selection);
        }
        cursorPositions.add(rowSelections);
      }

      // Update cells and header
      _cells = List.from(widget.initialCells.map((row) => List<String>.from(row)));
      _hasHeader = widget.initialHasHeader;

      // Dispose old controllers
      for (var row in _controllers) {
        for (var controller in row) {
          controller.dispose();
        }
      }

      // Create new controllers
      _initializeControllers();

      // Restore cursor positions where possible
      for (var i = 0; i < _controllers.length && i < cursorPositions.length; i++) {
        for (var j = 0; j < _controllers[i].length && j < cursorPositions[i].length; j++) {
          final selection = cursorPositions[i][j];
          if (selection.isValid && selection.start <= _controllers[i][j].text.length) {
            _controllers[i][j].selection = selection;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (var row in _controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
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
                    controller: _controllers[i][j],
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
        _controllers.add([TextEditingController(text: '')]);
      } else {
        // Add a row with the same number of columns
        final newRow = List<String>.filled(_cells[0].length, '');
        _cells.add(newRow);

        // Add controllers for the new row
        final newRowControllers = <TextEditingController>[];
        for (var i = 0; i < newRow.length; i++) {
          newRowControllers.add(TextEditingController(text: ''));
        }
        _controllers.add(newRowControllers);
      }
      widget.onChanged(_cells, _hasHeader);
    });
  }

  void _addColumn() {
    setState(() {
      if (_cells.isEmpty) {
        // If table is empty, add a row with one cell
        _cells.add(['']);
        _controllers.add([TextEditingController(text: '')]);
      } else {
        // Add a column to each row
        for (var i = 0; i < _cells.length; i++) {
          _cells[i].add('');
          _controllers[i].add(TextEditingController(text: ''));
        }
      }
      widget.onChanged(_cells, _hasHeader);
    });
  }

  void _removeRow(int index) {
    if (_cells.length <= 1) return; // Don't remove the last row

    setState(() {
      // Dispose controllers for the removed row
      for (var controller in _controllers[index]) {
        controller.dispose();
      }

      _cells.removeAt(index);
      _controllers.removeAt(index);
      widget.onChanged(_cells, _hasHeader);
    });
  }

  void _removeColumn(int index) {
    if (_cells.isEmpty || _cells[0].length <= 1) return; // Don't remove the last column

    setState(() {
      for (var i = 0; i < _cells.length; i++) {
        // Dispose controller for the removed cell
        _controllers[i][index].dispose();

        _cells[i].removeAt(index);
        _controllers[i].removeAt(index);
      }
      widget.onChanged(_cells, _hasHeader);
    });
  }
}
