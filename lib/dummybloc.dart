import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:warrantyreport/Report/Filter/Customapi.dart';

// Events
abstract class DummyEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchCustomersEvent extends DummyEvent {}

class FetchBillNumbersEvent extends DummyEvent {
  final String customerId;
  FetchBillNumbersEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

// States
class DummyState extends Equatable {
  final bool isLoading;
  final List<Map<String, String>> customers;
  final List<Map<String, String>> billNumbers;
  final String? error;

  const DummyState({
    this.isLoading = false,
    this.customers = const [],
    this.billNumbers = const [],
    this.error,
  });

  DummyState copyWith({
    bool? isLoading,
    List<Map<String, String>>? customers,
    List<Map<String, String>>? billNumbers,
    String? error,
  }) {
    return DummyState(
      isLoading: isLoading ?? this.isLoading,
      customers: customers ?? this.customers,
      billNumbers: billNumbers ?? this.billNumbers,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, customers, billNumbers, error];
}

// BLoC
class DummyBloc extends Bloc<DummyEvent, DummyState> {
  DummyBloc() : super(const DummyState()) {
    on<FetchCustomersEvent>(_fetchCustomers);
    on<FetchBillNumbersEvent>(_fetchBillNumbers);
  }

  Future<void> _fetchCustomers(
      FetchCustomersEvent event, Emitter<DummyState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final customers = await FilterApiService.fetchCustomers();

      emit(state.copyWith(customers: customers, isLoading: false));
    } catch (e) {
      log('Error fetching customers: $e');
      emit(
          state.copyWith(isLoading: false, error: 'Failed to fetch customers'));
    }
  }

  Future<void> _fetchBillNumbers(
      FetchBillNumbersEvent event, Emitter<DummyState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final billNumbers =
          await FilterApiService.fetchBillNumbers(event.customerId);
      log('Fetched Bill Numbers: $billNumbers');
      emit(state.copyWith(billNumbers: billNumbers, isLoading: false));
    } catch (e) {
      log('Error fetching bill numbers: $e');
      emit(state.copyWith(
          isLoading: false, error: 'Failed to fetch bill numbers'));
    }
  }
}
