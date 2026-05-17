# SKILL — Flutter Shared Widgets · conectamos-platform

> **Propósito:** Marco conceptual y reglas de uso de componentes compartidos para Claude Code.
> Antes de escribir cualquier widget de presentación en una pantalla nueva o modificación,
> lee este archivo completo. Las reglas aquí superan cualquier patrón anterior que hayas visto
> en el repo.
> **Fuente:** Auditoría 2026-05-17 + primitivos creados en sprint de refactor.
> **Mantenimiento:** Actualizar al agregar primitivos nuevos a lib/shared/widgets/.

---

## 1. Arquitectura de capas — obligatorio entender antes de escribir código

El repo sigue una jerarquía estricta de tres capas. Nunca saltarse capas hacia abajo.

```
┌─────────────────────────────────────────────┐
│  CAPA 3 — Composites de feature             │
│  lib/features/[módulo]/widgets/             │
│  Widgets con lógica de negocio que usan     │
│  primitivos. Ej: ConversationCard,          │
│  OperatorRow, FlowStatusBadge               │
├─────────────────────────────────────────────┤
│  CAPA 2 — Primitivos compartidos            │
│  lib/shared/widgets/                        │
│  Widgets de presentación pura, sin lógica   │
│  de negocio. Ej: AppButton, AppBadge        │
├─────────────────────────────────────────────┤
│  CAPA 1 — Tokens de diseño                  │
│  lib/core/theme/colors.dart                 │
│  lib/core/theme/text_styles.dart            │
│  Constantes puras. AppColors.*, AppTextStyles.* │
└─────────────────────────────────────────────┘
```

**Regla cardinal:** Las screens (`lib/features/[módulo]/[nombre]_screen.dart`) son
**compositors** — solo organizan widgets, no crean presentación inline.
Una screen NO debe contener `Container` con `BoxDecoration` inline, `TextStyle` inline,
ni widgets Flutter base de botón (`ElevatedButton`, `TextButton`, `OutlinedButton`).

---

## 2. Primitivos disponibles — catálogo completo

### 2.1 AppButton · `lib/shared/widgets/app_button.dart`

Widget canónico para todos los botones de la plataforma.

```dart
import '../../shared/widgets/app_button.dart';

// Uso mínimo
AppButton(
  label: 'Guardar',
  onPressed: _save,
)

// Con variante y tamaño
AppButton(
  label: 'Eliminar',
  variant: AppButtonVariant.danger,
  size: AppButtonSize.sm,
  onPressed: _delete,
)

// Con ícono prefijo
AppButton(
  label: 'Agregar operador',
  variant: AppButtonVariant.primary,
  prefixIcon: const Icon(Icons.add, size: 16, color: AppColors.ctTeal),
  onPressed: _openForm,
)

// Estado loading
AppButton(
  label: 'Enviando...',
  isLoading: _sending,
  onPressed: _send,
)

// Ancho completo
AppButton(
  label: 'Iniciar sesión',
  variant: AppButtonVariant.teal,
  expand: true,
  onPressed: _login,
)
```

**Variantes disponibles:**

| Variante | Cuándo usar |
|---|---|
| `primary` (default) | Acción principal de la pantalla — bg ctNavy, texto ctTeal |
| `teal` | CTA de auth, acciones de alta importancia — bg ctTeal, texto ctNavy |
| `ghost` | Acciones secundarias, cancelar, reintentar — bg transparente |
| `outline` | Alternativa a ghost cuando se necesita borde visible |
| `danger` | Acciones destructivas — eliminar, revocar |

**Tamaños:**

| Tamaño | Altura | Cuándo usar |
|---|---|---|
| `normal` (default) | 42px | Botones principales de pantalla |
| `sm` | 32px | Botones dentro de cards, tablas, dialogs |

**PROHIBIDO usar en su lugar:**
- `ElevatedButton` — reemplazar siempre por `AppButton`
- `TextButton` — reemplazar por `AppButton(variant: AppButtonVariant.ghost)`
- `OutlinedButton` — reemplazar por `AppButton(variant: AppButtonVariant.outline)`
- `FilledButton` — reemplazar por `AppButton(variant: AppButtonVariant.teal)`

---

### 2.2 AppBadge · `lib/shared/widgets/app_badge.dart`

Badge de estado, canal, tipo o cualquier etiqueta categórica.

