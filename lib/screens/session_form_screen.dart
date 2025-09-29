import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cc_session.dart';
import '../models/session_status.dart';
import '../providers/session_provider.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/session_status_chip.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

/// Pantalla de formulario para crear o editar sesiones de C&C
class SessionFormScreen extends StatefulWidget {
  final CCSession? session;

  const SessionFormScreen({
    Key? key,
    this.session,
  }) : super(key: key);

  bool get isEditing => session != null;

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  late final TextEditingController _machineNameController;
  late final TextEditingController _ipAddressController;
  late final TextEditingController _portController;
  late final TextEditingController _notesController;
  
  // Variables de estado
  SessionStatus _selectedStatus = SessionStatus.inactive;
  String? _selectedOperatingSystem;
  
  // Lista de sistemas operativos
  final List<String> _operatingSystems = [
    ...AppConstants.commonOS,
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores
    _machineNameController = TextEditingController();
    _ipAddressController = TextEditingController();
    _portController = TextEditingController();
    _notesController = TextEditingController();
    
    // Si estamos editando, cargar los datos existentes
    if (widget.isEditing) {
      _loadSessionData();
    }
  }

  void _loadSessionData() {
    final session = widget.session!;
    _machineNameController.text = session.machineName;
    _ipAddressController.text = session.ipAddress;
    _portController.text = session.port?.toString() ?? '';
    _notesController.text = session.notes ?? '';
    _selectedStatus = session.status;
    _selectedOperatingSystem = session.operatingSystem;
  }

