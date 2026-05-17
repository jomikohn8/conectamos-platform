# Auditoría UI Components — 2026-05-17

## Resumen ejecutivo
| Categoría | Ocurrencias |
|---|---|
| Botones ad-hoc (fuera de app_button.dart) | 211 |
| Clases _*Button / _*Btn privadas | 80+ |
| Color hardcodeado (fuera de colors.dart) | 40+ |
| TextStyle inline (fuera de tokens) | 1 245 |
| Widgets privados _Card/_Row/_Chip/_Badge/_Dialog | 206+ |
| Container/BoxDecoration en features/ | 1 245 |
| Archivos en lib/shared/widgets/ | 5 |

---

## Detalle por categoría

### Botones ad-hoc
> ElevatedButton / TextButton / OutlinedButton / FilledButton fuera de `app_button.dart` — 211 ocurrencias en 27 archivos.

| Archivo | Ocurrencias |
|---|---|
| lib/features/conversations/conversations_screen.dart | 24 |
| lib/features/flows/all_executions_screen.dart | 18 |
| lib/features/flows/flow_detail_screen.dart | 18 |
| lib/features/catalogs/new_catalog_wizard.dart | 17 |
| lib/features/catalogs/catalog_detail_screen.dart | 15 |
| lib/features/flows/flow_integrations_screen.dart | 14 |
| lib/features/config/connections_screen.dart | 14 |
| lib/features/escalaciones/widgets/escalacion_detail_sheet.dart | 11 |
| lib/features/settings/operator_fields_screen.dart | 9 |
| lib/features/config/operator_roles_screen.dart | 8 |
| lib/features/config/operator_detail_screen.dart | 8 |
| lib/features/config/template_create_dialog.dart | 8 |
| lib/features/flows/widgets/execution_header_block.dart | 8 |
| lib/features/assignments/assignments_screen.dart | 4 |
| lib/features/dashboard/dashboard_screen.dart | 4 |
| lib/features/config/operator_roles_screen.dart | 8 |
| lib/features/config/role_permissions_panel.dart | 2 |
| lib/features/flows/widgets/execution_metadata_sidebar.dart | 2 |
| lib/features/flows/widgets/field_card.dart | 2 |
| lib/features/config/settings_screen.dart | 3 |
| lib/features/flows/executions_screen.dart | 3 |
| lib/features/config/operator_detail_screen.dart | 8 |
| lib/features/config/worker_detail_screen.dart | 1 |
| lib/features/config/widgets/operator_form_dialog.dart | 4 |
| lib/features/catalogs/catalogs_screen.dart | 1 |
| lib/features/escalaciones/escalaciones_screen.dart | 1 |
| lib/features/assignments/assignment_detail_screen.dart | 1 |
| lib/features/settings/widgets/operator_field_form_dialog.dart | 5 |

**Muestra representativa — lib/features/escalaciones/widgets/escalacion_detail_sheet.dart:**
```
188: TextButton(
192: ElevatedButton(
196:   style: ElevatedButton.styleFrom(
248: TextButton(
252: ElevatedButton(
254:   style: ElevatedButton.styleFrom(
786: ElevatedButton.icon(
790:   style: ElevatedButton.styleFrom(
852: TextButton(
856: ElevatedButton(
858:   style: ElevatedButton.styleFrom(
```

---

### Clases _*Button / _*Btn privadas

