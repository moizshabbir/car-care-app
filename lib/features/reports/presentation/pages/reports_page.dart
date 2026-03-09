import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection.dart';
import '../../../vehicles/presentation/bloc/vehicle_bloc.dart';
import '../../../logs/domain/repositories/log_repository.dart';
import '../../../logs/data/models/fuel_log_model.dart';
import '../../../logs/data/models/maintenance_log_model.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _logRepository = getIt<LogRepository>();

  List<FuelLogModel> _fuelLogs = [];
  List<MaintenanceLogModel> _maintenanceLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fuelLogs = await _logRepository.getRecentFuelLogs();
      final maintenanceLogs = await _logRepository.getMaintenanceLogs();

      setState(() {
        _fuelLogs = fuelLogs;
        _maintenanceLogs = maintenanceLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                _buildSummaryCards(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRefuelingTab(),
                      _buildMaintenanceTab(),
                      _buildPartsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCards() {
    final totalFuelCost = _fuelLogs.fold<double>(0, (sum, log) => sum + log.cost);
    final totalMaintenanceCost = _maintenanceLogs.fold<double>(0, (sum, log) => sum + log.cost);
    final totalRefuels = _fuelLogs.length;
    final totalServices = _maintenanceLogs.where((l) => l.category != 'Parts').length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _summaryCard(
            'Total Spent',
            '₹${NumberFormat('#,##0').format(totalFuelCost + totalMaintenanceCost)}',
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
        border: Border.all(color: color.withValues(alpha: 0.2)),
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

  Widget _buildRefuelingTab() {
    if (_fuelLogs.isEmpty) {
      return _buildEmptyState('No refueling records yet', Icons.local_gas_station);
    }

    final totalCost = _fuelLogs.fold<double>(0, (sum, l) => sum + l.cost);
    final totalLiters = _fuelLogs.fold<double>(0, (sum, l) => sum + l.liters);
    final avgCostPerFill = _fuelLogs.isNotEmpty ? totalCost / _fuelLogs.length : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.withValues(alpha: 0.15), Colors.blue.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Total', '₹${NumberFormat('#,##0').format(totalCost)}'),
              Container(width: 1, height: 40, color: Colors.grey[700]),
              _miniStat('Liters', '${totalLiters.toStringAsFixed(1)} L'),
              Container(width: 1, height: 40, color: Colors.grey[700]),
              _miniStat('Avg/Fill', '₹${avgCostPerFill.toStringAsFixed(0)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('History', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 8),
        ..._fuelLogs.map((log) => _fuelLogCard(log)),
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
              color: Colors.blue.withValues(alpha: 0.1),
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
              Text('₹${log.cost.toStringAsFixed(0)}', style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
              const SizedBox(height: 4),
              Text(DateFormat('MMM dd, yyyy').format(log.timestamp), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    final maintenanceLogs = _maintenanceLogs.where((l) => l.category != 'Parts').toList();

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
              color: Colors.orange.withValues(alpha: 0.1),
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
              Text('₹${log.cost.toStringAsFixed(0)}', style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
              const SizedBox(height: 4),
              Text(DateFormat('MMM dd, yyyy').format(log.date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartsTab() {
    final partsLogs = _maintenanceLogs.where((l) => l.category == 'Parts').toList();

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
              colors: [Colors.green.withValues(alpha: 0.15), Colors.green.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Parts Spent', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400])),
              Text('₹${NumberFormat('#,##0').format(totalPartsCost)}', style: GoogleFonts.inter(
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
                  color: Colors.green.withValues(alpha: 0.1),
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
                    Text(DateFormat('MMM dd, yyyy').format(log.date), style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ],
                ),
              ),
              Text('₹${log.cost.toStringAsFixed(0)}', style: GoogleFonts.inter(
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
