# 👹 WannaShell C&C Client - Sistema de Comando y Control Educativo

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)
![Express](https://img.shields.io/badge/Express.js-000000?style=for-the-badge&logo=express&logoColor=white)


**Desarrollado para el Semillero de Ciberseguridad DarkWall - Universidad de Medellín (UdeM)**

*Una aplicación móvil educativa que simula un sistema de Comando y Control (C&C) para el aprendizaje de ciberseguridad en entornos controlados.*

</div>

---

## 🚨 **ADVERTENCIA IMPORTANTE**

> **⚠️ SOLO PARA FINES EDUCATIVOS ⚠️**
> 
> Esta aplicación ha sido desarrollada **EXCLUSIVAMENTE** para:
> - 🎓 **Laboratorios universitarios** de ciberseguridad
> - 🔬 **Entornos de entrenamiento** controlados
> - 📚 **Investigación académica** autorizada
> - 🎯 **Aprendizaje sobre seguridad** informática

---

## 📖 **¿Qué es un Sistema de Comando y Control (C&C)?**

Un **sistema de Comando y Control (C&C)** es una infraestructura utilizada para mantener comunicación con dispositivos comprometidos en una red. En el contexto de la ciberseguridad:

### 🔍 **Definición Técnica:**
Un C&C es el **centro de operaciones** desde donde los atacantes:
- 📡 **Controlan remotamente** dispositivos infectados
- 💻 **Ejecutan comandos** en máquinas comprometidas  
- 📊 **Recopilan información** de los sistemas objetivo
- 🔄 **Coordinan actividades** maliciosas distribuidas

### 🕸️ **Relación con Botnets:**
Los sistemas C&C son el **cerebro** de las **botnets**:

#### **¿Qué es una Botnet?**
Una **botnet** es una red de dispositivos infectados (llamados "bots" o "zombies") que son controlados remotamente sin el conocimiento de sus propietarios.

#### **Arquitectura Típica de Botnet:**
```
[Atacante] ←→ [Servidor C&C] ←→ [Bot 1] [Bot 2] [Bot 3] ... [Bot N]
```

#### **Funcionalidades Maliciosas:**
- 🎯 **Ataques DDoS**: Coordinar ataques distribuidos
- 💰 **Criptominería**: Minar criptomonedas usando recursos ajenos
- 🕵️ **Espionaje**: Robar información personal y corporativa
- 📧 **Spam**: Envío masivo de correos no deseados
- 🔒 **Ransomware**: Distribución de malware de cifrado

---

## 🎓 **Contexto Educativo - Semillero DarkWall UdeM**

### 🏫 **Universidad de Medellín (UdeM)**
Este proyecto forma parte de las actividades del **Semillero de Investigación en Ciberseguridad DarkWall** de la Universidad de Medellín, enfocado en:

- 🔬 **Investigación aplicada** en ciberseguridad
- 🛡️ **Desarrollo de herramientas** educativas
- 👥 **Formación de especialistas** en seguridad informática
- 🎯 **Simulación de amenazas** en entornos controlados

### 📚 **Objetivos Pedagógicos:**

#### **1. Comprensión de Amenazas:**
- Entender cómo funcionan los sistemas C&C reales
- Analizar patrones de comunicación maliciosa
- Identificar indicadores de compromiso (IoC)

#### **2. Desarrollo de Defensas:**
- Diseñar sistemas de detección de C&C
- Implementar contramedidas efectivas
- Crear herramientas de análisis forense

#### **3. Habilidades Técnicas:**
- Programación de aplicaciones móviles seguras
- Desarrollo de APIs REST robustas
- Manejo de bases de datos y sincronización

---

## 🚀 **Características Principales**

### 📱 **Aplicación Móvil Flutter**
- **🎨 Interfaz Moderna**: Material Design 3 con tema claro/oscuro
- **📊 Dashboard Completo**: Estadísticas en tiempo real de sesiones
- **🔍 Búsqueda Avanzada**: Filtros por IP, nombre de máquina y estado
- **📱 Responsive Design**: Adaptable a tablets y diferentes orientaciones

### 🌐 **API REST Robusta**
- **⚡ Node.js/Express**: Backend escalable y eficiente
- **🔒 Seguridad Integrada**: Rate limiting, validación con Joi, headers seguros
- **📊 8+ Endpoints**: CRUD completo + funcionalidades especializadas
- **📝 Logging Completo**: Monitoreo de todas las actividades

### 💾 **Gestión de Datos Híbrida**
- **🌐 Online First**: API como fuente principal de verdad
- **💾 Cache Local**: SQLite para funcionamiento offline
- **🔄 Sincronización Bidireccional**: Inteligente y automática
- **📊 Persistencia Garantizada**: No pérdida de datos

### 🎯 **Funcionalidades de Simulación**

#### **Gestión de Sesiones:**
- ✅ **Crear/Editar/Eliminar** máquinas objetivo
- ✅ **Estados Realistas**: Activo, Inactivo, Conectando, Error
- ✅ **Información Detallada**: IP, puerto, SO, notas
- ✅ **Historial Completo** de actividades

#### **Ejecución de Comandos:**
- ✅ **Comandos Simulados**: whoami, ls, ps, netstat, etc.
- ✅ **Adaptación por SO**: Comandos diferentes para Windows/Linux/Mac
- ✅ **Historial Persistente**: Seguimiento de todos los comandos
- ✅ **Validación de Estados**: Solo sesiones activas pueden ejecutar comandos

#### **Monitoreo y Estadísticas:**
- ✅ **Dashboard en Tiempo Real**: Contadores de sesiones por estado
- ✅ **Métricas Avanzadas**: Total de comandos, última actividad
- ✅ **Visualización Clara**: Chips de estado con códigos de color

---

```

### 🔄 **Flujo de Datos**

#### **Modo Online (Preferido):**
```
Usuario → App → API → Validación → Base de Datos → Respuesta → Cache Local → UI
```

#### **Modo Offline (Respaldo):**
```
Usuario → App → Cache Local → SQLite → Respuesta → UI → [Sync Pendiente]
```

## 🚀 **Instalación y Configuración**

### 📋 **Prerrequisitos**

#### **Para el Frontend:**
- 📱 **Flutter SDK**: 3.10.0 o superior
- 🎯 **Dart SDK**: 3.0.0 o superior  
- 🔧 **Android Studio** o **VS Code** con extensiones Flutter
- 📱 **Dispositivo/Emulador** Android/iOS

#### **Para el Backend:**
- 🟢 **Node.js**: 16.0.0 o superior
- 📦 **npm**: Incluido con Node.js

### ⚡ **Instalación Rápida**

#### **1. Clonar el Repositorio**
```bash
git clone https://github.com/tu-usuario/cybersec-cc-client.git
cd cybersec-cc-client
```

#### **2. Configurar Backend**
```bash
cd backend
npm install
npm run dev
```

#### **3. Configurar Frontend**
```bash
cd ..
flutter pub get
flutter pub run build_runner build
```

#### **4. Ejecutar la Aplicación**
```bash
flutter run
```






---

## 🔌 **API Documentation**

### 📡 **Endpoints Principales**

#### **🔍 Health Check**
```http
GET /api/health
```
**Respuesta:**
```json
{
  "status": "OK",
  "timestamp": "2025-09-29T10:30:00.000Z",
  "uptime": 3600,
  "version": "1.0.0"
}
```

#### **📋 Obtener Sesiones**
```http
GET /api/sessions?page=1&limit=20&search=LAB&status=active
```
**Respuesta:**
```json
{
  "sessions": [...],
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "totalItems": 100
  }
}
```

#### **➕ Crear Sesión**
```http
POST /api/sessions
Content-Type: application/json

