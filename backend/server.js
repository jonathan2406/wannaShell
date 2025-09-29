const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');
const moment = require('moment');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware de seguridad
app.use(helmet());

// Configuración de CORS
app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000', '*'], // Permitir todos los orígenes para desarrollo
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 1000, // Límite de 1000 peticiones por ventana por IP
  message: {
    error: 'Demasiadas peticiones desde esta IP, intenta de nuevo más tarde.'
  }
});
app.use('/api/', limiter);

// Middleware para logging
app.use(morgan('combined'));

// Middleware para parsing JSON
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Base de datos en memoria (para simulación)
let sessions = [
  {
    id: uuidv4(),
    machineName: 'LAB-PC-001',
    ipAddress: '192.168.1.100',
    status: 'active',
    lastCommand: 'whoami',
    commandHistory: ['whoami', 'pwd', 'ls -la'],
    timestamp: moment().subtract(5, 'minutes').toISOString(),
    port: 4444,
    operatingSystem: 'Windows 10',
    notes: 'Máquina de pruebas principal del laboratorio'
  },
  {
    id: uuidv4(),
    machineName: 'LAB-LINUX-001',
    ipAddress: '192.168.1.101',
    status: 'inactive',
    lastCommand: 'ps aux',
    commandHistory: ['uname -a', 'ps aux', 'netstat -an'],
    timestamp: moment().subtract(15, 'minutes').toISOString(),
    port: 4445,
    operatingSystem: 'Ubuntu 20.04',
    notes: 'Servidor Linux para pruebas de penetración'
  },
  {
    id: uuidv4(),
    machineName: 'LAB-MAC-001',
    ipAddress: '192.168.1.102',
    status: 'connecting',
    lastCommand: null,
    commandHistory: [],
    timestamp: moment().subtract(2, 'minutes').toISOString(),
    port: 4446,
    operatingSystem: 'macOS Monterey',
    notes: 'MacBook para pruebas de compatibilidad multiplataforma'
  }
];

// Validación de esquemas con Joi
const Joi = require('joi');

const sessionSchema = Joi.object({
  machineName: Joi.string().alphanum().min(3).max(50).required(),
  ipAddress: Joi.string().ip({ version: ['ipv4'] }).required(),
  status: Joi.string().valid('active', 'inactive', 'connecting', 'error').default('inactive'),
  port: Joi.number().integer().min(1).max(65535).optional(),
  operatingSystem: Joi.string().max(100).optional(),
  notes: Joi.string().max(500).optional()
});

const commandSchema = Joi.object({
  command: Joi.string().min(1).max(1000).required()
});

// Middleware de validación
const validateSession = (req, res, next) => {
  const { error } = sessionSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      error: 'Datos de sesión inválidos',
      details: error.details.map(detail => detail.message)
    });
  }
  next();
};

const validateCommand = (req, res, next) => {
  const { error } = commandSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      error: 'Comando inválido',
      details: error.details.map(detail => detail.message)
    });
  }
  next();
};

// Rutas de la API

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: moment().toISOString(),
    uptime: process.uptime(),
    version: '1.0.0',
    message: 'CyberSec C&C API funcionando correctamente'
  });
});

// Obtener todas las sesiones con filtros y paginación
app.get('/api/sessions', (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      search = '', 
      status = '' 
    } = req.query;

    let filteredSessions = [...sessions];

    // Filtro por búsqueda
    if (search) {
      filteredSessions = filteredSessions.filter(session =>
        session.machineName.toLowerCase().includes(search.toLowerCase()) ||
        session.ipAddress.includes(search) ||
        (session.operatingSystem && session.operatingSystem.toLowerCase().includes(search.toLowerCase()))
      );
    }

    // Filtro por estado
    if (status) {
      filteredSessions = filteredSessions.filter(session => session.status === status);
    }

    // Ordenar por timestamp descendente (más recientes primero)
    filteredSessions.sort((a, b) => moment(b.timestamp).valueOf() - moment(a.timestamp).valueOf());

    // Paginación
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + parseInt(limit);
    const paginatedSessions = filteredSessions.slice(startIndex, endIndex);

    res.json({
      sessions: paginatedSessions,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(filteredSessions.length / limit),
        totalItems: filteredSessions.length,
        itemsPerPage: parseInt(limit),
        hasNextPage: endIndex < filteredSessions.length,
        hasPreviousPage: page > 1
      }
    });
  } catch (error) {
    console.error('Error obteniendo sesiones:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'No se pudieron obtener las sesiones'
    });
  }
});

