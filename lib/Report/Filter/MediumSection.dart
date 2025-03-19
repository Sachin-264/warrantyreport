import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:warrantyreport/Report/Filter/filterbloc.dart';

class MediumSection extends StatefulWidget {
  final Function(Map<String, dynamic>) onDataChanged;

  const MediumSection({Key? key, required this.onDataChanged}) : super(key: key);

  @override
  _MediumSectionState createState() => _MediumSectionState();
}

class _MediumSectionState extends State<MediumSection> with AutomaticKeepAliveClientMixin {
  late final Map<String, TextEditingController> controllers;
  bool isEditing = false;
  int? selectedIndex;
  String selectedSparePartsOption = 'Yes';
  List<Map<String, dynamic>> items = [];
  List<DateTime> serviceDates = [];
  Timer? _updateTimer;
  Map<String, dynamic>? selectedItem;

  @override
  bool get wantKeepAlive => true;

  late final _sparePartsItems = ["Yes", "No"].map((option) => DropdownMenuItem(
    value: option,
    child: Text(option, style: GoogleFonts.poppins()),
  )).toList();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    context.read<FilterBloc>().stream.listen((state) {
      if (state.itemDetails.isNotEmpty && selectedItem == null) {
        setState(() {
          selectedItem = state.itemDetails[0];
          _updateFields(state.itemDetails[0]);
        });
      }
    });
  }

  void _initializeControllers() {
    controllers = {
      'itemName': TextEditingController(),
      'MCNo': TextEditingController(),
      'itemRemarks': TextEditingController(),
      'Qty': TextEditingController(),
      'warrantyFrom': TextEditingController(),
      'BillNo': TextEditingController(),
      'HSNCode': TextEditingController(),
      'AMCStartDate': TextEditingController(),
      'AMCEndDate': TextEditingController(),
      'BillDate': TextEditingController(),
      'InstallationAddress': TextEditingController(),
      'serviceDate': TextEditingController(),
    };
  }

  void _resetFields() {
    setState(() {
      controllers.values.forEach((c) => c.clear());
      isEditing = false;
      selectedIndex = null;
      selectedSparePartsOption = 'Yes';
      items.clear();
      serviceDates.clear();
      selectedItem = null;
    });
    _updateParentData();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _updateParentData() {
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.onDataChanged({'items': items});
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isMultiLine = false,
    bool isDate = false,
    double widthFactor = 0.5,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          width: MediaQuery.of(context).size.width * widthFactor,
          child: TextField(
            controller: controller,
            maxLines: isMultiLine ? 2 : 1,
            keyboardType: keyboardType,
            readOnly: isDate,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: isDate
                  ? IconButton(
                icon: Icon(Icons.calendar_today, color: Colors.blue[900]),
                onPressed: () => _selectDate(context, controller),
              )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormRow(List<Widget> children) {
    return Row(
      children: children.expand((w) => [w, const SizedBox(width: 16)]).toList()..removeLast(),
    );
  }

  Widget _buildSparePartsDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("With Spare Parts:", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: DropdownButtonFormField<String>(
            value: selectedSparePartsOption,
            items: _sparePartsItems,
            onChanged: (value) => mounted ? setState(() => selectedSparePartsOption = value ?? 'Yes') : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _updateFields(Map<String, dynamic> item) {
    if (!mounted) return;
    setState(() {
      selectedItem = item;
      controllers['itemName']?.text = item['name'] ?? '';
      controllers['MCNo']?.text = item['mcNo'] ?? '';
      controllers['itemRemarks']?.text = item['itemRemarks'] ?? '';
      controllers['HSNCode']?.text = item['hsnCode'] ?? '';
      controllers['AMCStartDate']?.text = item['amcStartDate'] ?? '';
      controllers['AMCEndDate']?.text = item['amcEndDate'] ?? '';
      controllers['InstallationAddress']?.text = item['installationAddress'] ?? '';
    });
  }

  void _addItem() {
    if (controllers['itemName']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item Name is required')));
      return;
    }

    final formData = {
      'SNo': items.length + 1,
      'IsEntryType': '',
      'itemName': controllers['itemName']!.text,
      'BillNo': controllers['BillNo']!.text,
      'BillDate': controllers['BillDate']!.text,
      'ItemNo': selectedItem?['id']?.toString() ?? '',
      'MCNo': controllers['MCNo']!.text,
      'itemRemarks': controllers['itemRemarks']!.text,
      'HSNCode': controllers['HSNCode']!.text,
      'Qty': controllers['Qty']!.text,
      'AMCStartDate': controllers['AMCStartDate']!.text,
      'AMCEndDate': controllers['AMCEndDate']!.text,
      'WithSpareParts': selectedSparePartsOption,
      'InstallationAddress': controllers['InstallationAddress']!.text,
      'serviceDates': serviceDates.map((date) => date.toIso8601String()).toList(),
    };

    setState(() {
      if (isEditing) {
        items[selectedIndex!] = formData;
      } else {
        items.add(formData);
      }
      isEditing = false;
      selectedIndex = null;
      serviceDates.clear();
    });

    controllers.values.forEach((c) => c.clear());
    _updateParentData();
  }

  void _editItem(int index) {
    final editedItem = items[index];
    final itemId = editedItem['ItemNo'];
    final itemDetails = context.read<FilterBloc>().state.itemDetails;

    Map<String, dynamic>? matchedItem;
    for (var item in itemDetails) {
      if (item['id'].toString() == itemId) {
        matchedItem = item;
        break;
      }
    }

    setState(() {
      isEditing = true;
      selectedIndex = index;

      if (matchedItem != null) {
        selectedItem = matchedItem;
        _updateFields(matchedItem);
      }

      controllers['itemName']!.text = editedItem['itemName'] ?? '';
      controllers['MCNo']!.text = editedItem['MCNo'] ?? '';
      controllers['itemRemarks']!.text = editedItem['itemRemarks'] ?? '';
      controllers['Qty']!.text = editedItem['Qty'] ?? '';
      controllers['HSNCode']!.text = editedItem['HSNCode'] ?? '';
      controllers['AMCStartDate']!.text = editedItem['AMCStartDate'] ?? '';
      controllers['AMCEndDate']!.text = editedItem['AMCEndDate'] ?? '';
      controllers['BillNo']!.text = editedItem['BillNo'] ?? '';
      controllers['BillDate']!.text = editedItem['BillDate'] ?? '';
      controllers['InstallationAddress']!.text = editedItem['InstallationAddress'] ?? '';

      selectedSparePartsOption = editedItem['WithSpareParts'] ?? 'Yes';

      serviceDates = [];
      if (editedItem['serviceDates'] != null) {
        for (var date in editedItem['serviceDates']) {
          if (date is String) {
            serviceDates.add(DateTime.parse(date));
          } else if (date is DateTime) {
            serviceDates.add(date);
          }
        }
      }
    });

    _updateParentData();
  }

  void _deleteItem(int index) {
    setState(() => items.removeAt(index));
    _updateParentData();
  }

  void _editDate(int index, DateTime newDate) {
    setState(() => serviceDates[index] = newDate);
    _updateParentData();
  }

  void _deleteDate(int index) {
    setState(() => serviceDates.removeAt(index));
    _updateParentData();
  }

  Widget _buildActionButtons() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                controllers.values.forEach((c) => c.clear());
                setState(() {
                  isEditing = false;
                  selectedIndex = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(120, 50),
              ),
              child: Text("Clear All", style: GoogleFonts.poppins(color: Colors.white)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(120, 50),
              ),
              child: Text(
                isEditing ? "Update Item" : "Add Item",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButtons() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            if (controllers['serviceDate']!.text.isNotEmpty) {
              final date = DateTime.parse(controllers['serviceDate']!.text);
              setState(() => serviceDates.add(date));
              controllers['serviceDate']!.clear();
              _updateParentData();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text("Add Date", style: GoogleFonts.poppins(color: Colors.white)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => controllers['serviceDate']!.clear(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text("Clear Date", style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildItemNameField(List<Map<String, dynamic>> itemDetails) {
    if (isEditing) {
      return _buildTextField(label: "Item Name:", controller: controllers['itemName']!, widthFactor: 0.48);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Item Name:",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.48,
            child: DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedItem != null &&
                  itemDetails.any((item) => item['id']?.toString() == selectedItem?['id']?.toString())
                  ? itemDetails.firstWhere((item) => item['id']?.toString() == selectedItem?['id']?.toString())
                  : (itemDetails.isNotEmpty ? itemDetails[0] : null),
              items: itemDetails.map((item) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: item,
                  child: Text(
                    item['name'] ?? '',
                    style: GoogleFonts.poppins(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newItem) {
                if (newItem != null && mounted) {
                  setState(() {
                    _updateFields(newItem);
                  });
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              isExpanded: true,
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<FilterBloc, FilterState>(
      listener: (context, state) {
        if (!state.isLoading && state.billNumbers.isEmpty && state.itemDetails.isEmpty) {
          _resetFields();
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 700,
                      child: _buildFormColumn(),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 432,
                      child: _buildItemsTableColumn(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormColumn() {
    return Expanded(
      flex: 2,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Item Detail",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
            const SizedBox(height: 16),
            BlocSelector<FilterBloc, FilterState, List<Map<String, dynamic>>>(
              selector: (state) => state.itemDetails,
              builder: (context, itemDetails) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItemNameField(itemDetails),
                    _buildTextField(label: "M/C No:", controller: controllers['MCNo']!, widthFactor: 0.48),
                    _buildTextField(
                        label: "Item Remarks:",
                        controller: controllers['itemRemarks']!,
                        isMultiLine: true,
                        widthFactor: 0.48),
                    _buildFormRow([
                      _buildTextField(
                        label: "Qty:",
                        controller: controllers['Qty']!,
                        widthFactor: 0.222,
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField(
                        label: "SAC/HSN:",
                        controller: controllers['HSNCode']!,
                        widthFactor: 0.222,
                      ),
                    ]),
                    _buildFormRow([
                      _buildTextField(
                          label: "From Date:",
                          controller: controllers['AMCStartDate']!,
                          widthFactor: 0.222,
                          isDate: true),
                      _buildTextField(
                          label: "To Date:",
                          controller: controllers['AMCEndDate']!,
                          widthFactor: 0.222,
                          isDate: true),
                    ]),
                    _buildSparePartsDropdown(),
                    _buildTextField(
                        label: "Installation Address:",
                        controller: controllers['InstallationAddress']!,
                        isMultiLine: true,
                        widthFactor: 0.48),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildTextField(
                                label: "Tentative Service Date:",
                                controller: controllers['serviceDate']!,
                                widthFactor: 1,
                                isDate: true,
                              ),
                              _buildDateButtons(),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: ServiceDateTable(
                            key: ValueKey(serviceDates.hashCode),
                            dates: serviceDates,
                            onEdit: _editDate,
                            onDelete: _deleteDate,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTableColumn() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (items.isNotEmpty) ...[
              Text("Added Items",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
              const SizedBox(height: 10),
              ItemTable(
                key: ValueKey(items.hashCode),
                items: items,
                onEdit: _editItem,
                onDelete: _deleteItem,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ItemTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const ItemTable({
    Key? key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          headingRowHeight: 45,
          dataRowHeight: 60,
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade300, width: 0.5),
            verticalInside: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
          headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blue.shade100),
          columns: const [
            DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('M/C No', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('SAC/HSN', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return DataRow(
              color: MaterialStateColor.resolveWith(
                    (states) => index.isEven ? Colors.white : Colors.grey.shade100,
              ),
              cells: [
                DataCell(SizedBox(width: 200, child: Text(item['itemName'] ?? ''))),
                DataCell(SizedBox(width: 100, child: Text(item['MCNo'] ?? ''))),
                DataCell(SizedBox(width: 100, child: Text(item['HSNCode'] ?? ''))),
                DataCell(SizedBox(width: 60, child: Center(child: Text(item['Qty'] ?? '')))),
                DataCell(
                  Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Tooltip(
                          message: 'Edit',
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                            onPressed: () => onEdit(index),
                          ),
                        ),
                        Tooltip(
                          message: 'Delete',
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                            onPressed: () => onDelete(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ServiceDateTable extends StatefulWidget {
  final List<DateTime> dates;
  final Function(int, DateTime) onEdit;
  final Function(int) onDelete;

  const ServiceDateTable({
    Key? key,
    required this.dates,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  _ServiceDateTableState createState() => _ServiceDateTableState();
}

class _ServiceDateTableState extends State<ServiceDateTable> {
  Future<void> _pickDate(BuildContext context, int index) async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: widget.dates[index],
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (newDate != null) {
      widget.onEdit(index, newDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          headingRowHeight: 40,
          dataRowHeight: 50,
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade300, width: 0.5),
            verticalInside: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
          headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blue.shade100),
          columns: const [
            DataColumn(label: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: widget.dates.asMap().entries.map((entry) {
            final index = entry.key;
            final date = entry.value;
            return DataRow(
              color: MaterialStateColor.resolveWith(
                    (states) => index.isEven ? Colors.white : Colors.grey.shade100,
              ),
              cells: [
                DataCell(Center(child: Text('${index + 1}'))),
                DataCell(Center(child: Text("${date.toLocal()}".split(' ')[0]))),
                DataCell(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _pickDate(context, index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => widget.onDelete(index),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}