import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/cc_session.dart';
import '../models/session_status.dart';
import '../providers/session_provider.dart';
import '../widgets/session_status_chip.dart';
import '../widgets/loading_overlay.dart';
import '../utils/constants.dart';
import 'session_form_screen.dart';

/// Pantalla de detalle de una sesión C&C (versión simplificada)
class SessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSession();
    });
  }

  @override
  void dispose() {
    _commandController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  /// Cargar datos de la sesión
  void _loadSession() {
    context.read<SessionProvider>().selectSession(widget.sessionId);
  }

  /// Ejecutar comando (simplificado)
  Future<void> _executeCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    final sessionProvider = context.read<SessionProvider>();
    await sessionProvider.executeCommand(widget.sessionId, command);

    // Limpiar campo de comando
    _commandController.clear();

    // Mostrar feedback
    HapticFeedback.lightImpact();

    // Recargar la sesión para mostrar el comando actualizado
    _loadSession();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        final session = sessionProvider.selectedSession;
        final isLoading = sessionProvider.selectedSessionState.isLoading;
        final isError = sessionProvider.selectedSessionState.isError;

        return Scaffold(
          appBar: AppBar(
            title: Text(session?.machineName ?? 'Cargando...'),
            actions: [
              if (session != null) ...[
                // Botón de editar
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editSession(session),
                  tooltip: 'Editar sesión',
                ),
                // Botón de eliminar
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteSession(session.id),
                  tooltip: 'Eliminar sesión',
                ),
                // Botón de actualizar
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSession,
                  tooltip: 'Actualizar',
                ),
              ],
            ],
          ),
          body: LoadingOverlay(
            isLoading: isLoading,
            child: isError
                ? _buildErrorState(sessionProvider.errorMessage)
                : session == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSessionDetail(session, sessionProvider),
          ),
        );
      },
    );
  }

  /// Construir estado de error
  Widget _buildErrorState(String? errorMessage) {
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
            'Error al cargar la sesión',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppConstants.paddingS),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppConstants.paddingL),
          ElevatedButton.icon(
            onPressed: _loadSession,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Construir detalle de la sesión
  Widget _buildSessionDetail(
      CCSession session, SessionProvider sessionProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Información de la sesión
          _buildSessionInfo(session),

          const SizedBox(height: AppConstants.paddingM),

          // Sección de comandos
          _buildCommandSection(session, sessionProvider),

          const SizedBox(height: AppConstants.paddingM),

          // Historial de comandos
          _buildCommandHistory(session),

          // Espacio adicional al final para evitar overflow
          const SizedBox(height: AppConstants.paddingL),
        ],
      ),
    );
  }

  /// Construir información de la sesión
  Widget _buildSessionInfo(CCSession session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado con estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.machineName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SessionStatusChip(status: session.status),
              ],
            ),

            const SizedBox(height: AppConstants.paddingM),

            // Información detallada en grid compacto
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompactInfoRow(
                          Icons.computer, 'IP', session.ipAddress),
                      if (session.operatingSystem != null)
                        _buildCompactInfoRow(
                            Icons.settings, 'SO', session.operatingSystem!),
                      if (session.lastCommand != null)
                        _buildCompactInfoRow(
                            Icons.terminal, 'Último', session.lastCommand!),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (session.port != null)
                        _buildCompactInfoRow(
                            Icons.router, 'Puerto', '${session.port}'),
                      _buildCompactInfoRow(Icons.access_time, 'Actividad',
                          _formatDateTime(session.timestamp)),
                      if (session.notes != null && session.notes!.isNotEmpty)
                        _buildCompactInfoRow(
                            Icons.note, 'Notas', session.notes!),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construir fila de información compacta
  Widget _buildCompactInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: AppConstants.paddingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construir sección de comandos
  Widget _buildCommandSection(
      CCSession session, SessionProvider sessionProvider) {
    final canExecute = session.status == SessionStatus.active;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ejecutar Comando',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppConstants.paddingM),

            // Campo de entrada de comando
            TextField(
              controller: _commandController,
              enabled: canExecute,
              decoration: InputDecoration(
                hintText: 'Ingresa un comando...',
                prefixIcon: const Icon(Icons.terminal),
                suffixIcon: IconButton(
                  icon: sessionProvider.executeCommandState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: canExecute &&
                          !sessionProvider.executeCommandState.isLoading
                      ? _executeCommand
                      : null,
                ),
              ),
              onSubmitted: canExecute ? (_) => _executeCommand() : null,
            ),

            // Mensaje de estado
            if (!canExecute) ...[
              const SizedBox(height: AppConstants.paddingS),
              Text(
                'La sesión debe estar activa para ejecutar comandos',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],

            // Comandos sugeridos
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'Comandos sugeridos:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Wrap(
              spacing: AppConstants.paddingS,
              runSpacing: AppConstants.paddingS,
              children: _getSuggestedCommands(session).map((command) {
                return ActionChip(
                  label: Text(
                    command,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: canExecute
                      ? () {
                          _commandController.text = command;
                        }
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir historial de comandos
  Widget _buildCommandHistory(CCSession session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Historial de Comandos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            if (session.commandHistory.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppConstants.paddingL),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: AppConstants.iconL,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      Text(
                        'No hay comandos en el historial',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: session.commandHistory.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final command = session.commandHistory[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingS,
                        vertical: 0,
                      ),
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        command,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => _copyToClipboard(command),
                        tooltip: 'Copiar comando',
                      ),
                      onTap: () {
                        _commandController.text = command;
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Obtener comandos sugeridos según el sistema operativo
  List<String> _getSuggestedCommands(CCSession session) {
    final isWindows =
        session.operatingSystem?.toLowerCase().contains('windows') ?? false;

    if (isWindows) {
      return ['whoami', 'dir', 'ipconfig', 'tasklist', 'systeminfo'];
    } else {
      return ['whoami', 'pwd', 'ls -la', 'ps aux', 'ifconfig', 'uname -a'];
    }
  }

  /// Copiar texto al portapapeles
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copiado: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Formatear fecha y hora
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Editar sesión
  void _editSession(CCSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionFormScreen(session: session),
      ),
    );
  }

  /// Eliminar sesión
  void _deleteSession(String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Sesión'),
        content:
            const Text('¿Estás seguro de que quieres eliminar esta sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<SessionProvider>()
                  .deleteSession(sessionId);
              if (success && mounted) {
                Navigator.pop(context);
              }
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
