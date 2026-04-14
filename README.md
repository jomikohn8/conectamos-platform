# ConectamOS Platform

**Plataforma SaaS de operaciones conversacionales sobre WhatsApp Business API**

![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Hosting-FFCA28?logo=firebase&logoColor=black)
![Supabase](https://img.shields.io/badge/Supabase-Realtime-3ECF8E?logo=supabase&logoColor=white)
![Vercel](https://img.shields.io/badge/Backend-Vercel-000000?logo=vercel&logoColor=white)

---

## ¿Qué es ConectamOS?

ConectamOS es una plataforma de gestión conversacional B2B que centraliza las operaciones de WhatsApp Business para empresas con múltiples líneas, flujos automatizados y equipos de supervisores. Permite a los equipos de operaciones monitorear conversaciones en tiempo real, gestionar operadores, visualizar el feed de mensajes y administrar la configuración de flujos por tenant.

La plataforma está diseñada bajo un modelo **multi-tenant**: cada empresa cliente (tenant) opera de forma aislada sobre la misma infraestructura, con sus propios operadores, flujos, credenciales Meta y métricas.

### Casos de uso activos

| Tenant | Descripción |
|--------|-------------|
| **TMR-Prixz** | Operaciones de campo y soporte técnico vía WhatsApp |
| **Brightcell** | Atención a distribuidores de telefonía |
| **Ova** | Gestión de leads y seguimiento comercial |
| **Hedajoga** | Comunicación con instructores y alumnos |

### Arquitectura conceptual

```
Tenant
  └── Operador (número WhatsApp registrado)
        └── Sesión (conversación activa)
              └── Flujo (automatización asignada)
                    └── Registro (evento de negocio capturado)
                          └── Evento (acción disparada: notificación, webhook, etc.)
```

---

## Stack técnico

| Capa | Tecnología |
|------|-----------|
| **Frontend** | Flutter Web 3.x |
| **State management** | Riverpod 2.x (`StateNotifierProvider`, `ConsumerStatefulWidget`) |
| **Navegación** | go_router |
| **Auth + Realtime + DB** | Supabase (PostgreSQL + Realtime streams) |
| **Hosting** | Firebase Hosting |
| **Backend API** | FastAPI en Vercel → [`skohn311/poc_api`](https://github.com/skohn311/poc_api) |
| **Mensajería** | WhatsApp Business API (Meta Graph API v19.0) |
| **CI/CD** | GitHub Actions → Firebase deploy en cada push a `main` |

---

## Estructura del proyecto

```
lib/
├── main.dart                        # Punto de entrada, inicialización Supabase
│
├── core/
│   ├── api/
│   │   ├── api_client.dart          # Cliente Dio → poc-api-lilac.vercel.app
│   │   ├── messages_api.dart        # Envío de mensajes, typing, read receipts
│   │   ├── operators_api.dart       # CRUD de operadores
│   │   ├── sessions_api.dart        # Gestión de sesiones
│   │   ├── tenants_api.dart         # Carga de tenants disponibles
│   │   ├── supabase_messages.dart   # Streams y queries directas a wa_messages
│   │   └── supabase_read_receipts.dart  # Read receipts vía backend
│   ├── config.dart                  # Constantes globales
│   ├── providers/
│   │   ├── auth_provider.dart       # Estado de autenticación Supabase
│   │   └── tenant_provider.dart     # Multi-tenancy: TenantInfo, TenantNotifier
│   ├── router/
│   │   └── app_router.dart          # Rutas y guards de autenticación
│   └── theme/
│       ├── app_theme.dart           # ThemeData global
│       ├── colors.dart              # AppColors (paleta ConectamOS)
│       └── text_styles.dart         # Estilos tipográficos
│
├── features/
│   ├── auth/
│   │   └── login_screen.dart        # Pantalla de login con Supabase Auth
│   ├── overview/
│   │   └── overview_screen.dart     # Dashboard de KPIs y métricas del día
│   ├── conversations/
│   │   └── conversations_screen.dart # Panel de conversaciones en tiempo real
│   ├── sessions/
│   │   └── sessions_screen.dart     # Historial y gestión de sesiones
│   ├── dashboard/
│   │   └── dashboard_screen.dart    # Vista ejecutiva (placeholder)
│   └── config/
│       ├── operators_screen.dart    # ABM de operadores
│       ├── workflows_screen.dart    # Configuración de flujos
│       ├── whatsapp_groups_screen.dart  # Grupos de WhatsApp
│       └── meta_credentials_screen.dart # Credenciales Meta por tenant
│
└── shared/
    └── widgets/
        └── app_shell.dart           # Shell principal: sidebar, topbar, tenant selector
```

---

## Pantallas implementadas

| Pantalla | Descripción |
|----------|-------------|
| **Login** | Autenticación con email + contraseña vía Supabase Auth |
| **Overview** | KPIs del día: mensajes recibidos, sesiones activas, operadores conectados |
| **Conversaciones → Por operador** | Sidebar con operadores registrados, chat en tiempo real con stream de Supabase, ventana de 24hrs, burbujas estilo WhatsApp, status icons (sent/delivered/read/failed) |
| **Conversaciones → Feed global** | Todos los mensajes del tenant con filtros por dirección, fecha, contacto y keyword |
| **Sesiones** | Listado de sesiones con estado, duración y operador asignado |
| **Operadores** | Alta, edición y asignación de flujos a operadores; banner de números no registrados |
| **Flujos** | Configuración de automatizaciones por tenant |
| **Grupos WhatsApp** | Administración de grupos de distribución |
| **Credenciales Meta** | Configuración de `phone_number_id` y `access_token` por tenant |

---

## Setup local

### Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- Acceso al proyecto Supabase (solicitar credenciales al equipo)
- Acceso al backend `poc_api` en Vercel (o levantar localmente)

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/jomikohn8/conectamos-platform.git
cd conectamos-platform

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Supabase
# Edita lib/main.dart y reemplaza las variables:
#   supabaseUrl: 'https://<tu-proyecto>.supabase.co'
#   supabaseAnonKey: '<tu-anon-key>'

# 4. Correr en Chrome
flutter run -d chrome
```

> **Nota:** El backend API (`poc-api-lilac.vercel.app`) está configurado en `lib/core/api/api_client.dart`. Para apuntar a un entorno local, reemplaza `baseUrl` por `http://localhost:8000`.

---

## Deploy

### Automático (recomendado)

Cada push a la rama `main` dispara el workflow de GitHub Actions:

```
push a main
  → flutter pub get
  → flutter build web --release
  → firebase deploy --only hosting --token $FIREBASE_TOKEN
```

Requiere el secret `FIREBASE_TOKEN` configurado en **GitHub → Settings → Secrets → Actions**.  
Para generar el token: `firebase login:ci`

### Manual

```bash
flutter build web --release
firebase deploy --only hosting
```

### URL de producción

🌐 **https://conectamos-platform-poc.web.app**

---

## Arquitectura multi-tenant

La plataforma soporta múltiples clientes (tenants) desde una sola instancia. Cada tenant tiene su propio conjunto de operadores, flujos, credenciales Meta y datos en Supabase.

### Roles

| Rol | Acceso |
|-----|--------|
| **superadmin** (`miguel@conectamos.mx`) | Puede cambiar entre tenants desde el selector en la topbar |
| **admin / supervisor** | Accede únicamente al tenant asignado |

### Cambiar de tenant en la UI

El superadmin ve un dropdown en la topbar con todos los tenants disponibles. Al seleccionar uno, todos los streams, queries y operaciones se filtran automáticamente por `tenant_id`. La selección se persiste en `localStorage` entre sesiones.

---

## Variables de entorno y configuración

### Supabase (`lib/main.dart`)

```dart
await Supabase.initialize(
  url: 'https://<proyecto>.supabase.co',
  anonKey: '<anon-key>',
);
```

### Backend API (`lib/core/api/api_client.dart`)

```dart
static const String baseUrl = 'https://poc-api-lilac.vercel.app';
```

### Credenciales Meta (WhatsApp)

Las credenciales de la Meta Graph API (`access_token`, `phone_number_id`) están almacenadas en el backend y en la tabla `tenants` de Supabase. **No existe ninguna credencial de Meta en el código del frontend.**

---

## Equipo y contacto

**Conectamos Tech & Delivery Solutions SAPI de CV**

Plataforma desarrollada y mantenida por el equipo de producto de Conectamos.  
Desarrollo técnico dirigido por **José Miguel Kohn** — COO.

Para soporte técnico o acceso al entorno de staging, contactar al equipo interno.