  @override
  void dispose() {
    _machineNameController.dispose();
    _ipAddressController.dispose();
    _portController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sessionProvider = context.read<SessionProvider>();
    
    final sessionData = CCSession(
      id: widget.session?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      machineName: _machineNameController.text.trim(),
      ipAddress: _ipAddressController.text.trim(),
      status: _selectedStatus,
      port: _portController.text.trim().isNotEmpty 
          ? int.parse(_portController.text.trim()) 
          : null,
      operatingSystem: _selectedOperatingSystem,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      commandHistory: widget.session?.commandHistory ?? [],
      lastCommand: widget.session?.lastCommand,
      timestamp: widget.session?.timestamp ?? DateTime.now(),
    );

    if (widget.isEditing) {
      await sessionProvider.updateSession(sessionData);
      
      if (sessionProvider.updateState.isSuccess) {
        if (mounted) {
          Navigator.pop(context, sessionData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión actualizada exitosamente'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } else if (sessionProvider.updateState.isError) {
        _showErrorSnackBar(sessionProvider.updateState.error!);
      }
    } else {
      await sessionProvider.createSession(sessionData);
      
      if (sessionProvider.createState.isSuccess) {
        if (mounted) {
          Navigator.pop(context, sessionProvider.createState.data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión creada exitosamente'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } else if (sessionProvider.createState.isError) {
        _showErrorSnackBar(sessionProvider.createState.error!);
      }
    }
  }

  void _showErrorSnackBar(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: AppConstants.errorColor,
          action: SnackBarAction(
            label: 'Cerrar',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showDiscardChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar Cambios'),
        content: const Text(
          '¿Estás seguro de que deseas descartar los cambios realizados?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver atrás
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }

  bool get _hasChanges {
    if (!widget.isEditing) {
      return _machineNameController.text.isNotEmpty ||
             _ipAddressController.text.isNotEmpty ||
             _portController.text.isNotEmpty ||
             _notesController.text.isNotEmpty ||
             _selectedOperatingSystem != null;
    }

    final session = widget.session!;
    return _machineNameController.text.trim() != session.machineName ||
           _ipAddressController.text.trim() != session.ipAddress ||
           (_portController.text.trim().isNotEmpty 
               ? int.tryParse(_portController.text.trim()) 
               : null) != session.port ||
           _notesController.text.trim() != (session.notes ?? '') ||
           _selectedStatus != session.status ||
           _selectedOperatingSystem != session.operatingSystem;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          _showDiscardChangesDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Editar Sesión' : 'Nueva Sesión'),
          actions: [
            Consumer<SessionProvider>(
              builder: (context, sessionProvider, child) {
                final isLoading = widget.isEditing 
                    ? sessionProvider.updateState.isLoading
                    : sessionProvider.createState.isLoading;

                return TextButton.icon(
                  onPressed: isLoading ? null : _saveSession,
                  icon: isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(widget.isEditing ? 'Actualizar' : 'Crear'),
                );
              },
            ),
          ],
        ),
        body: Consumer<SessionProvider>(
          builder: (context, sessionProvider, child) {
            final isLoading = widget.isEditing 
                ? sessionProvider.updateState.isLoading
                : sessionProvider.createState.isLoading;

            return LoadingOverlay(
              isLoading: isLoading,
              message: widget.isEditing 
                  ? 'Actualizando sesión...' 
                  : 'Creando sesión...',
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: AppConstants.paddingL),
                      _buildStatusSection(),
                      const SizedBox(height: AppConstants.paddingL),
                      _buildAdvancedSection(),
                      const SizedBox(height: AppConstants.paddingL),
                      _buildNotesSection(),
                      const SizedBox(height: AppConstants.paddingXL),
                      _buildActionButtons(isLoading),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.computer,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  'Información Básica',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            TextFormField(
              controller: _machineNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Máquina',
                hintText: 'Ej: LAB-PC-001',
                prefixIcon: Icon(Icons.desktop_windows),
                helperText: 'Identificador único para la máquina objetivo',
              ),
              validator: Validators.machineName,
              textCapitalization: TextCapitalization.characters,
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            TextFormField(
              controller: _ipAddressController,
              decoration: const InputDecoration(
                labelText: 'Dirección IP',
                hintText: 'Ej: 192.168.1.100',
                prefixIcon: Icon(Icons.language),
                helperText: 'Dirección IP de la máquina objetivo',
              ),
              validator: Validators.ipAddress,
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Puerto (Opcional)',
                hintText: 'Ej: 4444',
                prefixIcon: Icon(Icons.router),
                helperText: 'Puerto de conexión para la sesión',
              ),
              validator: Validators.port,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.radio_button_checked,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  'Estado de la Sesión',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            Text(
              'Selecciona el estado actual de la sesión:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            Wrap(
              spacing: AppConstants.paddingS,
              runSpacing: AppConstants.paddingS,
              children: SessionStatus.values.map((status) {
                final isSelected = _selectedStatus == status;
                
                return FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                  avatar: isSelected ? null : Icon(
                    _getStatusIcon(status),
                    size: AppConstants.iconS,
                  ),
                  label: Text(status.displayName),
                );
              }).toList(),
            ),
            
            const SizedBox(height: AppConstants.paddingS),
            
            Row(
              children: [
                const Text('Vista previa: '),
                SessionStatusChip(status: _selectedStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  'Configuración Avanzada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            DropdownButtonFormField<String>(
              value: _selectedOperatingSystem,
              decoration: const InputDecoration(
                labelText: 'Sistema Operativo (Opcional)',
                prefixIcon: Icon(Icons.desktop_windows),
                helperText: 'Sistema operativo de la máquina objetivo',
              ),
              items: _operatingSystems.map((os) {
                return DropdownMenuItem(
                  value: os,
                  child: Text(os),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedOperatingSystem = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  'Notas Adicionales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (Opcional)',
                hintText: 'Información adicional sobre la sesión...',
                alignLabelWithHint: true,
                helperText: 'Máximo 500 caracteres',
              ),
              validator: Validators.notes,
              maxLines: 4,
              maxLength: AppConstants.maxNotesLength,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : () {
              if (_hasChanges) {
                _showDiscardChangesDialog();
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _saveSession,
            icon: isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(widget.isEditing ? 'Actualizar' : 'Crear Sesión'),
          ),
        ),
      ],
    );
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