| Clase | Archivo:línea |
|---|---|
| `_TopbarIconBtn` | lib/shared/widgets/app_shell.dart:434 |
| `_SmallButton` | lib/features/flows/widgets/execution_header_block.dart:571 |
| `_ExportMenuButton` | lib/features/flows/widgets/execution_header_block.dart:596 |
| `_PrimaryButton` | lib/features/flows/flow_detail_screen.dart:4155 |
| `_GhostButton` | lib/features/flows/flow_detail_screen.dart:4193 |
| `_ViewToggleBtn` | lib/features/overview/overview_screen.dart:1020 |
| `_PrimaryButton` | lib/features/catalogs/catalogs_screen.dart:698 |
| `_SyncButton` | lib/features/catalogs/catalog_detail_screen.dart:574 |
| `_SaveButton` | lib/features/catalogs/catalog_detail_screen.dart:604 |
| `_AuthPrimaryButtonState` | lib/features/auth/auth_shared.dart:502 |
| `_ActionBarGhostButton` | lib/features/conversations/conversations_screen.dart:106 |
| `_PrimaryButton` | lib/features/conversations/conversations_screen.dart:149 |
| `_ArchivedEntryButton` | lib/features/conversations/conversations_screen.dart:1179 |
| `_InterveneButton` | lib/features/conversations/conversations_screen.dart:3168 |
| `_GhostButton` | lib/features/conversations/conversations_screen.dart:6047 |
| `_NmToggleBtn` | lib/features/conversations/conversations_screen.dart:7022 |
| `_GhostButton` | lib/features/sessions/sessions_screen.dart:88 |
| `_PrimaryButton` | lib/features/config/channel_detail_screen.dart:1553 |
| `_OutlineButton` | lib/features/config/channel_detail_screen.dart:1612 |
| `_TealButton` | lib/features/config/channel_detail_screen.dart:1667 |
| `_IconBtn` | lib/features/assignments/assignments_screen.dart:547 |
| `_DateTimePickerBtn` | lib/features/assignments/assignments_screen.dart:2357 |
| `_BehaviorBtn` | lib/features/assignments/assignments_screen.dart:2415 |
| `_PrimaryButton` | lib/features/assignments/assignments_screen.dart:2536 |
| `_GhostButton` | lib/features/assignments/assignments_screen.dart:2571 |
| `_SecondaryButton` | lib/features/assignments/assignments_screen.dart:2598 |
| `_CloseButton` | lib/features/broadcasts/broadcast_screen.dart:731 |
| `_SendButton` | lib/features/broadcasts/broadcast_screen.dart:1881 |
| `_PrimaryButton` | lib/features/broadcasts/broadcast_screen.dart:2208 |
| `_OutlineButton` | lib/features/broadcasts/broadcast_screen.dart:2269 |

---

### Colores hardcodeados

#### Color(0x...) / Color.fromARGB / Color.fromRGBO (fuera de colors.dart)

| Archivo:línea | Valor |
|---|---|
| lib/shared/widgets/app_shell.dart:365 | `Color(0xFFA7F3D0)` |
| lib/shared/widgets/app_shell.dart:375 | `Color(0xFF99F6E4)` |
| lib/shared/widgets/app_shell.dart:600 | `Color(0xFF99F6E4)` |
| lib/shared/widgets/app_shell.dart:699 | `Color(0x0FFFFFFF)` |
| lib/shared/widgets/app_shell.dart:876 | `Color(0x0FFFFFFF)` |
| lib/shared/widgets/app_shell.dart:887 | `Color(0x40FFFFFF)` |
| lib/shared/widgets/app_shell.dart:980 | `Color(0x1A59E0CC)` |
| lib/shared/widgets/app_shell.dart:982 | `Color(0x0DFFFFFF)` |
| lib/shared/widgets/app_shell.dart:996 | `Color(0xCCFFFFFF)` |
| lib/shared/widgets/app_shell.dart:997 | `Color(0x66FFFFFF)` |
| lib/shared/widgets/app_shell.dart:1025 | `Color(0x1A59E0CC)` |
| lib/shared/widgets/app_shell.dart:1027 | `Color(0x0DFFFFFF)` |
| lib/shared/widgets/app_shell.dart:1046 | `Color(0xCCFFFFFF)` |
| lib/shared/widgets/app_shell.dart:1047 | `Color(0x66FFFFFF)` |
| lib/shared/widgets/app_shell.dart:1060 | `Color(0xCCFFFFFF)` |

#### Strings hex '#...' en archivos de features