// Obtener una sesión específica
app.get('/api/sessions/:id', (req, res) => {
  try {
    const { id } = req.params;
    const session = sessions.find(s => s.id === id);

    if (!session) {
      return res.status(404).json({
        error: 'Sesión no encontrada',
        message: `No se encontró una sesión con ID: ${id}`
      });
    }

    res.json(session);
  } catch (error) {
    console.error('Error obteniendo sesión:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'No se pudo obtener la sesión'
    });
  }
});

// Crear una nueva sesión
app.post('/api/sessions', validateSession, (req, res) => {
  try {
    // Verificar que no exista una sesión con el mismo nombre de máquina
    const existingSession = sessions.find(s => s.machineName === req.body.machineName);
    if (existingSession) {
      return res.status(409).json({
        error: 'Sesión duplicada',
        message: `Ya existe una sesión con el nombre de máquina: ${req.body.machineName}`
      });
    }

    const newSession = {
      id: uuidv4(),
      ...req.body,
      lastCommand: null,
      commandHistory: [],
      timestamp: moment().toISOString()
    };

    sessions.push(newSession);

    console.log(`Nueva sesión creada: ${newSession.machineName} (${newSession.ipAddress})`);

    res.status(201).json(newSession);
  } catch (error) {
    console.error('Error creando sesión:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'No se pudo crear la sesión'
    });
  }
});

// Actualizar una sesión existente
app.put('/api/sessions/:id', validateSession, (req, res) => {
  try {
    const { id } = req.params;
    const sessionIndex = sessions.findIndex(s => s.id === id);

    if (sessionIndex === -1) {
      return res.status(404).json({
        error: 'Sesión no encontrada',
        message: `No se encontró una sesión con ID: ${id}`
      });
    }

    // Verificar que no exista otra sesión con el mismo nombre de máquina
    const existingSession = sessions.find(s => s.machineName === req.body.machineName && s.id !== id);
    if (existingSession) {
      return res.status(409).json({
        error: 'Nombre de máquina duplicado',
        message: `Ya existe otra sesión con el nombre de máquina: ${req.body.machineName}`
      });
    }

    const currentSession = sessions[sessionIndex];
    const updatedSession = {
      ...currentSession,
      ...req.body,
      id: currentSession.id, // Mantener el ID original
      timestamp: moment().toISOString()
    };

    sessions[sessionIndex] = updatedSession;

    console.log(`Sesión actualizada: ${updatedSession.machineName} (${updatedSession.ipAddress})`);

    res.json(updatedSession);
  } catch (error) {
    console.error('Error actualizando sesión:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'No se pudo actualizar la sesión'
    });
  }
});

// Eliminar una sesión
app.delete('/api/sessions/:id', (req, res) => {
  try {
    const { id } = req.params;
    const sessionIndex = sessions.findIndex(s => s.id === id);

    if (sessionIndex === -1) {
      return res.status(404).json({
        error: 'Sesión no encontrada',
        message: `No se encontró una sesión con ID: ${id}`
      });
    }

    const deletedSession = sessions[sessionIndex];
    sessions.splice(sessionIndex, 1);

    console.log(`Sesión eliminada: ${deletedSession.machineName} (${deletedSession.ipAddress})`);

    res.json({
      message: 'Sesión eliminada exitosamente',
      deletedSession: deletedSession
    });
  } catch (error) {
    console.error('Error eliminando sesión:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'No se pudo eliminar la sesión'
    });
  }
});