```dart
import '../../shared/widgets/app_badge.dart';

// Badge semántico
AppBadge(label: 'Activo', variant: AppBadgeVariant.ok)
AppBadge(label: 'Pendiente', variant: AppBadgeVariant.warn)
AppBadge(label: 'Error', variant: AppBadgeVariant.danger)
AppBadge(label: 'WhatsApp', variant: AppBadgeVariant.teal)

// Con punto de estado
AppBadge(label: 'En línea', variant: AppBadgeVariant.ok, dot: true)

// Con ícono prefijo
AppBadge(
  label: 'Sincronizado',
  variant: AppBadgeVariant.info,
  prefixIcon: const Icon(Icons.sync, size: 12),
)
```

**Variantes disponibles:**

| Variante | bg → texto | Uso típico |
|---|---|---|
| `ok` | ctOkBg → ctOkText | Activo, exitoso, en línea |
| `warn` | ctWarnBg → ctWarnText | Pendiente, en proceso, advertencia |
| `danger` | ctRedBg → ctRedText | Error, fallido, bloqueado |
| `info` | ctInfoBg → ctInfoText | Informativo, sincronizado |
| `neutral` | ctSurface2 → ctText2 | Sin estado relevante, desconocido |
| `teal` | ctTealLight → ctTealText | Marca, canal WhatsApp, destacado |
| `purple` | ctPurpleBg → ctPurpleText | Tipo fecha, tipo especial |
| `orange` | ctOrangeBg → ctOrangeText | Reabierto, atención requerida |

**PROHIBIDO crear:** `_StatusBadge`, `_ChannelBadge`, `_SourceBadge`, `_SyncStatusBadge`,
`_SmallBadge`, `_Badge` privados. Usar `AppBadge` siempre.

---

### 2.3 AppChip · `lib/shared/widgets/app_chip.dart`

Chip de filtro interactivo para barras de filtros y selección múltiple.

```dart
import '../../shared/widgets/app_chip.dart';

// Chip de filtro
AppChip(
  label: 'Todos',
  isActive: _filter == 'all',
  onTap: () => setState(() => _filter = 'all'),
)

// Chip no interactivo (display only)
AppChip(label: 'WhatsApp')

// Con ícono
AppChip(
  label: 'Activos',
  isActive: true,
  prefixIcon: const Icon(Icons.circle, size: 8, color: AppColors.ctTeal),
  onTap: _toggleActive,
)
```

**Estados:**
- Inactivo: borde `ctBorder`, texto `ctText2`, fondo transparente
- Activo: fondo `ctNavy`, texto `ctTeal`, borde `ctNavy`
- Hover inactivo: fondo `ctSurface2`

**PROHIBIDO crear:** `_TopbarChip`, `_FilterChip`, `_OpChip`, `_MiniMetricChip` privados.

---

### 2.4 AppDetailRow · `lib/shared/widgets/app_detail_row.dart`

Fila label + valor para fichas de detalle, configuración y resumen.

```dart
import '../../shared/widgets/app_detail_row.dart';

// Uso básico — label izquierda, valor derecha
AppDetailRow(
  label: 'Tenant ID',
  value: Text(_tenant['id'], style: AppTextStyles.body),
)

// Con badge como valor
AppDetailRow(
  label: 'Estado',
  value: AppBadge(label: 'Activo', variant: AppBadgeVariant.ok),
)

// Con ícono prefijo en el label
AppDetailRow(
  label: 'Teléfono',
  prefixIcon: const Icon(Icons.phone, size: 14, color: AppColors.ctText3),
  value: Text(_operator['phone'] ?? '—', style: AppTextStyles.body),
)

// Alineación superior para valores largos
AppDetailRow(
  label: 'Descripción',
  crossAxisAlignment: CrossAxisAlignment.start,
  value: Text(_flow['description'] ?? '—', style: AppTextStyles.bodySmall),
)
```

**Patrón de ficha de detalle completa:**
```dart
Column(
  children: [
    AppDetailRow(label: 'ID', value: Text(item['id'])),
    const Divider(height: 1),
    AppDetailRow(label: 'Nombre', value: Text(item['name'])),
    const Divider(height: 1),
    AppDetailRow(label: 'Estado', value: AppBadge(
      label: item['status'],
      variant: AppBadgeVariant.ok,
    )),
  ],
)
```

**PROHIBIDO crear:** `_DetailRow`, `_ConfigRow`, `_KpiRow`, `_SummaryRow`, `_GroupRow` privados.

---

### 2.5 AppKpiCard · `lib/shared/widgets/app_kpi_card.dart`