| Archivo:línea | Valor |
|---|---|
| lib/features/flows/flow_detail_screen.dart:58 | `'#9CA3AF'` |
| lib/features/config/channel_detail_screen.dart:17 | `'#59E0CC'` |
| lib/features/config/channel_detail_screen.dart:17 | `'#818CF8'` |
| lib/features/config/channel_detail_screen.dart:17 | `'#FB923C'` |
| lib/features/config/channel_detail_screen.dart:17 | `'#F472B6'` |
| lib/features/config/channel_detail_screen.dart:17 | `'#34D399'` |
| lib/features/config/channel_detail_screen.dart:17 | `'#60A5FA'` |
| lib/features/config/channel_detail_screen.dart:33 | `'#9CA3AF'` |
| lib/features/config/channels_screen.dart:35 | `'#9CA3AF'` |
| lib/features/config/channels_screen.dart:286 | `'#59E0CC'` |
| lib/features/config/channels_screen.dart:290 | `'#9CA3AF'` |
| lib/features/config/channels_screen.dart:549 | `'#59E0CC'` |
| lib/features/config/channels_screen.dart:869 | `'#25D366'` (WhatsApp green) |
| lib/features/config/channels_screen.dart:869 | `'#229ED9'` (Telegram blue) |
| lib/features/config/operators_screen.dart:858 | `'#59E0CC'` |
| lib/features/config/operator_roles_screen.dart:240 | `'#59E0CC'` |
| lib/features/config/operator_roles_screen.dart:353 | `'#59E0CC'`, `'#3B82F6'`, `'#8B5CF6'`, `'#F97316'`, `'#EF4444'`, `'#22C55E'`, `'#EC4899'`, `'#6B7280'` |
| lib/features/config/ai_workers_screen.dart:349 | `'#59E0CC'` |
| lib/features/conversations/conversations_screen.dart:717 | `'#9CA3AF'` |
| lib/features/conversations/conversations_screen.dart:3778 | `'#000'` |
| lib/features/conversations/conversations_screen.dart:5594 | `'#000'` |

---

### TextStyle inline (primeras 30 ocurrencias)

> 1 245 ocurrencias totales en 47 archivos (fuera de `app_text_styles.dart` y `app_theme.dart`).

| # | Archivo:línea |
|---|---|
| 1 | lib/shared/widgets/operator_avatar.dart:55 |
| 2 | lib/shared/widgets/asset_item_selector.dart:128 |
| 3 | lib/shared/widgets/asset_item_selector.dart:163 |
| 4 | lib/shared/widgets/asset_item_selector.dart:170 |
| 5 | lib/shared/widgets/asset_item_selector.dart:226 |
| 6 | lib/shared/widgets/asset_item_selector.dart:255 |
| 7 | lib/shared/widgets/app_shell.dart:160 |
| 8 | lib/shared/widgets/app_shell.dart:170 |
| 9 | lib/shared/widgets/app_shell.dart:244 |
| 10 | lib/shared/widgets/app_shell.dart:291 |
| 11 | lib/shared/widgets/app_shell.dart:418 |
| 12 | lib/shared/widgets/app_shell.dart:538 |
| 13 | lib/shared/widgets/app_shell.dart:583 |
| 14 | lib/shared/widgets/app_shell.dart:605 |
| 15 | lib/shared/widgets/app_shell.dart:668 |
| 16 | lib/shared/widgets/app_shell.dart:883 |
| 17 | lib/shared/widgets/app_shell.dart:960 |
| 18 | lib/shared/widgets/app_shell.dart:1053 |
| 19 | lib/shared/widgets/app_shell.dart:1080 |
| 20 | lib/shared/widgets/app_shell.dart:1184 |
| 21 | lib/shared/widgets/app_shell.dart:1240 |
| 22 | lib/shared/widgets/app_shell.dart:1321 |
| 23 | lib/features/auth/reset_password_screen.dart:175 |
| 24 | lib/features/auth/reset_password_screen.dart:196 |
| 25 | lib/features/auth/reset_password_screen.dart:278 |
| 26 | lib/features/flows/widgets/execution_export.dart:227 |
| 27 | lib/features/flows/widgets/execution_export.dart:543 |
| 28 | lib/features/flows/widgets/execution_export.dart:566 |
| 29 | lib/features/flows/widgets/execution_export.dart:574 |
| 30 | lib/features/flows/widgets/execution_export.dart:586 |

**Archivos con mayor densidad:**
| Archivo | Ocurrencias |
|---|---|
| lib/features/conversations/conversations_screen.dart | 152 |
| lib/features/flows/flow_detail_screen.dart | 155 |
| lib/features/flows/all_executions_screen.dart | 84 |
| lib/features/config/settings_screen.dart | 66 |
| lib/features/assignments/assignments_screen.dart | 64 |

---

### Widgets privados duplicados

> 206+ clases privadas `_*Card`, `_*Row`, `_*Chip`, `_*Badge`, `_*Dialog` en `lib/features/`.

