import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../injection.dart';
import '../../../logs/data/models/fuel_log_model.dart';
import '../../../logs/data/models/maintenance_log_model.dart';
import 'package:carlog/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:carlog/features/reports/presentation/bloc/reports_event.dart';
import 'package:carlog/features/reports/presentation/bloc/reports_state.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ReportsBloc>()..add(LoadReports()),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Reports', style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          )),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[500],
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'Refueling'),
              Tab(text: 'Maintenance'),
              Tab(text: 'Parts & Tools'),
            ],
          ),
        ),
        body: BlocBuilder<ReportsBloc, ReportsState>(
          builder: (context, state) {
            if (state.status == ReportsStatus.loading || state.status == ReportsStatus.initial) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }

            if (state.status == ReportsStatus.error) {
              return Center(child: Text('Error: ${state.errorMessage}', style: const TextStyle(color: Colors.red)));
            }

            return Column(
              children: [
                _buildSummaryCards(state),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRefuelingTab(state),
                      _buildMaintenanceTab(state),
                      _buildPartsTab(state),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ReportsState state) {
    final totalFuelCost = state.fuelLogs.fold<double>(0, (sum, log) => sum + log.cost);
    final totalMaintenanceCost = state.maintenanceLogs.fold<double>(0, (sum, log) => sum + log.cost);
    final totalRefuels = state.fuelLogs.length;
    final totalServices = state.maintenanceLogs.where((l) => l.category != 'Parts').length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _summaryCard(
            'Total Spent',
            '${getIt<SettingsService>().currency}${NumberFormat('#,##0').format(totalFuelCost + totalMaintenanceCost)}',
            Icons.account_balance_wallet,
            AppTheme.primary,
          )),
          const SizedBox(width: 8),
          Expanded(child: _summaryCard(
            'Refuels',
            '$totalRefuels',
            Icons.local_gas_station,
            Colors.blue,
          )),
          const SizedBox(width: 8),
          Expanded(child: _summaryCard(
            'Services',
            '$totalServices',
            Icons.build,
            Colors.orange,
          )),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          )),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey[400],
          )),
        ],
      ),
    );
  }

  Widget _buildRefuelingTab(ReportsState state) {
    if (state.fuelLogs.isEmpty) {
      return _buildEmptyState('No refueling records yet', Icons.local_gas_station);
    }

    final totalCost = state.fuelLogs.fold<double>(0, (sum, l) => sum + l.cost);
    final totalLiters = state.fuelLogs.fold<double>(0, (sum, l) => sum + l.liters);
    final avgCostPerFill = state.fuelLogs.isNotEmpty ? totalCost / state.fuelLogs.length : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.withOpacity(0.15), Colors.blue.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
               _miniStat('Total', '${getIt<SettingsService>().currency}${NumberFormat('#,##0').format(totalCost)}'),
              Container(width: 1, height: 40, color: Colors.grey[700]),
              _miniStat('Liters', '${totalLiters.toStringAsFixed(1)} L'),
              Container(width: 1, height: 40, color: Colors.grey[700]),
               _miniStat('Avg/Fill', '${getIt<SettingsService>().currency}${avgCostPerFill.toStringAsFixed(0)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('History', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 8),
        ...state.fuelLogs.map((log) => _fuelLogCard(log)),
      ],
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }

  Widget _fuelLogCard(FuelLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_gas_station, color: Colors.blue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.stationName ?? 'Fuel Fill-up',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.liters.toStringAsFixed(1)} L • ${log.odometer} km',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${getIt<SettingsService>().currency}${log.cost.toStringAsFixed(0)}', style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
              const SizedBox(height: 4),
               Text(DateFormat(getIt<SettingsService>().dateFormat).format(log.timestamp), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab(ReportsState state) {
    final maintenanceLogs = state.maintenanceLogs.where((l) => l.category != 'Parts').toList();

    if (maintenanceLogs.isEmpty) {
      return _buildEmptyState('No maintenance records yet', Icons.build);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Maintenance Timeline', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        ...maintenanceLogs.map((log) => _maintenanceCard(log)),
      ],
    );
  }

  Widget _maintenanceCard(MaintenanceLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.build, color: Colors.orange, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                if (log.note != null && log.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(log.note!, style: TextStyle(color: Colors.grey[400], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${getIt<SettingsService>().currency}${log.cost.toStringAsFixed(0)}', style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
              const SizedBox(height: 4),
               Text(DateFormat(getIt<SettingsService>().dateFormat).format(log.date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartsTab(ReportsState state) {
    final partsLogs = state.maintenanceLogs.where((l) => l.category == 'Parts').toList();

    if (partsLogs.isEmpty) {
      return _buildEmptyState('No parts purchased yet', Icons.shopping_cart);
    }

    final totalPartsCost = partsLogs.fold<double>(0, (sum, l) => sum + l.cost);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text('Total Parts Spent', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400])),
              Text('${getIt<SettingsService>().currency}${NumberFormat('#,##0').format(totalPartsCost)}', style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white,
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Purchase History', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        ...partsLogs.map((log) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_cart, color: Colors.green, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.note ?? 'Car Part', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                   const SizedBox(height: 4),
                     Text(DateFormat(getIt<SettingsService>().dateFormat).format(log.date), style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ],
                ),
              ),
              Text('${getIt<SettingsService>().currency}${log.cost.toStringAsFixed(0)}', style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[700], size: 64),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}
