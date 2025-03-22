// edit_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class EditState {
  final String fromDate;
  final String toDate;
  final List<Map<String, dynamic>> data;
  final bool isLoading;
  final String message;
  final bool isError;

  EditState({
    required this.fromDate,
    required this.toDate,
    this.data = const [],
    this.isLoading = false,
    this.message = '',
    this.isError = false,
  });

  EditState copyWith({
    String? fromDate,
    String? toDate,
    List<Map<String, dynamic>>? data,
    bool? isLoading,
    String? message,
    bool? isError,
  }) {
    return EditState(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      isError: isError ?? this.isError,
    );
  }
}

abstract class EditEvent {}

class FromDateChanged extends EditEvent {
  final String fromDate;
  FromDateChanged(this.fromDate);
}

class ToDateChanged extends EditEvent {
  final String toDate;
  ToDateChanged(this.toDate);
}

class SubmitEvent extends EditEvent {}

class ResetEvent extends EditEvent {}

class DeleteEvent extends EditEvent {
  final String recNo;
  DeleteEvent(this.recNo);
}

class EditBloc extends Bloc<EditEvent, EditState> {
  EditBloc() : super(EditState(
    fromDate: "01-Jan-${DateTime.now().year}",
    toDate: "01-${_getMonthName(DateTime.now().month)}-${DateTime.now().year}",
  )) {
    on<FromDateChanged>((event, emit) {
      emit(state.copyWith(fromDate: event.fromDate, message: ''));
    });

    on<ToDateChanged>((event, emit) {
      emit(state.copyWith(toDate: event.toDate, message: ''));
    });

    on<ResetEvent>((event, emit) {
      emit(EditState(
        fromDate: "01-Jan-${DateTime.now().year}",
        toDate: "01-${_getMonthName(DateTime.now().month)}-${DateTime.now().year}",
      ));
    });

    on<SubmitEvent>((event, emit) async {
      if (state.fromDate.isEmpty || state.toDate.isEmpty) {
        emit(state.copyWith(
          message: 'Please select both dates',
          isError: true,
        ));
        return;
      }

      emit(state.copyWith(isLoading: true, message: ''));
      try {
        final response = await http.get(
          Uri.parse(
            'http://localhost/sp_GetWarrantyAMCMasterDetails.php?UserCode=1&CompanyCode=101&FromDate=${state.fromDate}&ToDate=${state.toDate}&AccountCode',
          ),
        );
        final jsonData = json.decode(response.body);
        final data = (jsonData['data'] as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        emit(state.copyWith(
          data: data,
          isLoading: false,
          message: 'Data loaded successfully',
          isError: false,
        ));
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          message: 'Error loading data',
          isError: true,
        ));
      }
    });

    on<DeleteEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true, message: ''));
      try {
        final url = 'http://localhost/sp_DeleteWarrantyAMCMaster.php?UserCode=1&CompanyCode=101&RecNo=${event.recNo}';
        developer.log('Delete API Request: $url', name: 'DeleteAPI');

        final response = await http.get(Uri.parse(url));

        developer.log('Delete API Status: ${response.statusCode}', name: 'DeleteAPI');
        developer.log('Delete API Response: ${response.body}', name: 'DeleteAPI');

        final jsonData = json.decode(response.body);
        String message = 'Record deleted successfully';
        if (jsonData is List && jsonData.isNotEmpty) {
          message = jsonData[0]['ResultMsg'] ?? 'Record deleted successfully';
        }

        if (response.statusCode == 200) {
          add(SubmitEvent());
          emit(state.copyWith(
            isLoading: false,
            message: message,
            isError: false,
          ));
        } else {
          emit(state.copyWith(
            isLoading: false,
            message: 'Delete failed: ${response.statusCode}',
            isError: true,
          ));
        }
      } catch (e) {
        developer.log('Delete API Error: $e', name: 'DeleteAPI');
        emit(state.copyWith(
          isLoading: false,
          message: 'Error deleting record: $e',
          isError: true,
        ));
      }
    });
  }

  static String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}