// Ejecutar un comando en una sesión
app.post('/api/sessions/:id/command', validateCommand, (req, res) => {
  try {
    const { id } = req.params;
    const { command } = req.body;
    const sessionIndex = sessions.findIndex(s => s.id === id);

    if (sessionIndex === -1) {
      return res.status(404).json({
        error: 'Sesión no encontrada',
        message: `No se encontró una sesión con ID: ${id}`
      });
    }

    const session = sessions[sessionIndex];

    // Verificar que la sesión esté activa para ejecutar comandos
    if (session.status !== 'active') {
      return res.status(400).json({
        error: 'Sesión inactiva',
        message: 'La sesión debe estar activa para ejecutar comandos'
      });
    }

    // Simular la ejecución del comando
    const updatedSession = {
      ...session,
      lastCommand: command,
      commandHistory: [...session.commandHistory, command],
      timestamp: moment().toISOString()
    };

    sessions[sessionIndex] = updatedSession;

    console.log(`Comando ejecutado en ${session.machineName}: ${command}`);

    // Simular respuesta del comando (en un sistema real, esto vendría del agente)
    const commandResponse = {
      command: command,
      output: `Simulación: Comando '${command}' ejecutado en ${session.machineName}`,
      timestamp: moment().toISOString(),
      exitCode: 0
    };

    res.json({
      session: updatedSession,
      commandResponse: commandResponse
    });
  } catch (error) {
    console.error('Error ejecutando comando:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'No se pudo ejecutar el comando'
    });
  }
});

// Obtener estadísticas del sistema
app.get('/api/statistics', (req, res) => {
  try {
    const stats = {
      totalSessions: sessions.length,
      activeSessions: sessions.filter(s => s.status === 'active').length,
      inactiveSessions: sessions.filter(s => s.status === 'inactive').length,
      connectingSessions: sessions.filter(s => s.status === 'connecting').length,
      errorSessions: sessions.filter(s => s.status === 'error').length,
      totalCommands: sessions.reduce((total, session) => total + session.commandHistory.length, 0),
      lastUpdate: moment().toISOString(),
      mode: 'online'
    };

    res.json(stats);
  } catch (error) {
    console.error('Error obteniendo estadísticas:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'No se pudieron obtener las estadísticas'
    });
  }
});

// Terminar todas las sesiones activas
app.post('/api/sessions/terminate-all', (req, res) => {
  try {
    let terminatedCount = 0;

    sessions = sessions.map(session => {
      if (session.status === 'active') {
        terminatedCount++;
        return {
          ...session,
          status: 'inactive',
          timestamp: moment().toISOString()
        };
      }
      return session;
    });

    console.log(`Terminadas ${terminatedCount} sesiones activas`);

    res.json({
      message: `${terminatedCount} sesiones terminadas exitosamente`,
      terminatedCount: terminatedCount
    });
  } catch (error) {
    console.error('Error terminando sesiones:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'No se pudieron terminar las sesiones'
    });
  }
});

// Obtener historial de comandos de una sesión
app.get('/api/sessions/:id/history', (req, res) => {
  try {
    const { id } = req.params;
    const session = sessions.find(s => s.id === id);

    if (!session) {
      return res.status(404).json({
        error: 'Sesión no encontrada',
        message: `No se encontró una sesión con ID: ${id}`
      });
    }

    res.json({
      sessionId: id,
      machineName: session.machineName,
      history: session.commandHistory,
      totalCommands: session.commandHistory.length,
      lastCommand: session.lastCommand
    });
  } catch (error) {
    console.error('Error obteniendo historial:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'No se pudo obtener el historial'
    });
  }
});

// Middleware para rutas no encontradas
app.use('/api/*', (req, res) => {
  res.status(404).json({
    error: 'Ruta no encontrada',
    message: `La ruta ${req.method} ${req.originalUrl} no existe`
  });
});

// Middleware para manejo de errores globales
app.use((error, req, res, next) => {
  console.error('Error no manejado:', error);
  res.status(500).json({
    error: 'Error interno del servidor',
    message: 'Ocurrió un error inesperado'
  });
});

// Iniciar el servidor
app.listen(PORT, () => {
  console.log(`
🚀 Servidor WannaShell C&C API iniciado exitosamente
📍 URL: http://localhost:${PORT}
`);
});

// Manejo de señales para cierre limpio
process.on('SIGTERM', () => {
  console.log('🛑 Recibida señal SIGTERM, cerrando servidor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 Recibida señal SIGINT, cerrando servidor...');
  process.exit(0);
});

module.exports = app;
