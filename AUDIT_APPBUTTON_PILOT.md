# Auditoría AppButton + Pantalla Piloto

## Estado actual de AppButton

> **`lib/shared/widgets/app_button.dart` no existe en el repositorio.**
> El archivo referenciado en CLAUDE.md y en la auditoría anterior no ha sido creado aún.
> Las 211 ocurrencias de botones ad-hoc y las 80+ clases privadas `_*Button` funcionan sin
> ningún componente compartido base.

- Variantes implementadas: **ninguna — archivo inexistente**
- Variantes faltantes vs DS v1.0: `primary`, `ghost`, `outline`, `teal`, `danger` — **todas**
- Tamaños: **ninguno**
- Loading state: **no**
- Icono support: **no**
- Disabled state: **no**
- Constructor completo: **N/A**

```dart
// app_button.dart no existe
```

## Código completo de app_button.dart

```
// Archivo no encontrado en lib/shared/widgets/app_button.dart
// ni en ninguna otra ruta bajo lib/
```

---

## Ranking de pantallas por deuda

> Métricas: TextStyle inline + botones ad-hoc (ElevatedButton|TextButton|OutlinedButton) + widgets privados (_*Button|_*Card|_*Row|_*Badge|_*Chip).
> Ordenado de menor a mayor deuda total.

| Pantalla | TextStyle | Buttons | PrivWidgets | Total |
|---|---|---|---|---|
| lib/features/auth/forgot_password_screen.dart | 3 | 0 | 0 | 3 |
| lib/features/auth/reset_password_screen.dart *(excluida — auth)* | 3 | 0 | 0 | 3 |
| lib/features/assignments/assignment_detail_screen.dart | 0 | 1 | 4 | 5 |
| lib/features/config/worker_detail_screen.dart | 4 | 1 | 0 | **5** |
| lib/features/auth/activate_screen.dart | 6 | 0 | 0 | 6 |
| lib/features/escalaciones/escalaciones_screen.dart | 6 | 1 | 0 | 7 |
| lib/features/catalogs/catalogs_screen.dart | 3 | 1 | 6 | 10 |
| lib/features/flows/execution_detail_screen.dart | 2 | 6 | 3 | 11 |
| lib/features/config/operator_roles_screen.dart | 2 | 8 | 4 | 14 |
| lib/features/overview/overview_screen.dart | 7 | 0 | 8 | 15 |
| lib/features/assignments/assignments_screen.dart | 2 | 4 | 10 | 16 |
| lib/features/auth/login_screen.dart *(excluida — auth)* | 15 | 0 | 1 | 16 |
| lib/features/config/ai_workers_screen.dart | 14 | 0 | 3 | 17 |
| lib/features/config/operators_screen.dart | 8 | 0 | 11 | 19 |
| lib/features/flows/executions_screen.dart | 14 | 3 | 2 | 19 |
| lib/features/sessions/sessions_screen.dart | 20 | 0 | 6 | 26 |
| lib/features/flows/all_executions_screen.dart | 0 | 18 | 10 | 28 |
| lib/features/catalogs/catalog_detail_screen.dart | 0 | 15 | 14 | 29 |
| lib/features/config/whatsapp_groups_screen.dart | 23 | 0 | 8 | 31 |
| lib/features/settings/operator_fields_screen.dart | 19 | 9 | 3 | 31 |
| lib/features/config/workflows_screen.dart | 23 | 0 | 10 | 33 |
| lib/features/broadcasts/broadcast_screen.dart | 17 | 0 | 17 | 34 |
| lib/features/config/meta_credentials_screen.dart | 20 | 0 | 17 | 37 |
| lib/features/config/channel_detail_screen.dart | 29 | 0 | 10 | 39 |
| lib/features/dashboard/dashboard_screen.dart | 27 | 4 | 9 | 40 |
| lib/features/flows/flow_integrations_screen.dart | 23 | 14 | 3 | 40 |
| lib/features/config/connections_screen.dart | 15 | 14 | 12 | 41 |
| lib/features/config/operator_detail_screen.dart | 35 | 8 | 4 | 47 |
| lib/features/config/channels_screen.dart | 61 | 0 | 5 | 66 |
| lib/features/config/settings_screen.dart | 57 | 3 | 17 | 77 |
| lib/features/conversations/conversations_screen.dart | 113 | 14 | 10 | 137 |
| lib/features/flows/flow_detail_screen.dart | 150 | 18 | 6 | 174 |

---

## Pantalla piloto recomendada

- **Archivo:** `lib/features/config/worker_detail_screen.dart`
- **Justificación:** Menor deuda total (5) entre pantallas funcionales no-auth, con 0 widgets privados y solo 1 botón ad-hoc a migrar.
- TextStyle inline: **4**
- Botones ad-hoc: **1**
- Widgets privados: **0**