| Clase | Archivo:línea |
|---|---|
| `_SideCard` | lib/features/flows/widgets/execution_metadata_sidebar.dart:499 |
| `_Badge` | lib/features/flows/widgets/execution_metadata_sidebar.dart:670 |
| `_GroupRow` | lib/features/flows/widgets/execution_metadata_sidebar.dart:881 |
| `_DesktopRow` | lib/features/flows/widgets/lineage_breadcrumb.dart:88 |
| `_CompactRow` | lib/features/flows/widgets/lineage_breadcrumb.dart:131 |
| `_ParentChip` | lib/features/flows/widgets/lineage_breadcrumb.dart:211 |
| `_CurrentChip` | lib/features/flows/widgets/lineage_breadcrumb.dart:290 |
| `_ChildChip` | lib/features/flows/widgets/lineage_breadcrumb.dart:350 |
| `_MoreChip` | lib/features/flows/widgets/lineage_breadcrumb.dart:448 |
| `_StatusBadge` | lib/features/flows/all_executions_screen.dart:2788 |
| `_ChannelBadge` | lib/features/flows/all_executions_screen.dart:2842 |
| `_TopbarChip` | lib/features/flows/all_executions_screen.dart:2887 |
| `_CatalogRow` | lib/features/catalogs/catalogs_screen.dart:379 |
| `_SourceBadge` | lib/features/catalogs/catalogs_screen.dart:548 |
| `_SyncStatusBadge` | lib/features/catalogs/catalogs_screen.dart:580 |
| `_FieldRow` | lib/features/flows/flow_detail_screen.dart:958 |
| `_ConditionCard` | lib/features/flows/flow_detail_screen.dart:2465 |
| `_ActionCard` | lib/features/flows/flow_detail_screen.dart:3091 |
| `_RuleCard` | lib/features/flows/flow_detail_screen.dart:4401 |
| `_LegacyFieldsCard` | lib/features/flows/execution_detail_screen.dart:1008 |
| `_AssetsAttachedCard` | lib/features/flows/execution_detail_screen.dart:1086 |
| `_EventRow` | lib/features/flows/execution_detail_screen.dart:1317 |
| `_SmallBadge` | lib/features/flows/widgets/field_card.dart:167 |
| `_SourceCard` | lib/features/catalogs/new_catalog_wizard.dart:1525 |
| `_FieldRow` | lib/features/catalogs/new_catalog_wizard.dart:1748 |
| `_SummaryRow` | lib/features/catalogs/new_catalog_wizard.dart:2142 |
| `_IntegrationCard` | lib/features/flows/flow_integrations_screen.dart:338 |
| `_StatusChip` | lib/features/flows/flow_integrations_screen.dart:870 |
| `_OutboundEndpointRow` | lib/features/flows/flow_integrations_screen.dart:895 |
| `_NotifCard` | lib/features/auth/login_screen.dart:513 |
| `_SyncStatusBadge` | lib/features/catalogs/catalog_detail_screen.dart:475 |
| `_FieldSchemaCard` | lib/features/catalogs/catalog_detail_screen.dart:956 |
| `_OAuthStateBadge` | lib/features/catalogs/catalog_detail_screen.dart:1476 |
| `_ConfigRow` | lib/features/catalogs/catalog_detail_screen.dart:1535 |
| `_DetailRow` | lib/features/catalogs/catalog_detail_screen.dart:1996 |
| `_KpiRow` | lib/features/sessions/sessions_screen.dart:162 |
| `_SessionKpiCard` | lib/features/sessions/sessions_screen.dart:221 |
| `_KpiRow` | lib/features/overview/overview_screen.dart:175 |
| `_MiniMetricChip` | lib/features/overview/overview_screen.dart:636 |
| `_OpChip` | lib/features/overview/overview_screen.dart:1056 |

*(Lista completa: 206+ clases — solo se muestran las primeras 40)*

---

### Shared widgets existentes

> Archivos actuales en `lib/shared/` — 5 archivos.

```
lib/shared/widgets/app_shell.dart
lib/shared/widgets/asset_item_selector.dart
lib/shared/widgets/operator_avatar.dart
lib/shared/widgets/page_header.dart
lib/shared/widgets/screen_header.dart
```
