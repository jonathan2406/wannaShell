import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cc_session.dart';
import '../models/session_status.dart';
import '../providers/session_provider.dart';
import '../providers/app_provider.dart';
import '../widgets/session_status_chip.dart';
import '../widgets/loading_overlay.dart';
import '../utils/constants.dart';
import 'session_detail_screen.dart';
import 'session_form_screen.dart';

/// Pantalla principal que muestra la lista de sesiones de C&C (versión corregida)
class SessionListScreen extends StatefulWidget {
  const SessionListScreen({Key? key}) : super(key: key);

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SessionStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Cargar sesiones al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadSessions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Cargar más sesiones cuando esté cerca del final
      context.read<SessionProvider>().loadMoreSessions();
    }
  }

  void _onSearchChanged(String query) {
    // Buscar inmediatamente sin debounce para mejor UX
    context.read<SessionProvider>().searchSessions(query);
  }

  void _onStatusFilterChanged(SessionStatus? status) {
    setState(() {
      _selectedStatusFilter = status;
    });
    context.read<SessionProvider>().filterByStatus(status);
  }

  Future<void> _onRefresh() async {
    await context.read<SessionProvider>().refresh();
  }

  void _navigateToDetail(CCSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDetailScreen(sessionId: session.id),
      ),
    );
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SessionFormScreen(),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusL),
        ),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedStatus: _selectedStatusFilter,
        onStatusChanged: _onStatusFilterChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Sesiones C&C'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'terminate_all':
                  _showTerminateAllDialog();
                  break;
                case 'sync':
                  context.read<SessionProvider>().syncWithApi();
                  break;
                case 'clear_db':
                  _showClearDatabaseDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync',
                child: ListTile(
                  leading: Icon(Icons.sync),
                  title: Text('Sincronizar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'terminate_all',
                child: ListTile(
                  leading: Icon(Icons.power_off, color: Colors.red),
                  title: Text('Terminar Todas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_db',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.orange),
                  title: Text('Recrear BD'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          return LoadingOverlay(
            isLoading: sessionProvider.sessionsState.isLoading &&
                sessionProvider.sessions.isEmpty,
            message: 'Cargando sesiones...',
            child: Column(
              children: [
                // Barra de búsqueda y estadísticas
                _buildSearchAndStats(sessionProvider),

                // Lista de sesiones
                Expanded(
                  child: _buildSessionsList(sessionProvider),
                ),
              ],
            ),
          );
        },
      ),
      // Botón flotante con posición fija para evitar overflow
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton(
          onPressed: _navigateToCreate,
          tooltip: 'Nueva Sesión',
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchAndStats(SessionProvider sessionProvider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o IP...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS,
              ),
            ),
            onChanged: _onSearchChanged,
          ),

          const SizedBox(height: AppConstants.paddingM),

          // Estadísticas rápidas
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total',
                    value: sessionProvider.totalSessions.toString(),
                    icon: Icons.computer,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: _StatCard(
                    title: 'Activas',
                    value: sessionProvider.activeSessions.toString(),
                    icon: Icons.radio_button_checked,
                    color: AppConstants.activeColor,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: _StatCard(
                    title: 'Inactivas',
                    value: sessionProvider.inactiveSessions.toString(),
                    icon: Icons.radio_button_unchecked,
                    color: AppConstants.inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(SessionProvider sessionProvider) {
    if (sessionProvider.sessionsState.isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppConstants.iconXL * 2,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'Error al cargar sesiones',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              sessionProvider.errorMessage ?? 'Error desconocido',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingL),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SessionProvider>().loadSessions();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final sessions = sessionProvider.filteredSessions;

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.computer_outlined,
              size: AppConstants.iconXL * 2,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'No hay sesiones',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              'Toca el botón + para crear una nueva sesión',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          left: AppConstants.paddingM,
          right: AppConstants.paddingM,
          bottom: 80, // Espacio para el FAB
        ),
        itemCount:
            sessions.length + (sessionProvider.sessionsState.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= sessions.length) {
            // Indicador de carga al final
            return const Padding(
              padding: EdgeInsets.all(AppConstants.paddingM),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final session = sessions[index];
          return _SessionCard(
            session: session,
            onTap: () => _navigateToDetail(session),
            onDelete: () => _showDeleteDialog(session),
          );
        },
      ),
    );
  }

  void _showTerminateAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminar Todas las Sesiones'),
        content: const Text(
            '¿Estás seguro de que quieres terminar todas las sesiones activas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SessionProvider>().terminateAllSessions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Terminar Todas'),
          ),
        ],
      ),
    );
  }

  void _showClearDatabaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recrear Base de Datos'),
        content: const Text(
            'Esto eliminará todas las sesiones y recreará la base de datos con datos de ejemplo. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SessionProvider>().recreateDatabase();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Recrear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(CCSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Sesión'),
        content: Text(
            '¿Estás seguro de que quieres eliminar la sesión "${session.machineName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SessionProvider>().deleteSession(session.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar estadísticas rápidas
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: AppConstants.iconM,
            ),
            const SizedBox(height: AppConstants.paddingXS),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar una sesión individual
class _SessionCard extends StatelessWidget {
  final CCSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(session.status),
          child: Icon(
            _getStatusIcon(session.status),
            color: Colors.white,
            size: AppConstants.iconS,
          ),
        ),
        title: Text(
          session.machineName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.ipAddress),
            if (session.lastCommand != null)
              Text(
                'Último: ${session.lastCommand}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SessionStatusChip(status: session.status),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Eliminar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return AppConstants.activeColor;
      case SessionStatus.inactive:
        return AppConstants.inactiveColor;
      case SessionStatus.connecting:
        return AppConstants.connectingColor;
      case SessionStatus.error:
        return AppConstants.errorSessionColor;
    }
  }

  IconData _getStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return Icons.radio_button_checked;
      case SessionStatus.inactive:
        return Icons.radio_button_unchecked;
      case SessionStatus.connecting:
        return Icons.sync;
      case SessionStatus.error:
        return Icons.error;
    }
  }
}

/// Bottom sheet para filtros
class _FilterBottomSheet extends StatelessWidget {
  final SessionStatus? selectedStatus;
  final Function(SessionStatus?) onStatusChanged;

  const _FilterBottomSheet({
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrar por Estado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingL),

          // Opción "Todos"
          RadioListTile<SessionStatus?>(
            title: const Text('Todos'),
            value: null,
            groupValue: selectedStatus,
            onChanged: (value) {
              onStatusChanged(value);
              Navigator.pop(context);
            },
          ),

          // Opciones de estado
          ...SessionStatus.values.map((status) {
            return RadioListTile<SessionStatus?>(
              title: Row(
                children: [
                  SessionStatusChip(status: status),
                  const SizedBox(width: AppConstants.paddingS),
                  Text(_getStatusName(status)),
                ],
              ),
              value: status,
              groupValue: selectedStatus,
              onChanged: (value) {
                onStatusChanged(value);
                Navigator.pop(context);
              },
            );
          }).toList(),

          const SizedBox(height: AppConstants.paddingL),

          // Botón cerrar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusName(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return 'activo';
      case SessionStatus.inactive:
        return 'inactivo';
      case SessionStatus.connecting:
        return 'conectando';
      case SessionStatus.error:
        return 'error';
    }
  }
}
