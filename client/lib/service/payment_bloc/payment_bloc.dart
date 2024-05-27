import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:udharo/data/repository/borrow_repository.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final BorrowRepository _borrowRepository;
  PaymentBloc(this._borrowRepository) : super(PaymentStateInitial()) {
    // make khalti payment
    on<PaymentEventMakeKhaltiPayment>(
      (event, emit) async {
        try {
          // make payment
          await KhaltiScope.of(event.context).pay(
            config: PaymentConfig(
              // amount: event.amount * 100,

              // for testing
              amount: 20 * 100,

              productIdentity: event.productIdentity,
              productName: event.productName,
            ),
            preferences: [
              PaymentPreference.khalti,
            ],
            onSuccess: (success) async {
              emit(PaymentStateKhaltiPaymentSuccess(success: success));
              // print('Success: ${success.token}');
            },
            onFailure: (failure) {
              emit(PaymentStateError(failure.message));
            },
          );
        } on Exception catch (e) {
          emit(PaymentStateError(e.toString()));
        }
      },
    );
    // accept borrow request
    on<PaymentEventAcceptBorrowRequest>(
      (event, emit) async {
        try {
          await _borrowRepository.acceptBorrowRequest(event.productIdentity);
          emit(PaymentStateAcceptSuccess());
        } on Exception catch (e) {
          emit(PaymentStateError(e.toString()));
        }
      },
    );
    // verify khalti transaction
    on<PaymentEventVerifyKhaltiTransaction>(
      (event, emit) async {
        try {
          await _borrowRepository.verifyKhaltiTransaction(pidx: event.pidx);
          emit(PaymentStateKhaltiPaymentVerificationSuccess());
        } on Exception catch (e) {
          emit(PaymentStateError(e.toString()));
        }
      },
    );
    on<PaymentEventResetPayment>(
      (event, emit) {
        emit(PaymentStateInitial());
      },
    );
  }
}
