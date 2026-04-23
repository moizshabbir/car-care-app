import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'transaction_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../injection.dart';
import '../../../vehicles/presentation/bloc/vehicle_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import 'add_expense_page.dart';
import 'quick_log_page.dart';
import 'scan_receipt_page.dart';
import 'scan_mechanic_bill_page.dart';
import 'share_stats_page.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import 'all_transactions_page.dart';

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
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final vehicleState = context.read<VehicleBloc>().state;
    final initialPage = vehicleState.selectedVehicle != null 
        ? vehicleState.vehicles.indexOf(vehicleState.selectedVehicle!)
        : 0;
    _pageController = PageController(viewportFraction: 0.85, initialPage: initialPage >= 0 ? initialPage : 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleBloc, VehicleState>(
      listenWhen: (previous, current) => previous.selectedVehicle?.id != current.selectedVehicle?.id,
      listener: (context, state) {
        if (state.selectedVehicle != null) {
          context.read<DashboardBloc>().add(SubscribeToLogs(vehicleId: state.selectedVehicle!.id));
          
          // Sync PageView if selection was changed from elsewhere
          final index = state.vehicles.indexOf(state.selectedVehicle!);
          if (_pageController.hasClients && _pageController.page?.round() != index) {
            _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          }
        }
      },
      child: Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Garage', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildVehicleSwitcher(),
          ),
          Expanded(
            child: BlocBuilder<DashboardBloc, DashboardState>(
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildOverviewCard(state),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildStatCard(
                                  title: 'Total Fuel',
                                  value: NumberFormat.currency(symbol: getIt<SettingsService>().currency, decimalDigits: 0).format(state.totalFuelCost),
                                  trend: '+5%', // Dummy trend
                                  icon: Icons.local_gas_station,
                                  iconColor: Colors.orange,
                                )),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: _buildStatCard(
                                  title: 'Last Service',
                                  value: NumberFormat.currency(symbol: getIt<SettingsService>().currency, decimalDigits: 0).format(state.lastServiceCost),
                                  subtext: state.lastServiceDate != null ? DateFormat(getIt<SettingsService>().dateFormat).format(state.lastServiceDate!) : 'N/A',
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
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllTransactionsPage()));
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
          ),
        ],
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
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.document_scanner, color: AppTheme.primary),
                      ),
                      title: const Text('Refuel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
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
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
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
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
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
            const Color(0xFF135BEC).withOpacity(0.8),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(DateFormat('MMM yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
                    Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                NumberFormat.currency(symbol: getIt<SettingsService>().currency).format(state.avgCostPerKm),
                style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                '/km',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                state.fuelEfficiency.toStringAsFixed(2),
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'km/L',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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
              color: iconColor.withOpacity(0.1),
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
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
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
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailPage(logItem: log)));
          },
          child: Container(
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
                  color: (log.type == LogType.fuel ? Colors.blue : Colors.orange).withOpacity(0.1),
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
                  Text(NumberFormat.currency(symbol: getIt<SettingsService>().currency).format(log.amount), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(DateFormat(getIt<SettingsService>().dateFormat).format(log.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        );
      },
    );
  }

    Widget _buildVehicleSwitcher() {
    return BlocBuilder<VehicleBloc, VehicleState>(
      builder: (context, state) {
        if (state.vehicles.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _pageController,
            itemCount: state.vehicles.length,
            onPageChanged: (index) {
              context.read<VehicleBloc>().add(SelectVehicle(state.vehicles[index]));
            },
            itemBuilder: (context, index) {
              final vehicle = state.vehicles[index];
              final isSelected = state.selectedVehicle?.id == vehicle.id;
              
              return AnimatedScale(
                scale: isSelected ? 1.0 : 0.9,
                duration: const Duration(milliseconds: 200),
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.grey[800]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Hero(
                            tag: 'vehicle_${vehicle.id}',
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                shape: BoxShape.circle,
                                image: vehicle.imagePath != null
                                    ? DecorationImage(
                                        image: FileImage(File(vehicle.imagePath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: vehicle.imagePath == null
                                  ? const Icon(Icons.directions_car, color: Colors.white, size: 30)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${vehicle.make} ${vehicle.model}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                    if (vehicle.isSold)
                      Positioned(
                        top: 5,
                        right: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SOLD',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