Tarjeta de métrica para dashboards, overviews y fichas de resumen.

```dart
import '../../shared/widgets/app_kpi_card.dart';

// KPI básico
AppKpiCard(
  label: 'CONVERSACIONES HOY',
  value: '42',
)

// Con subtítulo y acento
AppKpiCard(
  label: 'TIEMPO DE RESPUESTA',
  value: '3.2m',
  subtitle: 'promedio últimas 24h',
  accentColor: AppColors.ctWarn,
)

// KPI tappable
AppKpiCard(
  label: 'OPERADORES ACTIVOS',
  value: _activeCount.toString(),
  onTap: () => context.go('/operators'),
)

// Con ícono decorativo
AppKpiCard(
  label: 'FLUJOS EJECUTADOS',
  value: '128',
  prefixIcon: const Icon(Icons.bolt, size: 18, color: AppColors.ctTeal),
)
```

**PROHIBIDO crear:** `_SessionKpiCard`, `_KpiCard`, widgets kpi ad-hoc en features.

---

## 3. Tokens de diseño — reglas de uso

### Colores

**NUNCA** usar valores hex inline, `Color(0xFF...)`, `Color.fromARGB(...)` en screens
ni en widgets de features. Todo color viene de `AppColors`.

```dart
// ❌ PROHIBIDO
color: Color(0xFF59E0CC)
color: Color(0xFF9CA3AF)

// ✅ CORRECTO
color: AppColors.ctTeal
color: AppColors.ctText3
```

Tokens de uso frecuente:

| Token | Valor | Uso |
|---|---|---|
| `AppColors.ctNavy` | #0B132B | Botón primary bg, AppBar, sidebar |
| `AppColors.ctTeal` | #59E0CC | Acento, botón teal bg, tab activo |
| `AppColors.ctTealLight` | #CCFBF1 | Badge teal bg, estado activo suave |
| `AppColors.ctTealText` | #0F766E | Texto sobre fondo teal light |
| `AppColors.ctText` | #111827 | Texto principal |
| `AppColors.ctText2` | #6B7280 | Texto secundario, labels |
| `AppColors.ctText3` | #9CA3AF | Placeholder, caption, muted |
| `AppColors.ctSurface` | #FFFFFF | Fondo de cards |
| `AppColors.ctSurface2` | #F3F4F6 | Fondo hover, fondo alternado |
| `AppColors.ctBorder` | #E5E7EB | Bordes de contenedores |
| `AppColors.ctDanger` | #EF4444 | Acciones destructivas, errores |
| `AppColors.ctOk` | #10B981 | Estados exitosos |
| `AppColors.ctWarn` | #F59E0B | Advertencias, pendientes |
| `AppColors.ctWa` | #25D366 | WhatsApp — solo en contexto de canal |
| `AppColors.ctTg` | #229ED9 | Telegram — solo en contexto de canal |

### Tipografía

**NUNCA** usar `TextStyle(...)` inline en screens ni widgets de features.
Todo estilo viene de `AppTextStyles` o `.copyWith()` sobre un token existente.

```dart
// ❌ PROHIBIDO
style: TextStyle(fontFamily: 'Geist', fontSize: 13, fontWeight: FontWeight.w400)

// ✅ CORRECTO
style: AppTextStyles.body

// ✅ CORRECTO — cuando necesitas ajustar solo color
style: AppTextStyles.body.copyWith(color: AppColors.ctText2)
```

Tokens disponibles:

| Token | Spec | Uso |
|---|---|---|
| `AppTextStyles.pageTitle` | Onest 15 700 ctText | Título de pantalla |
| `AppTextStyles.pageSubtitle` | Geist 13 400 ctText2 | Subtítulo de pantalla |
| `AppTextStyles.cardTitle` | Onest 13 600 ctText | Título de card o sección |
| `AppTextStyles.body` | Geist 13 400 ctText | Texto de cuerpo principal |
| `AppTextStyles.bodySmall` | Geist 11 400 ctText2 | Texto secundario, metadata |
| `AppTextStyles.caption` | Geist 10 400 ctText3 | Timestamp, caption, muted |
| `AppTextStyles.formLabel` | Geist 12 600 ctText | Label de input en formularios |
| `AppTextStyles.kpiLabel` | Geist 10 600 ctText2 uppercase | Label de KPI |
| `AppTextStyles.kpiValue` | Onest 28 700 ctText | Valor numérico de KPI |
| `AppTextStyles.badge` | Geist 11 600 | Texto en badges (sin color fijo) |
| `AppTextStyles.navItem` | Geist 12 400 ctText2 | Ítem de nav inactivo |
| `AppTextStyles.navItemActive` | Geist 12 600 ctTeal | Ítem de nav activo |

