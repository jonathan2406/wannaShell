import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/session_provider.dart';
import 'screens/session_list_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar providers
  final appProvider = AppProvider();
  final sessionProvider = SessionProvider();
  
  await appProvider.initialize();
  await sessionProvider.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: sessionProvider),
      ],
      child: const CyberSecCCApp(),
    ),
  );
}

/// Aplicación principal de Control de Comando y Control para Ciberseguridad
class CyberSecCCApp extends StatelessWidget {
  const CyberSecCCApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          title: 'CyberSec C&C Client',
          debugShowCheckedModeBanner: false,
          
          // Configuración de tema
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appProvider.themeMode,
          
          // Pantalla inicial
          home: const MainScreen(),
          
          // Configuración de navegación
          builder: (context, child) {
            return _AppWrapper(child: child!);
          },
        );
      },
    );
  }
}

/// Wrapper principal de la aplicación con manejo de mensajes globales
class _AppWrapper extends StatelessWidget {
  final Widget child;

  const _AppWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Mostrar mensajes de error o éxito globales
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (appProvider.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(appProvider.errorMessage!),
                backgroundColor: AppConstants.errorColor,
                action: SnackBarAction(
                  label: 'Cerrar',
                  textColor: Colors.white,
                  onPressed: () {
                    appProvider.clearMessages();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          } else if (appProvider.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(appProvider.successMessage!),
                backgroundColor: AppConstants.successColor,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });

        return this.child;
      },
    );
  }
}

/// Pantalla principal con navegación por pestañas
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const SessionListScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          context.read<AppProvider>().setSelectedNavIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.computer),
            selectedIcon: Icon(Icons.computer),
            label: 'Sesiones',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}

/// Pantalla de estadísticas
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SessionProvider>().loadStatistics();
            },
            tooltip: 'Actualizar estadísticas',
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          if (sessionProvider.statisticsState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (sessionProvider.statisticsState.isError) {
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
                    'Error al cargar estadísticas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                  ElevatedButton.icon(
                    onPressed: () {
                      sessionProvider.loadStatistics();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final stats = sessionProvider.statistics;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen general
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen General',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        _StatisticItem(
                          label: 'Total de Sesiones',
                          value: '${stats['totalSessions'] ?? 0}',
                          icon: Icons.computer,
                          color: Colors.blue,
                        ),
                        _StatisticItem(
                          label: 'Sesiones Activas',
                          value: '${stats['activeSessions'] ?? 0}',
                          icon: Icons.radio_button_checked,
                          color: AppConstants.activeColor,
                        ),
                        _StatisticItem(
                          label: 'Sesiones Inactivas',
                          value: '${stats['inactiveSessions'] ?? 0}',
                          icon: Icons.radio_button_unchecked,
                          color: AppConstants.inactiveColor,
                        ),
                        _StatisticItem(
                          label: 'Conectando',
                          value: '${stats['connectingSessions'] ?? 0}',
                          icon: Icons.sync,
                          color: AppConstants.connectingColor,
                        ),
                        _StatisticItem(
                          label: 'Con Error',
                          value: '${stats['errorSessions'] ?? 0}',
                          icon: Icons.error,
                          color: AppConstants.errorSessionColor,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingM),
                
                // Información del sistema
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información del Sistema',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        _StatisticItem(
                          label: 'Modo de Operación',
                          value: sessionProvider.isOfflineMode ? 'Offline' : 'Online',
                          icon: sessionProvider.isOfflineMode ? Icons.wifi_off : Icons.wifi,
                          color: sessionProvider.isOfflineMode ? Colors.orange : Colors.green,
                        ),
                        if (stats['lastUpdate'] != null)
                          _StatisticItem(
                            label: 'Última Actualización',
                            value: _formatDate(stats['lastUpdate']),
                            icon: Icons.access_time,
                            color: Colors.grey,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

/// Widget para mostrar elementos estadísticos
class _StatisticItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatisticItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: AppConstants.iconM,
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pantalla de configuración
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: Consumer2<AppProvider, SessionProvider>(
        builder: (context, appProvider, sessionProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            children: [
              // Configuración de tema
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apariencia',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      SwitchListTile(
                        title: const Text('Modo Oscuro'),
                        subtitle: const Text('Cambiar entre tema claro y oscuro'),
                        value: appProvider.isDarkMode,
                        onChanged: (value) {
                          appProvider.toggleDarkMode();
                        },
                        secondary: const Icon(Icons.dark_mode),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingM),
              
              // Configuración de conexión
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conexión',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      SwitchListTile(
                        title: const Text('Modo Offline'),
                        subtitle: const Text('Usar solo base de datos local'),
                        value: sessionProvider.isOfflineMode,
                        onChanged: (value) {
                          sessionProvider.setOfflineMode(value);
                          appProvider.setOfflineMode(value);
                        },
                        secondary: const Icon(Icons.wifi_off),
                      ),
                      ListTile(
                        title: const Text('URL de la API'),
                        subtitle: Text(appProvider.apiBaseUrl),
                        leading: const Icon(Icons.link),
                        trailing: const Icon(Icons.edit),
                        onTap: () {
                          _showApiUrlDialog(context, appProvider);
                        },
                      ),
                      ListTile(
                        title: const Text('Sincronizar con API'),
                        subtitle: const Text('Forzar sincronización manual'),
                        leading: const Icon(Icons.sync),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          sessionProvider.syncWithApi();
                          appProvider.showSuccess('Sincronización iniciada');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingM),
              
              // Información de la aplicación
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      const ListTile(
                        title: Text('Versión'),
                        subtitle: Text('1.0.0'),
                        leading: Icon(Icons.info),
                      ),
                      const ListTile(
                        title: Text('Propósito Educativo'),
                        subtitle: Text('Esta aplicación es solo para fines educativos en laboratorios de ciberseguridad controlados'),
                        leading: Icon(Icons.school),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showApiUrlDialog(BuildContext context, AppProvider appProvider) {
    final controller = TextEditingController(text: appProvider.apiBaseUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar URL de API'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL de la API',
            hintText: 'http://localhost:3000/api',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                appProvider.setApiBaseUrl(url);
                Navigator.pop(context);
                appProvider.showSuccess('URL de API actualizada');
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
