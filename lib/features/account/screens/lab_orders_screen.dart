import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../orders/orders_cubit.dart';
import '../../../core/models.dart';
import 'lab_order_list.dart';

class LabOrdersScreen extends StatelessWidget {
  const LabOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: Text('Lab Test Orders'),
          bottom: TabBar(
            isScrollable: true,
            tabs: <Tab>[
              Tab(text: 'Upcoming'),
              Tab(text: 'Processing'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: BlocBuilder<OrdersCubit, OrdersState>(
          builder: (context, state) {
            final labOrders = state.labBookings;
            return TabBarView(
              children: <Widget>[
                LabOrderList(
                  items: labOrders
                      .where((item) => item.status == LabBookingStatus.upcoming)
                      .toList(),
                ),
                LabOrderList(
                  items: labOrders
                      .where(
                        (item) => item.status == LabBookingStatus.processing,
                      )
                      .toList(),
                ),
                LabOrderList(
                  items: labOrders
                      .where(
                        (item) => item.status == LabBookingStatus.completed,
                      )
                      .toList(),
                ),
                LabOrderList(
                  items: labOrders
                      .where(
                        (item) => item.status == LabBookingStatus.cancelled,
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LabBookingsScreen extends LabOrdersScreen {
  const LabBookingsScreen({super.key});
}

class LabTestOrdersScreen extends LabOrdersScreen {
  const LabTestOrdersScreen({super.key});
}