---

## 4. Cuándo crear un widget privado `_*` vs usar un primitivo

**Usar primitivo siempre que:**
- El elemento es un botón de cualquier tipo → `AppButton`
- El elemento es una etiqueta de estado, canal, tipo → `AppBadge`
- El elemento es un chip de filtro o selección → `AppChip`
- El elemento es una fila label + valor → `AppDetailRow`
- El elemento es una tarjeta de métrica numérica → `AppKpiCard`

**Crear widget privado `_*` solo cuando:**
- El widget tiene lógica de negocio específica del módulo que no pertenece a shared
- El widget combina múltiples primitivos en una composición propia del dominio
  (ej: `_ConversationCard` que combina `AppBadge` + `AppDetailRow` + lógica de ventana)
- El widget NO es una variación cosmética de un primitivo existente

**Señal de alerta — si estás creando alguno de estos, usa el primitivo en su lugar:**
```
_PrimaryButton, _GhostButton, _OutlineButton, _TealButton, _DangerButton
_StatusBadge, _ChannelBadge, _SourceBadge, _SyncBadge, _SmallBadge
_FilterChip, _TopbarChip, _OpChip
_DetailRow, _ConfigRow, _SummaryRow, _KpiRow, _GroupRow
_KpiCard, _MetricCard, _SessionKpiCard
```

---

## 5. Patrón de screen limpia — checklist antes de hacer commit

Antes de entregar código de una screen nueva o modificada, verifica:

```bash
# Cero botones Flutter base
grep -c "ElevatedButton\|TextButton\|OutlinedButton\|FilledButton" lib/features/[modulo]/[archivo].dart
# → debe retornar 0

# Cero colores hex inline
grep -c "Color(0x\|Color.fromARGB\|Color.fromRGBO" lib/features/[modulo]/[archivo].dart
# → debe retornar 0

# Cero TextStyle inline
grep -c "TextStyle(" lib/features/[modulo]/[archivo].dart
# → debe retornar 0

# Análisis estático limpio
flutter analyze lib/features/[modulo]/[archivo].dart
# → No issues found
```

Si alguno retorna > 0, no hacer commit — aplicar los primitivos correspondientes primero.

---

## 6. Imports canónicos

Rutas relativas desde `lib/features/[módulo]/`:

```dart
// Primitivos
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/app_detail_row.dart';
import '../../shared/widgets/app_kpi_card.dart';

// Tokens
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
```

Desde `lib/shared/widgets/` (un widget shared importando otro):
```dart
import 'app_badge.dart';
import 'app_button.dart';
```

---

## 7. Deuda técnica conocida — no replicar estos patrones

Los siguientes problemas existen en el repo pero están pendientes de migración.
No los repliques en código nuevo:

| Archivo | Problema | Estado |
|---|---|---|
| `lib/shared/widgets/app_shell.dart` | `Color(0x...)` inline, `TextStyle` inline | Pendiente migración |
| `lib/shared/widgets/app_chip.dart` | `TextStyle` local Geist 500 12px (token faltante en AppTextStyles) | Pendiente agregar token |
| `AppTextStyles.btnPrimary` | Color `ctNavy` fijo — debería ser sin color | Pendiente corrección DS |
| `lib/features/conversations/conversations_screen.dart` | 113 TextStyle inline, 14 botones ad-hoc | Pendiente migración |
| `lib/features/flows/flow_detail_screen.dart` | 150 TextStyle inline, 18 botones ad-hoc | Pendiente migración |

Pantallas con baja deuda ya migradas o limpias:
- `lib/features/config/worker_detail_screen.dart` ✅ — referencia de patrón correcto

---

## 8. Convención de AppBar con TabBar

El patrón del repo usa `TextStyle` inline en `TabBar.labelStyle`. Reemplazar por tokens:

```dart
// ❌ Patrón viejo (ver FLUTTER_CONVENTIONS.md sección 3)
labelStyle: const TextStyle(fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w600),
unselectedLabelStyle: const TextStyle(fontFamily: 'Geist', fontSize: 12),

// ✅ Patrón correcto
labelStyle: AppTextStyles.formLabel,
unselectedLabelStyle: AppTextStyles.navItem,
```
