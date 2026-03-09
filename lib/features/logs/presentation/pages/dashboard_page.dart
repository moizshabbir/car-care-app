import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection.dart';
import '../../../vehicles/presentation/bloc/vehicle_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import 'add_expense_page.dart';
import 'quick_log_page.dart';
import 'scan_receipt_page.dart';
import 'scan_mechanic_bill_page.dart';
import 'share_stats_page.dart';
import '../../../reports/presentation/pages/reports_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<DashboardBloc>();
        final vehicleId = context.read<VehicleBloc>().state.selectedVehicle?.id;
        if (vehicleId != null) {
          bloc.add(SubscribeToLogs(vehicleId: vehicleId));
        }
        return bloc;
      },
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleBloc, VehicleState>(
      listenWhen: (previous, current) => previous.selectedVehicle?.id != current.selectedVehicle?.id,
      listener: (context, state) {
        if (state.selectedVehicle != null) {
          context.read<DashboardBloc>().add(SubscribeToLogs(vehicleId: state.selectedVehicle!.id));
        }
      },
      child: Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Garage', style: TextStyle(fontSize: 12, color: Colors.grey)),
            BlocBuilder<VehicleBloc, VehicleState>(
              builder: (context, vehicleState) {
                if (vehicleState.status == VehicleStatus.loading) {
                  return const Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white));
                }

                if (vehicleState.vehicles.isEmpty) {
                  return const Text('No Vehicles', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white));
                }

                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: vehicleState.selectedVehicle?.id,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
                    dropdownColor: AppTheme.cardDark,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    isDense: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        final selected = vehicleState.vehicles.firstWhere((v) => v.id == newValue);
                        context.read<VehicleBloc>().add(SelectVehicle(selected));
                      }
                    },
                    items: vehicleState.vehicles.map<DropdownMenuItem<String>>((vehicle) {
                      return DropdownMenuItem<String>(
                        value: vehicle.id,
                        child: Text(vehicle.name),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShareStatsPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state.status == DashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.recentLogs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  "Your dashboard is looking a bit lonely! Tap the scan icon below to log your first fuel fill-up or maintenance task.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(state),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                      title: 'Total Fuel',
                      value: NumberFormat.simpleCurrency().format(state.totalFuelCost),
                      trend: '+5%', // Dummy trend
                      icon: Icons.local_gas_station,
                      iconColor: Colors.orange,
                    )),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildStatCard(
                      title: 'Last Service',
                      value: NumberFormat.simpleCurrency().format(state.lastServiceCost),
                      subtext: state.lastServiceDate != null ? DateFormat('MMM dd').format(state.lastServiceDate!) : 'N/A',
                      icon: Icons.build,
                      iconColor: Colors.purple,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(state),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Logs', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsPage()));
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                _buildRecentLogs(state),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppTheme.cardDark,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.document_scanner, color: AppTheme.primary),
                      ),
                      title: const Text('Magic Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Auto-extract data from receipts', style: TextStyle(color: Colors.grey)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickLogPage()));
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.receipt_long, color: Colors.green),
                      ),
                      title: const Text('Scan Store Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Auto parts & accessories', style: TextStyle(color: Colors.grey)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanReceiptPage()));
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.handyman, color: Colors.amber),
                      ),
                      title: const Text('Scan Mechanic Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Repair & maintenance records', style: TextStyle(color: Colors.grey)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanMechanicBillPage()));
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.receipt, color: Colors.orange),
                      ),
                      title: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Manual entry for fuel or service', style: TextStyle(color: Colors.grey)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddExpensePage()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.document_scanner, color: Colors.white),
      ),
    ));
  }

  Widget _buildOverviewCard(DashboardState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF135BEC),
            const Color(0xFF135BEC).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text('Avg. Cost / KM', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(DateFormat('MMM yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            NumberFormat.simpleCurrency().format(state.avgCostPerKm),
            style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_down, color: Colors.greenAccent, size: 16),
                SizedBox(width: 4),
                Text('-2%', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Text('vs last month', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, String? trend, String? subtext, required IconData icon, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (trend != null)
            Text(trend, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))
          else if (subtext != null)
            Text(subtext, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(DashboardState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Last Refuel', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  state.lastRefuelDate != null ? _formatDaysAgo(state.lastRefuelDate!) : 'Never',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Odometer', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Icon(Icons.speed, color: Colors.grey, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${NumberFormat('#,###').format(state.odometer)} km', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDaysAgo(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  Widget _buildRecentLogs(DashboardState state) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.recentLogs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = state.recentLogs[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (log.type == LogType.fuel ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  log.type == LogType.fuel ? Icons.local_gas_station : Icons.build,
                  color: log.type == LogType.fuel ? Colors.blue : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(log.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(NumberFormat.simpleCurrency().format(log.amount), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(DateFormat('MMM dd').format(log.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
