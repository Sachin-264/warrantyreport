import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'editfilterbloc.dart';

class EditMediumSection extends StatefulWidget {
  final Function(Map<String, dynamic>) onDataChanged;

  const EditMediumSection({Key? key, required this.onDataChanged}) : super(key: key);

  @override
  _EditMediumSectionState createState() => _EditMediumSectionState();
}

class _EditMediumSectionState extends State<EditMediumSection> with AutomaticKeepAliveClientMixin {
  late final Map<String, TextEditingController> controllers;
  bool isEditing = false;
  int? selectedIndex;
  String selectedSparePartsOption = 'Yes';
  List<Map<String, dynamic>> items = [];
  Map<int, List<DateTime>> serviceDatesMap = {};
  Timer? _updateTimer;
  Map<String, dynamic>? selectedItem;
  bool isWarrantyDataLoaded = false;
  int? selectedItemIndex;

  @override
  bool get wantKeepAlive => true;

  late final _sparePartsItems = ["Yes", "No"].map((option) => DropdownMenuItem(
    value: option,
    child: Text(option, style: GoogleFonts.poppins(fontSize: 14)),
  )).toList();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _listenToBlocState();
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

  void _listenToBlocState() {
    context.read<EditFilterBloc>().stream.listen((state) {
      if (state.warrantyData != null && !isWarrantyDataLoaded) {
        setState(() {
          items = List<Map<String, dynamic>>.from(state.warrantyData!['items'] ?? []);
          final serviceDates = state.warrantyData!['serviceDates'] as List<dynamic>? ?? [];
          serviceDatesMap = {};
          for (var date in serviceDates) {
            final sno = int.parse(date['SNo'].toString());
            serviceDatesMap[sno] ??= [];
            final dateStr = date['TentativeServiceDate'] as String;
            final parsedDate = DateFormat('dd-MMM-yyyy').parse(dateStr);
            serviceDatesMap[sno]!.add(parsedDate);
          }
          isWarrantyDataLoaded = true;
        });
        _updateParentData();
      }

      if (state.itemDetails.isNotEmpty && !state.isItemDetailsLoading) {
        setState(() {
          if (state.itemDetails.isNotEmpty) {
            selectedItemIndex = 0;
            selectedItem = state.itemDetails[selectedItemIndex!];
            _updateFields(selectedItem!);
          } else {
            selectedItem = null;
            selectedItemIndex = null;
          }
        });
      }
    });
  }