{
  "machineName": "LABPC001",
  "ipAddress": "192.168.1.100",
  "status": "active",
  "port": 4444,
  "operatingSystem": "Windows 10",
  "notes": "Máquina de pruebas"
}
```

#### **⌨️ Ejecutar Comando**
```http
POST /api/sessions/{id}/command
Content-Type: application/json

{
  "command": "whoami"
}
```
**Respuesta:**
```json
{
  "session": { ... },
  "commandResponse": {
    "command": "whoami",
    "output": "LAB-PC-001\\administrator",
    "timestamp": "2025-09-29T10:30:00.000Z",
    "exitCode": 0
  }
}
```

---

## 🧪 **Testing y Validación**

### ✅ **Casos de Prueba Implementados**

#### **1. Validación de Formularios**
- ✅ Campos obligatorios (nombre de máquina, IP)
- ✅ Formato de IP válido (IPv4)
- ✅ Rango de puertos (1-65535)
- ✅ Nombres únicos de máquina

#### **2. Estados de Sesión**
- ✅ Transiciones válidas de estado
- ✅ Comandos solo en sesiones activas
- ✅ Actualización automática de timestamps

#### **3. Sincronización**
- ✅ Modo online/offline
- ✅ Sincronización bidireccional
- ✅ Resolución de conflictos

#### **4. Manejo de Errores**
- ✅ Conexión API perdida
- ✅ Datos inválidos del servidor
- ✅ Operaciones concurrentes

### 🔍 **Herramientas de Testing Sugeridas**

#### **Para la API:**
```bash
# Usar curl para testing manual
curl -X GET http://localhost:3000/api/health

