import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharo/service/browse_borrow_requests_bloc/browse_borrow_request_bloc.dart';
import 'package:udharo/service/payment_bloc/payment_bloc.dart';
import 'package:udharo/view/widget/bottom_navigation_bar.dart';
import 'package:udharo/view/widget/custom_details_container.dart';
import 'package:udharo/view/widget/custom_dialog_box.dart';
import 'package:udharo/view/widget/custom_toast.dart';

class BrowseBorrowRequestsPage extends StatefulWidget {
  const BrowseBorrowRequestsPage({super.key});

  @override
  State<BrowseBorrowRequestsPage> createState() =>
      _BrowseBorrowRequestsPageState();
}

class _BrowseBorrowRequestsPageState extends State<BrowseBorrowRequestsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Borrow Requests'),
      ),
      body: BlocBuilder<BrowseBorrowRequestBloc, BrowseBorrowRequestState>(
        builder: (context, state) {
          if (state is BrowseBorrowRequestStateInitial) {
            BlocProvider.of<BrowseBorrowRequestBloc>(context)
                .add(BrowseBorrowRequestEventLoadRequests());
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is BrowseBorrowRequestStateLoaded) {
            final borrowRequests = state.borrowRequests.data?.borrowRequests;
            if (borrowRequests == null || borrowRequests.isEmpty) {
              return const Center(
                child: Text('No borrow requests found.'),
              );
            } else {
              return BlocConsumer<PaymentBloc, PaymentState>(
                listener: (context, state) {
                  // Listener logic here
                  if (state is PaymentStateAcceptSuccess) {
                          // borrow request accepted, make khalti payment

                          print('khalti payment state called');
                          context.read<PaymentBloc>().add(
                                PaymentEventMakeKhaltiPayment(
                                  context: context,
                                  amount: state.amount,
                                  productIdentity: state.borrowId,
                                  productName: 'Loan for: ${state.borrowId}',
                                ),
                              );
                        } else if (state is PaymentStateKhaltiPaymentSuccess) {
                          // verify khalti transaction

                          // print('verifying khalti transaction');

                          print('verification state called');


                          context.read<PaymentBloc>().add(
                                PaymentEventVerifyKhaltiTransaction(
                                  token: state.success.token,
                                  amount: state.success.amount,
                                ),
                              );

                          // CustomToast().showToast(
                          //   context: context,
                          //   message: 'Borrow request accepted successfully.',
                          // );
                        } else if (state
                            is PaymentStateKhaltiPaymentVerificationSuccess) {
                          final verificationData = state.success.data;

                          if(verificationData!=null){
                            context.read<PaymentBloc>().add(
                            PaymentEventSaveKhaltiTransaction(
                              idx: verificationData.idx!,
                              amount: verificationData.amount!,
                              senderName: verificationData.merchant!.name!,
                              createdOn: verificationData.createdOn!.toString(),
                              receiverName: verificationData.user!.name!,
                              feeAmount: verificationData.feeAmount!,
                            ),
                          );
                          }

                          
                          // show success message
                          // CustomToast().showToast(
                          //   context: context,
                          //   message: 'Borrow request accepted successfully.',
                          // );

                          // reset payment bloc
                          // context.read<PaymentBloc>().add(
                          //       PaymentEventResetPayment(),
                          //     );
                        }
                        else if(state is PaymentStateKhaltiPaymentSaveKhaltiPaymentSuccess){
                          CustomToast().showToast(
                            context: context,
                            message: 'Borrow request accepted successfully.',
                          );
                        }
                        else if (state is PaymentStateError) {
                          CustomToast().showToast(
                            context: context,
                            message: state.message,
                          );
                        }
                },
                builder: (context, paymentState) {
                  return SizedBox(
                    child: ListView.builder(
                      itemCount: borrowRequests.length,
                      itemBuilder: (context, index) {
                        final borrowRequest = borrowRequests[index];
                        return CustomDetailsContainer(
                          fields: [
                            Text('Borrower : ${borrowRequest.fullName}'),
                            Text('Purpose: ${borrowRequest.purpose}'),
                            Text('Amount: Rs.${borrowRequest.amount}'),
                            Text('Risk Factor: ${borrowRequest.riskFactor}'),
                            Text('Risk: ${borrowRequest.risk}'),
                            Text(
                                'Interest Rate: ${borrowRequest.interestRate}%'),
                            Text(
                                'Payback Period: ${borrowRequest.paybackPeriod} days'),
                          ],
                          showButton: true,
                          buttonName: 'Invest',
                          onPressed: () {
                            CustomDialogBox.showCustomDialogBox(
                              context,
                              'Invest in Borrow Request',
                              'Investing is a high-risk activity and may result in loss of funds. Are you sure you want to proceed?',
                              () {
                                context.read<PaymentBloc>().add(
                                      PaymentEventAcceptBorrowRequest(
                                        amount: borrowRequest.amount!,
                                        productIdentity: borrowRequest.id!,
                                      ),
                                    );
                                Navigator.of(context).pop();
                              },
                              buttonName: 'Invest',
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              );
            }
          } else if (state is BrowseBorrowRequestStateError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          } else {
            return const Center(
              child: Text('Error fetching data. Please try again later.'),
            );
          }
        },
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