  void _resetFields() {
    if (!mounted) return;
    setState(() {
      controllers.values.forEach((c) => c.clear());
      isEditing = false;
      selectedIndex = null;
      selectedSparePartsOption = 'Yes';
      selectedItem = null;
      selectedItemIndex = null;
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
      if (mounted) {
        final data = {'items': items};
        widget.onDataChanged(data);
      }
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
              hintText: isDate ? 'Select Date' : null,
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              suffixIcon: isDate
                  ? IconButton(
                icon: Icon(Icons.calendar_today, color: Colors.blue[900]),
                onPressed: () => _selectDate(context, controller),
              )
                  : null,
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
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
            onChanged: (value) {
              if (mounted) {
                setState(() => selectedSparePartsOption = value ?? 'Yes');
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            dropdownColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _updateFields(Map<String, dynamic> item) {
    if (!mounted) return;
    setState(() {
      selectedItem = item;
      controllers['itemName']?.text = item['ItemName'] ?? item['name'] ?? '';
      controllers['MCNo']?.text = item['MCNo'] ?? item['mcNo'] ?? '';
      controllers['itemRemarks']?.text = item['ItemRemarks'] ?? item['itemRemarks'] ?? '';
      controllers['HSNCode']?.text = item['HSNCode'] ?? item['hsnCode'] ?? '';
      controllers['AMCStartDate']?.text = item['AMCStartDate'] ?? item['amcStartDate'] ?? '';
      controllers['AMCEndDate']?.text = item['AMCEndDate'] ?? item['amcEndDate'] ?? '';
      controllers['InstallationAddress']?.text = item['InstallationAddress'] ?? item['installationAddress'] ?? '';
      controllers['Qty']?.text = item['Qty']?.toString() ?? '';
      controllers['BillNo']?.text = item['BillNo'] ?? '';
      controllers['BillDate']?.text = item['BillDate'] ?? '';
      selectedSparePartsOption = item['WithSpareParts']?.isNotEmpty == true ? item['WithSpareParts'] : (item['withSpareParts']?.isNotEmpty == true ? item['withSpareParts'] : 'Yes');
    });
  }

  void _addItem() {
    if (controllers['itemName']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item Name is required')),
      );
      return;
    }

    int sno;
    if (selectedIndex != null) {
      final currentSNo = items[selectedIndex!]['SNo'];
      sno = currentSNo is int ? currentSNo : int.parse(currentSNo.toString());
    } else {
      sno = items.length + 1;
    }

    final formData = {
      'SNo': sno,
      'IsEntryType': '',
      'ItemName': controllers['itemName']!.text,
      'BillNo': controllers['BillNo']!.text,
      'BillDate': controllers['BillDate']!.text,
      'ItemNo': selectedItem?['id']?.toString() ?? '',
      'MCNo': controllers['MCNo']!.text,
      'ItemRemarks': controllers['itemRemarks']!.text,
      'HSNCode': controllers['HSNCode']!.text,
      'Qty': controllers['Qty']!.text,
      'AMCStartDate': controllers['AMCStartDate']!.text,
      'AMCEndDate': controllers['AMCEndDate']!.text,
      'WithSpareParts': selectedSparePartsOption,
      'InstallationAddress': controllers['InstallationAddress']!.text,
      'serviceDates': serviceDatesMap[sno] ?? [],
    };

    if (!mounted) return;
    setState(() {
      if (isEditing && selectedIndex != null) {
        items[selectedIndex!] = formData;
      } else {
        items.add(formData);
      }
      isEditing = false;
      selectedIndex = null;
      controllers.values.forEach((c) => c.clear());
      selectedItem = null;
    });
    _updateParentData();
  }

  void _editItem(int index) {
    if (!mounted) return;
    final editedItem = items[index];
    setState(() {
      isEditing = true;
      selectedIndex = index;
      selectedItem = editedItem;
      _updateFields(editedItem);
    });
  }

  void _deleteItem(int index) {
    if (!mounted) return;
    if (isEditing && selectedIndex == index) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete an item being edited. Please update or cancel first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      final sno = items[index]['SNo'] is int ? items[index]['SNo'] : int.parse(items[index]['SNo'].toString());
      items.removeAt(index);
      serviceDatesMap.remove(sno);
    });
    _updateParentData();
  }

  void _editDate(int sno, int index, DateTime newDate) {
    if (!mounted) return;
    setState(() {
      serviceDatesMap[sno]![index] = newDate;
    });
    _updateParentData();
  }

  void _deleteDate(int sno, int index) {
    if (!mounted) return;
    setState(() {
      serviceDatesMap[sno]!.removeAt(index);
    });
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
                if (!mounted) return;
                controllers.values.forEach((c) => c.clear());
                setState(() {
                  isEditing = false;
                  selectedIndex = null;
                  selectedItem = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(120, 50),
              ),
              child: Text("Clear All", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(120, 50),
              ),
              child: Text(
                isEditing ? "Update Item" : "Add Item",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButtons(int sno) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            if (controllers['serviceDate']!.text.isNotEmpty) {
              final date = DateTime.parse(controllers['serviceDate']!.text);
              if (!mounted) return;
              setState(() {
                serviceDatesMap[sno] ??= [];
                serviceDatesMap[sno]!.add(date);
              });
              controllers['serviceDate']!.clear();
              _updateParentData();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text("Add Date", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            controllers['serviceDate']!.clear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text("Clear Date", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
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
          Text(
            "Item Name:",
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.48,
            child: itemDetails.isEmpty
                ? TextField(
              enabled: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                hintText: "No items available",
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
              ),
            )
                : DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedItem != null && itemDetails.any((item) => item['id'] == selectedItem!['id'])
                  ? itemDetails.firstWhere((item) => item['id'] == selectedItem!['id'])
                  : itemDetails.isNotEmpty
                  ? itemDetails[0]
                  : null,
              items: itemDetails.map((item) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: item,
                  child: Text(
                    item['name'] ?? 'Unnamed Item',
                    style: GoogleFonts.poppins(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newItem) {
                if (newItem != null && mounted) {
                  setState(() {
                    selectedItem = newItem;
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
    return BlocListener<EditFilterBloc, EditFilterState>(
      listener: (context, state) {
        if (!state.isLoading && state.billNumbers.isEmpty && state.itemDetails.isEmpty && state.warrantyData == null) {
          _resetFields();
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 700,
                    child: _buildFormColumn(),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 732,
                    child: _buildItemsTableColumn(),
                  ),
                ],
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Item Detail",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
          ),
          const SizedBox(height: 16),
          BlocSelector<EditFilterBloc, EditFilterState, List<Map<String, dynamic>>>(
            selector: (state) => state.itemDetails,
            builder: (context, itemDetails) {
              final sno = selectedIndex != null
                  ? (items[selectedIndex!]['SNo'] is int ? items[selectedIndex!]['SNo'] : int.parse(items[selectedIndex!]['SNo'].toString()))
                  : items.length + 1;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemNameField(itemDetails),
                  _buildTextField(label: "M/C No:", controller: controllers['MCNo']!, widthFactor: 0.48),
                  _buildTextField(
                    label: "Item Remarks:",
                    controller: controllers['itemRemarks']!,
                    isMultiLine: true,
                    widthFactor: 0.48,
                  ),
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
                      isDate: true,
                    ),
                    _buildTextField(
                      label: "To Date:",
                      controller: controllers['AMCEndDate']!,
                      widthFactor: 0.222,
                      isDate: true,
                    ),
                  ]),
                  _buildSparePartsDropdown(),
                  _buildTextField(
                    label: "Installation Address:",
                    controller: controllers['InstallationAddress']!,
                    isMultiLine: true,
                    widthFactor: 0.48,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildTextField(
                              label: "Tentative Service Date:",
                              controller: controllers['serviceDate']!,
                              widthFactor: 1,
                              isDate: true,
                            ),
                            _buildDateButtons(sno),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 4,
                        child: ServiceDateTable(
                          key: ValueKey(serviceDatesMap.hashCode),
                          dates: serviceDatesMap[sno] ?? [],
                          onEdit: (index, date) => _editDate(sno, index, date),
                          onDelete: (index) => _deleteDate(sno, index),
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
    );
  }

  Widget _buildItemsTableColumn() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (items.isNotEmpty) ...[
              Text(
                "Added Items",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
              ),
              const SizedBox(height: 10),
              ItemTable(
                key: ValueKey(items.hashCode),
                items: items,
                onEdit: _editItem,
                onDelete: _deleteItem,
              ),
            ] else
              Text(
                "No Items Added Yet",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
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
                  DataCell(SizedBox(width: 200, child: Text(item['ItemName'] ?? '', style: GoogleFonts.poppins(fontSize: 14)))),
                  DataCell(SizedBox(width: 100, child: Text(item['MCNo'] ?? '', style: GoogleFonts.poppins(fontSize: 14)))),
                  DataCell(SizedBox(width: 100, child: Text(item['HSNCode'] ?? '', style: GoogleFonts.poppins(fontSize: 14)))),
                  DataCell(SizedBox(width: 60, child: Center(child: Text(item['Qty']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 14))))),
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
                DataCell(Center(child: Text('${index + 1}', style: GoogleFonts.poppins(fontSize: 14)))),
                DataCell(Center(child: Text("${date.toLocal()}".split(' ')[0], style: GoogleFonts.poppins(fontSize: 14)))),
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