# Usar Postman para testing completo
# Importar colección de endpoints desde docs/
```

#### **Para la Aplicación:**
```bash
# Tests unitarios Flutter
flutter test

# Tests de integración
flutter drive --target=test_driver/app.dart
```




---

## 🎥 **Demo y Capturas de Pantalla**

### 📹 **Video de Demostración**
> 🎬 **[Ver Demo Completa en YouTube](https://youtube.com/tu-video-demo)**
> 
> El video incluye:
> - ✅ Configuración inicial del proyecto
> - ✅ Navegación entre pantallas principales
> - ✅ Creación y gestión de sesiones C&C
> - ✅ Ejecución de comandos simulados
> - ✅ Funcionalidades offline y sincronización
> - ✅ Monitoreo de estadísticas en tiempo real

### 📸 **Galería de Pantallas**

<div align="center">

| 📋 Lista de Sesiones | 📄 Detalle y Comandos | ➕ Formulario de Creación |
|:---:|:---:|:---:|
| ![Lista](docs/screenshots/session-list.png) | ![Detalle](docs/screenshots/session-detail.png) | ![Formulario](docs/screenshots/session-form.png) |

| 📊 Dashboard Estadísticas | ⚙️ Configuración | 🎨 Tema Oscuro |
|:---:|:---:|:---:|
| ![Estadísticas](docs/screenshots/statistics.png) | ![Configuración](docs/screenshots/settings.png) | ![Tema Oscuro](docs/screenshots/dark-theme.png) |

</div>

---


### 📋 **Roadmap de Desarrollo**

#### **🔄 Versión Actual (v1.0.0)**
- ✅ CRUD completo de sesiones
- ✅ Ejecución de comandos simulada
- ✅ Sincronización API/Local
- ✅ Interfaz responsive

#### **🚀 Próximas Versiones**

**v1.1.0 - Análisis Avanzado**
- 📊 Gráficos de actividad en tiempo real
- 🔍 Análisis de patrones de comandos
- 📈 Métricas de rendimiento del sistema
- 🎯 Detección de comportamientos anómalos

**v1.2.0 - Colaboración**
- 👥 Múltiples operadores simultáneos
- 💬 Chat entre investigadores
- 📋 Sistema de notas compartidas
- 🔔 Notificaciones push

**v2.0.0 - Simulación Avanzada**
- 🌐 Simulación de red completa
- 🤖 Bots con comportamiento autónomo
- 🔒 Módulos de cifrado/descifrado
- 🕵️ Técnicas de evasión simuladas

---

#### **❌ Error: "API no disponible"**
```bash
# Solución:
1. Verificar que el backend esté ejecutándose: npm run dev
2. Comprobar la URL en Configuración: http://localhost:3000/api
3. Revisar logs del servidor para errores
```

#### **❌ Error: "Database not initialized"**
```bash
# Solución:
1. Limpiar caché de Flutter: flutter clean
2. Reinstalar dependencias: flutter pub get
3. Recrear base de datos desde la app: Menú → Recrear BD
```

#### **❌ Error: "Validation failed"**
```bash
# Solución:
1. Verificar formato de IP (IPv4 válida)
2. Usar nombres alfanuméricos para máquinas
3. Comprobar rango de puertos (1-65535)
```

---

## 📄 **Licencia y Uso Académico**

### 📜 **Licencia MIT**

```
MIT License

Copyright (c) 2025 Semillero DarkWall - Universidad de Medellín

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<div align="center">

## 🎯 **¿Listo para Explorar el Mundo de la Ciberseguridad?**

---

**⭐ Si este proyecto te ha sido útil, no olvides darle una estrella en GitHub ⭐**

**🔒 Desarrollado con 💜 para la educación en ciberseguridad**

**🛡️ Semillero DarkWall - Universidad de Medellín | 2025**

---
