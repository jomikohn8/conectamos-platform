# BASE DE DATOS — Conectamos

> **Propósito:** Estado actual del esquema, migrations aplicadas y convenciones. Consultar **antes** de proponer cualquier cambio de esquema.
> **Regla del proyecto:** Todo cambio de BD debe tener su migration correspondiente. Sin migration, el cambio no existe — salvo excepciones marcadas abajo.
> **Fuente de verdad del schema:** `information_schema.columns` del proyecto Supabase `atqmtsmjpjtrqooibubm`, consultado 2026-04-26.

---

## 1. Motor y entorno

- **Motor:** PostgreSQL (Supabase managed)
- **Project ID:** `atqmtsmjpjtrqooibubm`
- **ORM / cliente:** Supabase Python SDK (backend) + Supabase Flutter SDK (frontend cuando aplica; la mayoría migrada a backend vía ADR-060)
- **Hosting:** Supabase Cloud
- **Entornos:** prod único — sin staging separado al momento. Dev local contra el mismo proyecto de Supabase.
- **Migration path:** archivos `.sql` versionados en `conectamos_meta_api/supabase/migrations/`. **Aplicación manual** vía Supabase SQL Editor (no hay runner automático).

---

## 2. Convenciones

- **Nombres de tablas:** `snake_case` plural (`tenants`, `operators`, `wa_messages`).
- **Nombres de columnas:** `snake_case`.
- **Llaves primarias:** `uuid` con `gen_random_uuid()` por defecto (casos recientes); algunas tablas legacy con `bigint`.
- **Timestamps:** `created_at`, `updated_at` como `timestamptz` con UTC explícito (`timezone.utc` desde Python).
- **Foreign keys:** `<tabla>_id` — ej. `operator_id`, `tenant_id`, `channel_id`.
- **JSONB:** para configuración flexible (`variables`, `segment_filters`, `fields_status`, `channel_config`).
- **Deprecación en BD:** columnas deprecadas se renombran con prefijo `_deprecated_` antes de eliminarse, para romper referencias en código a tiempo de compilación.
- **RLS:** activo en `wa_messages`, `operators`, `operator_flows`, `operator_field_definitions`, `escalations`, `supervisor_channel_access` (ver nota), `telegram_linking_tokens`.

---

## 3. Esquema actual (tablas principales)

> ⚠️ **Verificado contra `information_schema` el 2026-04-26.** Columnas marcadas con `[PROD-DIFF]` difieren del schema documentado anteriormente.

### `tenants`
- **Propósito:** Organización cliente de Conectamos.
- **Columnas reales en prod:** `id uuid PK`, `slug text UNIQUE NOT NULL`, `display_name text NOT NULL`, `legal_name text`, `address text` [PROD-DIFF: campo adicional junto a los campos individuales], `logo_url text`, `status text DEFAULT 'active'` [PROD-DIFF: sin documentar antes], `wa_phone_number_id text`, `wa_waba_id text`, `wa_token text`, `created_at timestamptz`, `rfc text`, `email_contacto text`, `telefono text`, `calle text`, `numero_exterior text`, `numero_interior text`, `colonia text`, `ciudad text`, `estado_cliente text`, `codigo_postal text`, `requiere_cfdi bool DEFAULT false`, `regimen_fiscal text`, `uso_cfdi text`, `welcome_template_id uuid`, `show_supervisor_name bool DEFAULT false`, `operator_export_config jsonb`.
- **Notas:** Las columnas `wa_*` son transitorias — migrarán a `channels` en migración 000002. `operator_export_config` define qué columnas aparecen en el export de operadores, configurable por admin. Migration `20260423000001`.

### `tenant_users`
- **Propósito:** Usuarios de la plataforma (panel web) por tenant.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `user_id uuid` (auth.users, nullable), `role_id uuid NOT NULL`, `status text DEFAULT 'invited'`, `invited_by uuid` [PROD-DIFF: sin documentar antes], `created_at timestamptz`, `nombre text`, `telefono text`.
- **Notas:** Tabla M:N entre `auth.users` y `tenants`. `nombre` y `telefono` se sincronizan con `auth.users.user_metadata` al aceptar invitación. Históricamente algunos `nombre` quedaron `NULL` — se corrigieron manualmente 2026-04-17.

### `user_roles` [LEGACY]
- **Propósito:** Superadmin/admin global (diferente de `tenant_users`).
- **Columnas reales en prod:** `id uuid PK`, `user_id uuid`, `tenant_id uuid`, `role text`, `created_at timestamptz`.
- **Estado:** Sin uso en el código actual. Superseded por `tenant_users + roles`. Candidato a DROP.

### `roles`
- **Propósito:** Roles del sistema por tenant.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid`, `name text`, `description text`, `is_system bool DEFAULT false`, `created_at timestamptz`.
- **Notas:** 3 roles por tenant (`admin`, `supervisor`, `viewer`) creados por `_seed_system_roles()` en `POST /tenants` (no por migration — migration solo sembró a tenants existentes al momento de su aplicación).

### `permissions`
- **Propósito:** Catálogo global de permisos.
- **Columnas reales en prod:** `id uuid PK`, `module text NOT NULL`, `action text NOT NULL`, `description text`.
- **Notas:** Formato de nombre: `module.action` (ej. `escalations.view`, `escalations.manage`). 13 permisos en seed inicial + 2 de escalaciones (migration 31).

### `role_permissions`
- **Propósito:** Join M:N entre roles y permisos.
- **Columnas reales en prod:** `role_id uuid`, `permission_id uuid`.
- **Notas:** 52 registros iniciales (admin 13, supervisor 7, viewer 6). Sin PK explícita — PK compuesta implícita.

### `invitations`
- **Propósito:** Tokens de invitación a usuarios de plataforma.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid`, `email text NOT NULL`, `role_id uuid NOT NULL`, `token uuid UNIQUE DEFAULT gen_random_uuid()`, `expires_at timestamptz DEFAULT now()+7d`, `accepted_at timestamptz`, `invited_by uuid` [PROD-DIFF: sin documentar antes], `created_at timestamptz`, `nombre text`, `telefono text`.
- **Notas:** `accepted_at NULL` = pendiente.

### `operators`
- **Propósito:** Operadores de campo del tenant.
- **Columnas reales en prod:** `id uuid PK`, `name text NOT NULL` (**nota: `name`, no `nombre`**), `phone text NOT NULL`, `whatsapp_verified bool DEFAULT false` [PROD-DIFF: sin documentar antes], `status text DEFAULT 'inactive'` (active/suspended/inactive/deleted — CHECK), `last_event_at timestamptz` [PROD-DIFF: sin documentar antes], `created_at timestamptz`, `tenant_id uuid`, `_deprecated_ai_worker_id uuid`, `_deprecated_ai_enabled bool DEFAULT false`, `metadata jsonb NOT NULL DEFAULT '{}'`, `email text`, `profile_picture_url text`, `nationality text` (ISO 3166-1 alpha-2), `identity_type text` (CHECK), `identity_number text`, `created_by uuid`, `updated_at timestamptz`, `updated_by uuid`.
- **Unicidad:** `(tenant_id, phone)` — no global. Partial unique index `operators_identity_unique` sobre `(tenant_id, identity_type, identity_number)` cuando ambos no son NULL.
- **Notas:** Los campos `_deprecated_*` serán eliminados cuando la migración a `operator_flows` esté completa. `metadata` almacena: `telegram_chat_id` (string), `telegram_link_status` (none/pending/linked), `telegram_link_expires_at`, `phone_secondary[]` (`{label, number, channel}`), y valores de `operator_field_definitions`. Claves reservadas: ver ADR-135. `created_by` y `updated_by` están en BD pero nunca se escriben desde backend (null). Columna legacy `flows` (array) eliminada via migration `20260422000000`.

### `_deprecated_operator_channels` [RENOMBRADA — EN DEPRECACIÓN]
- **Columnas reales en prod:** `id uuid PK`, `operator_id uuid NOT NULL`, `channel_id uuid NOT NULL`, `tenant_id uuid NOT NULL`, `granted_at timestamptz DEFAULT now()`, `granted_by uuid`.
- **Estado:** RENAME de `operator_channels` (migration `20260418000001`). DROP diferido hasta confirmar migración completa a `operator_flows`. El código backend apunta a `_deprecated_operator_channels`; frontend ya no la usa directamente.

### `operator_flows` [NUEVA]
- **Propósito:** Fuente de verdad de asignación operador ↔ flujo. Reemplaza `_deprecated_operator_channels`.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid`, `operator_id uuid`, `flow_definition_id uuid`, `assigned_at timestamptz DEFAULT now()` [PROD-DIFF: sin documentar antes], `assigned_by_user_id uuid` [PROD-DIFF: sin documentar antes], `is_active bool DEFAULT true` [PROD-DIFF: sin documentar antes].
- **Unicidad:** `UNIQUE(operator_id, flow_definition_id)`.
- **Notas:** RLS habilitado. Migration `20260418000001_operator_flows_and_fields.sql`.

### `operator_field_definitions` [NUEVA]
- **Propósito:** Campos configurables por tenant para la ficha del operador.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid`, `field_key text NOT NULL`, `label text NOT NULL` [PROD-DIFF: el MD anterior decía `field_label` — el nombre real en prod es `label`], `field_type text NOT NULL`, `required bool DEFAULT false`, `display_order int DEFAULT 0` [PROD-DIFF: el MD anterior decía `sort_order` — el nombre real en prod es `display_order`], `options jsonb`, `is_active bool DEFAULT true`, `created_at timestamptz`.
- **Unicidad:** `UNIQUE(tenant_id, field_key)`.
- **Notas:** RLS habilitado. Valores almacenados en `operators.metadata`. Migration `20260418000001`. DELETE es soft delete (`is_active=false`). CRUD completo en `app/routers/operator_fields.py`. **Importante:** los nombres de columna `label` y `display_order` difieren de lo que el MD anterior documentaba — verificar que el código use los nombres reales.

### `channels`
- **Propósito:** Conexión entre un tenant_worker y un canal de mensajería (WhatsApp, Telegram, SMS).
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `channel_type text DEFAULT 'whatsapp'` (whatsapp/telegram/sms), `display_name text NOT NULL` [PROD-DIFF: sin documentar antes], `color text`, `channel_config jsonb NOT NULL DEFAULT '{}'`, `is_active bool DEFAULT true`, `created_at timestamptz`, `updated_at timestamptz`, `tenant_worker_id uuid`, `signup_source varchar(20) DEFAULT 'manual'`.
- **`signup_source` valores:** `'manual'` | `'embedded_signup'`. Migration `20260421000003`.
- **`channel_config` estructura WhatsApp:** `{channel_type, credentials{phone_number_id, waba_id, access_token}, capabilities[]}`.
- **`channel_config` estructura Telegram:** `{channel_type, credentials{bot_token, bot_username}, capabilities[]}`.
- **Notas:** Las columnas top-level `phone_number_id`, `waba_id`, `wa_token` fueron dropeadas (migrations `20260420000001` y `20260420000002`). Credenciales viven exclusivamente en `channel_config.credentials`. Canal con historial (`wa_messages` o `flow_executions`) no permite editar credenciales — `PATCH` retorna 409 (ver ADR-094). `access_token`/`bot_token` enmascarados como `"••••••••"` por `_mask_channel_token()`. Nunca se devuelven en claro.

### `ai_worker_catalog`
- **Propósito:** Catálogo global de Workers gestionado por Conectamos.
- **Columnas reales en prod:** `id uuid PK`, `name text NOT NULL`, `description text`, `worker_type text NOT NULL`, `webhook_url text`, `color text`, `icon_url text` [PROD-DIFF: sin documentar antes], `skills text[] DEFAULT '{}'`, `is_published bool DEFAULT false`, `is_active bool DEFAULT true` [PROD-DIFF: sin documentar antes], `sort_order int DEFAULT 0` [PROD-DIFF: sin documentar antes], `created_at timestamptz`, `updated_at timestamptz`.
- **Nota:** `visible_to_all` y `worker_catalog_tenant_visibility` **no existen en prod** (migration `20260420000003` fue revertida o nunca aplicada — ADR-100). El código `list_catalog_workers` no depende de ellas.
- **Seed real (migration `20260421000001`):** `Worker paquetería` (is_published: true), `Worker transporte` (is_published: true), `Worker ventas` (is_published: true), `Worker cobranza` (is_published: false).

### `worker_catalog_tenant_visibility` [NO EXISTE EN PROD]
- **Estado:** Documentada en migration `20260420000003` pero **confirmado que no existe en prod** vía `information_schema` 2026-04-26. Código reescrito sin ella (ADR-100). No crear ni referenciar.

### `tenant_workers`
- **Propósito:** Contratación de Workers del catálogo por un tenant.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `catalog_worker_id uuid NOT NULL`, `display_name text`, `is_active bool DEFAULT true` [PROD-DIFF: sin documentar antes], `contracted_at timestamptz DEFAULT now()` [PROD-DIFF: sin documentar antes], `contracted_by uuid` [PROD-DIFF: sin documentar antes], `metadata jsonb DEFAULT '{}'` [PROD-DIFF: sin documentar antes].
- **Unicidad:** `UNIQUE(tenant_id, catalog_worker_id)`.

### `ai_workers` [EN DEPRECACIÓN]
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `name text NOT NULL`, `routing_key text NOT NULL`, `is_active bool DEFAULT true`, `metadata jsonb DEFAULT '{}'`, `created_at timestamptz`, `worker_type text DEFAULT 'custom'`, `webhook_url text`, `color text`.
- **Estado:** Siendo reemplazada gradualmente por `ai_worker_catalog + tenant_workers`. Mantener por ahora.

### `flow_definitions`
- **Propósito:** Plantilla de flujo configurable por tenant sobre un `tenant_worker`.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `name text NOT NULL`, `description text`, `fields jsonb NOT NULL DEFAULT '[]'`, `behavior jsonb NOT NULL DEFAULT '{}'` [PROD-DIFF: el MD anterior decía `mode (abierto/cerrado)` — en prod es `behavior jsonb`], `on_complete jsonb` [PROD-DIFF: sin documentar antes], `is_active bool DEFAULT true`, `sort_order int DEFAULT 0`, `created_at timestamptz`, `updated_at timestamptz`, `tenant_worker_id uuid`.
- **Nota [PROD-DIFF]:** Las columnas `mode` y `permissions jsonb` mencionadas en documentación anterior **no existen en prod**. Fueron reemplazadas por `behavior` y `on_complete`.
- **Unicidad:** `UNIQUE(tenant_id, tenant_worker_id, name)`.

### `flow_executions`
- **Propósito:** Instancia activa de un `flow_definition` para un operador específico.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `flow_definition_id uuid NOT NULL`, `operator_id uuid NOT NULL`, `channel_id uuid NOT NULL`, `status text DEFAULT 'active'` (active/in_progress/paused/completed/abandoned/escalated — CHECK actualizado en migration 30), `fields_status jsonb DEFAULT '{}'`, `attempts jsonb DEFAULT '{}'` [PROD-DIFF: sin documentar antes], `completed_at timestamptz`, `escalated_at timestamptz` [PROD-DIFF: sin documentar antes], `escalated_to uuid` [PROD-DIFF: sin documentar antes], `created_at timestamptz`, `updated_at timestamptz`, `active_channel_id uuid FK→channels` (nullable — canal activo actual del operador).
- **Índice especial:** Partial unique `idx_flow_executions_unique_active` previene dos ejecuciones activas del mismo flow por operador.
- **Bug activo:** código no verifica existencia antes de INSERT → `duplicate key` error (ID-002).
- **Notas:** `active_channel_id` se actualiza si el operador migra de canal durante un flujo activo (ADR-139). Threshold de inactividad para `status='paused'` sin definir aún (ID-074).

### `flow_field_values`
- **Propósito:** Valores capturados por el AI Worker para cada campo de un `flow_execution`.
- **Columnas reales en prod:** `id uuid PK`, `execution_id uuid NOT NULL FK→flow_executions`, `tenant_id uuid NOT NULL`, `field_key text NOT NULL`, `value_text text`, `value_numeric numeric`, `value_jsonb jsonb`, `value_media_url text`, `captured_at timestamptz DEFAULT now()`, `wa_message_id uuid`.
- **Notas:** UPSERT desde `_save_field_values()` en `ai_worker_events.py`. Tipado automático: número → `value_numeric`, URL → `value_media_url`, dict/list → `value_jsonb`, resto → `value_text`. Activo desde commit c046cd5 (2026-04-26).

### `flow_events`
- **Propósito:** Historial de hitos del ciclo de vida de los flujos.
- **Columnas reales en prod:** `id uuid PK`, `session_id uuid`, `operator_id uuid`, `flow_number int NOT NULL`, `flow_name text`, `event_id text`, `status text DEFAULT 'open'`, `data jsonb DEFAULT '{}'`, `created_at timestamptz`, `updated_at timestamptz`, `tenant_id uuid` [PROD-DIFF: sin documentar antes].
- **Notas:** INSERT desde `_save_flow_event()` en `ai_worker_events.py`. Activo desde commit c046cd5. Tipos definidos: `flujo_iniciado | campo_capturado | campo_rechazado | supervisor_intervino | flujo_pausado | flujo_retomado | worker_escaló | ticket_asignado | ticket_resuelto | ticket_reabierto | flujo_completado | flujo_abandonado`.

### `escalations` [NUEVA]
- **Propósito:** Tickets de escalación generados cuando el AI Worker no puede completar un flujo (`checkpoint_incomplete`).
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `flow_execution_id uuid NOT NULL FK→flow_executions`, `operator_id uuid NOT NULL FK→operators`, `reason text NOT NULL`, `trigger_messages jsonb NOT NULL DEFAULT '[]'` [PROD-DIFF: el MD anterior decía `UUID[]` — en prod es `jsonb`], `status text DEFAULT 'open'` (open/assigned/resolved/reopened — CHECK), `opened_at timestamptz DEFAULT now()` [PROD-DIFF: sin documentar antes], `assigned_to uuid FK→tenant_users`, `assigned_at timestamptz` [PROD-DIFF: sin documentar antes], `resolved_at timestamptz`, `resolved_by uuid` [PROD-DIFF: sin documentar antes], `resolution_notes text` [PROD-DIFF: sin documentar antes], `worker_can_resume bool DEFAULT false`, `resumed_at timestamptz` [PROD-DIFF: sin documentar antes], `created_at timestamptz`, `updated_at timestamptz` (trigger automático).
- **Nota [PROD-DIFF]:** La columna `channel_id FK→channels` mencionada en el MD anterior **no existe en prod**.
- **Notas:** RLS habilitada. 7 índices incluyendo compuesto `(tenant_id, status)`. Permisos: `escalations.view` y `escalations.manage`. Migration `20260424000001`. Migration `20260424000002` para seed de permisos. ADR-143.

### `supervisor_channel_access` [⚠️ VERIFICAR — NO APARECE EN PROD]
- **Propósito documentado:** Controla qué canales puede ver cada `tenant_user` con rol supervisor o viewer.
- **Estado:** Migration `20260420000004_supervisor_channel_access.sql` existe en el repo, **pero la tabla no aparece en `information_schema` al 2026-04-26**. Verificar si la migration fue aplicada. Si no existe, el endpoint `/supervisor-channel-access` retorna error 500.

### `telegram_linking_tokens` [NUEVA]
- **Propósito:** Tokens UUID de un solo uso para vincular a un operador con su `telegram_chat_id` via deep link.
- **Columnas reales en prod:** `id uuid PK`, `token uuid UNIQUE DEFAULT gen_random_uuid()`, `operator_id uuid NOT NULL FK→operators CASCADE`, `channel_id uuid NOT NULL FK→channels CASCADE`, `tenant_id uuid NOT NULL FK→tenants CASCADE`, `expires_at timestamptz NOT NULL`, `used_at timestamptz`, `created_at timestamptz DEFAULT now()`.
- **Notas:** RLS habilitado. Índices sobre `token` (unique), `operator_id`, `(channel_id, used_at)`. Migration `20260421000002`. Backend valida token no usado y no expirado antes de persistir `telegram_chat_id` en `operators.metadata`.

### `sessions`
- **Columnas reales en prod:** `id uuid PK`, `operator_id uuid`, `operator_phone text`, `operator_name text`, `status text DEFAULT 'open'`, `started_at timestamptz`, `closed_at timestamptz`, `checklist_completed bool DEFAULT false`, `created_at timestamptz`, `tenant_id uuid NOT NULL`.
- **Estado:** Tabla creada en migración 000008. Usada parcialmente — `sessions.status` CHECK solo permite `'open'|'closed'` pero código busca `status='supervisor'`. Evaluar agregar `'supervisor'` al CHECK o documentar como en desuso para intervención.

### `wa_messages`
- **Propósito:** Mensajes WhatsApp y Telegram (inbound y outbound).
- **Columnas reales en prod:** `id uuid PK`, `chat_id text`, `wa_message_id text` (wamid), `from_phone text`, `from_name text`, `message_type text`, `raw_body text`, `raw_payload jsonb DEFAULT '{}'` [PROD-DIFF: sin documentar antes], `is_processed bool DEFAULT false`, `processed_at timestamptz`, `parse_error text`, `received_at timestamptz DEFAULT now()` (campo de timestamp para ordenamiento), `chat_name text` [PROD-DIFF: sin documentar antes], `operator_id uuid`, `session_id uuid`, `flow_number int`, `direction text DEFAULT 'inbound'`, `wa_status text DEFAULT 'pending'`, `status_updated_at timestamptz`, `error_code text`, `error_message text`, `unregistered bool DEFAULT false`, `tenant_id uuid`, `media_url text`, `media_type text`, `sent_by_user_id uuid`, `origin text DEFAULT 'human'` (human/ai_worker/broadcast), `ai_worker_id uuid` [PROD-DIFF: sin documentar antes], `routing_request_id text` [PROD-DIFF: sin documentar antes], `channel_id uuid`, `context_message_id text`, `context_from text` [PROD-DIFF: sin documentar antes], `reaction_emoji text` [PROD-DIFF: sin documentar antes], `reaction_message_id text` [PROD-DIFF: sin documentar antes], `_deprecated_reply_to_message_id uuid`, `reactions jsonb DEFAULT '{}'` (huérfano — candidato a DROP), `panel_read_at timestamptz`, `panel_read_by uuid FK→auth.users` [PROD-DIFF: migration 20260423000002 — sin documentar antes], `broadcast_id uuid FK→broadcasts`.
- **Nota [PROD-DIFF]:** La columna `to_phone` mencionada en notas del MD anterior **no existe en prod**.
- **Nota sobre origin:** Verificar si el CHECK `wa_messages_origin_check` incluye `'broadcast'` [REVISAR CON EQUIPO].
- **Nota sobre `is_processed`:** `is_processed=True` se actualiza en `webhook.py` después del INSERT usando `routing_request_id` (fix de race condition — ADR-141). Lógica de retry no implementada (ID-067).
- **Realtime:** publicado en `supabase_realtime`.

### `wa_templates`
- **Propósito:** Plantillas Meta sincronizadas a Supabase.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `meta_template_id text` [PROD-DIFF: sin documentar antes], `name text NOT NULL`, `category text NOT NULL`, `language text DEFAULT 'es'` [PROD-DIFF: sin documentar antes], `body_text text NOT NULL` [PROD-DIFF: sin documentar antes — el cuerpo del template se llama `body_text`, no `body`], `variables jsonb DEFAULT '[]'` (formato `[{slot, type, key}]`), `status text DEFAULT 'PENDING'`, `rejection_reason text` [PROD-DIFF: sin documentar antes], `is_welcome bool DEFAULT false` [PROD-DIFF: sin documentar antes], `created_at timestamptz`, `updated_at timestamptz`, `waba_id text`.
- **Columnas pendientes de migration:** `header_type VARCHAR`, `header_text TEXT`, `footer_text TEXT`, `buttons JSONB`. **Migration `20260425000000_add_template_components_to_wa_templates.sql` — NO creada ni aplicada (ID-062).** Los valores se envían correctamente a Meta pero no se persisten en Supabase.
- **Unicidad:** `UNIQUE(tenant_id, name)`.
- **Notas:** Templates son por WABA — dos canales del mismo WABA comparten templates (ADR-081). WABA activo: `1744815743186774`.

### `broadcasts`
- **Propósito:** Envíos masivos.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `sent_by_user_id uuid` [PROD-DIFF: el MD anterior decía `created_by_user_id`], `message_text text` [PROD-DIFF: el MD anterior decía `body`], `template_id uuid`, `template_variables jsonb DEFAULT '[]'` [PROD-DIFF: sin documentar antes], `segment_filters jsonb DEFAULT '{}'`, `recipient_count int DEFAULT 0`, `sent_count int DEFAULT 0`, `failed_count int DEFAULT 0`, `status text DEFAULT 'pending'` [PROD-DIFF: sin documentar antes], `created_at timestamptz`, `completed_at timestamptz` [PROD-DIFF: sin documentar antes].
- **Nota [PROD-DIFF]:** La columna `channel_id` mencionada en el MD anterior **no existe en prod** (ver ADR-080).
- **Notas:** Formalizada en `20260420000006`. `channel_id` se pasa como parámetro en la petición HTTP pero no se persiste en la tabla.

### `broadcast_recipients`
- **Propósito:** Destinatarios del broadcast con status individual.
- **Columnas reales en prod:** `id uuid PK`, `broadcast_id uuid NOT NULL`, `operator_id uuid`, `phone text NOT NULL`, `wa_message_id text`, `status text DEFAULT 'pending'` (pending/sent/delivered/read/failed), `error_message text`, `sent_at timestamptz`.
- **Notas:** Formalizada en `20260420000006`.

### `user_read_receipts`
- **Propósito:** Último `last_read_at` por usuario por chat.
- **Columnas reales en prod:** `id uuid PK`, `user_id uuid NOT NULL`, `tenant_id uuid NOT NULL`, `chat_id text NOT NULL`, `last_read_at timestamptz NOT NULL`.
- **Notas:** Formalizada en `20260420000006`.

---

## 4. Migrations aplicadas (historial)

> Ubicación: `conectamos_meta_api/supabase/migrations/`. Aplicación manual vía Supabase SQL Editor.

| # | Migration | Repo | Descripción |
|---|---|---|---|
| 1 | `20260407120000_initial.sql` | conectamos_meta_api | `wa_messages` inicial |
| 2 | `20260408000000_operators_sessions.sql` | conectamos_meta_api | `operators`, `sessions`, `flow_events`; columnas `operator_id`, `session_id`, `flow_number`, `direction` en `wa_messages` |
| 3 | `20260409000000_outbound_messages.sql` | conectamos_meta_api | `wa_status`, `status_updated_at`, `error_code`, `error_message` en `wa_messages` |
| 4 | `20260413000000_unregistered_column.sql` | conectamos_meta_api | `unregistered BOOLEAN` en `wa_messages` |
| 5 | `20260413100000_multitenancy.sql` | conectamos_meta_api | `tenants` (con todas las columnas WA/fiscales), `user_roles` (legacy) |
| 6 | `20260414000000_iam.sql` | conectamos_meta_api | `permissions`, `roles`, `role_permissions`, `tenant_users`, `invitations`; seed de 13 permisos, 3 roles sistema, 52 role_permissions |
| 7 | `20260415160310_remote_schema.sql` | conectamos_meta_api | `nombre`, `telefono` en `tenant_users` e `invitations` |
| 8 | `20260415200000_channels_tenant_worker.sql` | conectamos_meta_api | Índice sobre `channels.tenant_worker_id` |
| 9 | `20260415210000_flow_definitions_fix.sql` | conectamos_meta_api | UNIQUE restaurado + 3 índices de soporte en `flow_definitions` |
| 10 | `20260416000000_channels_and_flows.sql` | conectamos_meta_api | `channels`, `operator_channels`, `flow_definitions`, `flow_executions`, `flow_field_values`; `operators.ai_worker_id → _deprecated_*`; `worker_type`, `webhook_url`, `color` en `ai_workers`; `channel_id` en `wa_messages` |
| 11 | `20260416000003_worker_catalog.sql` | conectamos_meta_api | `ai_worker_catalog`, `tenant_workers`; `channels.tenant_worker_id`; `flow_definitions.tenant_worker_id`; seed de 3 Workers |
| 12 | `20260417000001_channel_config_restructure.sql` | conectamos_meta_api | Reestructura `channel_config` JSONB en `channels`; constraint CHECK validando estructura. |
| 13 | `20260418000001_operator_flows_and_fields.sql` | conectamos_meta_api | Crear `operator_flows`, `operator_field_definitions`; ADD `operators.metadata JSONB`; RENAME `operator_channels` → `_deprecated_operator_channels`. |
| 14 | `20260420000001_drop_channel_credential_columns.sql` | conectamos_meta_api | DROP `channels.phone_number_id` y `channels.waba_id`; índice GIN sobre `channel_config`. |
| 15 | `20260420000002_drop_channel_wa_token.sql` | conectamos_meta_api | DROP `channels.wa_token`. |
| 16 | `20260420000003_worker_catalog_updates.sql` | conectamos_meta_api | **[NO APLICADA O REVERTIDA]** Intentó ADD `visible_to_all`, CREATE `worker_catalog_tenant_visibility`. Ambas confirmadas como inexistentes en prod (ADR-100). Los cambios reales del catálogo se aplicaron en migration 20. |
| 17 | `20260420000004_supervisor_channel_access.sql` | conectamos_meta_api | CREATE `supervisor_channel_access`; RLS + 3 policies; índices por `tenant_user_id`, `channel_id`, `tenant_id`. **Aplicada manualmente el 2026-04-26** (la tabla no existía en prod — gap resuelto). |
| 18 | `20260420000005_backfill_wa_messages_channel_id.sql` | conectamos_meta_api | Backfill de 252 mensajes con `channel_id=NULL` al canal activo del tenant `conectamos-demo`. |
| 19 | `20260420000006_formalize_missing_migrations.sql` | conectamos_meta_api | Formalización idempotente de `user_read_receipts`, `wa_templates`, `broadcasts`, `broadcast_recipients`, RLS `wa_messages`, RLS `operators`, realtime `wa_messages`. |
| 20 | `20260421000001_add_skills_to_worker_catalog.sql` | conectamos_meta_api | UPDATE Worker logística → paquetería; INSERT Worker transporte con `skills text[]`. |
| 21 | `20260421000002_telegram_linking_tokens.sql` | conectamos_meta_api | CREATE `telegram_linking_tokens`; FK a operators, channels, tenants con CASCADE; RLS habilitado. |
| 22 | `20260421000003_add_signup_source_to_channels.sql` | conectamos_meta_api | ALTER TABLE channels ADD COLUMN IF NOT EXISTS `signup_source VARCHAR(20) NOT NULL DEFAULT 'manual'`. |
| 23 | `20260422000000_drop_operators_flows_legacy.sql` | conectamos_meta_api | DROP COLUMN `operators.flows` (array legacy). |
| 24 | `20260422000001_add_reply_to_telegram.sql` | conectamos_meta_api | ADD COLUMN `reply_to_message_id uuid FK` a `wa_messages`. Deprecada en la misma sesión. |
| 25 | `20260422000002_add_reactions_to_wa_messages.sql` | conectamos_meta_api | ADD COLUMN `reactions jsonb NOT NULL DEFAULT '{}'` a `wa_messages`. Columna huérfana — candidata a DROP. |
| 26 | `20260422120000_operators_sprint_fields.sql` | conectamos_meta_api | ADD COLUMNS `email`, `profile_picture_url`, `nationality`, `identity_type`, `identity_number`, `created_by`, `updated_at`, `updated_by` a `operators`. Partial unique index `operators_identity_unique`. Trigger `updated_at`. |
| 27 | `20260423000000_operators_status_add_deleted.sql` | conectamos_meta_api | Amplía CHECK de `operators.status` para incluir `'deleted'`. |
| 28 | `20260423000001_deprecate_reply_to_message_id.sql` | conectamos_meta_api | RENAME `reply_to_message_id` → `_deprecated_reply_to_message_id`. |
| 29 | `20260423000001_operator_export_config.sql` | conectamos_meta_api | ADD COLUMN `operator_export_config jsonb` a `tenants`. **Nota:** colisión de timestamp con migration 28 — deuda técnica. |
| 29b | `20260423000002_panel_read_wa_messages.sql` | conectamos_meta_api | ADD COLUMNS `panel_read_at TIMESTAMPTZ`, `panel_read_by UUID FK→auth.users` a `wa_messages`. Índice parcial `idx_wa_messages_panel_read` donde `panel_read_at IS NULL`. [PROD-DIFF: migration no documentada en el MD anterior] |
| 30 | `20260424000001_escalations.sql` | conectamos_meta_api | CREATE `escalations`; ADD `flow_executions.active_channel_id` UUID FK; CHECK de `status` extendido con `'paused'`; 7 índices; trigger `updated_at`; RLS. |
| 31 | `20260424000002_escalations_permissions.sql` | conectamos_meta_api | INSERT `escalations.view` y `escalations.manage` en `permissions`. |
| 32 | `20260425000001_wa_messages_broadcast_id.sql` | conectamos_meta_api | ADD COLUMN `broadcast_id uuid REFERENCES broadcasts(id)` nullable a `wa_messages`. Índice parcial WHERE `broadcast_id IS NOT NULL`. |

---

## 5. Cambios aplicados sin archivo de migration formal

> **IMPORTANTE:** deuda técnica pendiente de formalizar. Si se recrea la BD, estos cambios se pierden.

- ALTER TABLE `wa_templates` ADD COLUMN `waba_id TEXT` + UPDATE manual de filas existentes con WABA correspondiente.
- ALTER TABLE `wa_messages` ADD `media_url`, `media_type`, `sent_by_user_id`, `from_name`, `origin`.
- UPDATE de `tenant_users.nombre` donde era NULL (2026-04-17) — ver ADR-069.
- Operación manual: mover usuario `0b208d48` de "Jomi Prueba" a `4ea0c9d8` (conectamos-demo).
- Operación manual: DELETE de tenants de prueba `jomi-prueba` a `jomi-prueba-7` con CASCADE.
- UPDATE manual de `channel_config: {}` a estructura válida previo a migration `20260417000001` — no versionado formalmente.
- UPDATE manual: `phone` de Santiago Kohn corregido; `telegram_chat_id` de José Miguel Kohn corregido de int a string `"6224256977"`. Sin migration formal.
- Policies RLS INSERT y UPDATE en bucket `wa-media` de Supabase Storage para usuarios autenticados.
- UPDATE directo: `webhook_url` de Worker transporte (`abb17c7d`) en `ai_worker_catalog` actualizado a URL de ngrok de Gustavo — temporal (ID-070).
- INSERT directo: 6 flujos en `flow_definitions` para Worker transporte en `conectamos-demo`. `CREAR_VIAJE` posiblemente duplicado (ID-069).
- UPDATE directo: 2 `flow_executions` de prueba marcadas como `abandoned`.

---

## 6. Migrations pendientes / en revisión

- **`20260416000002_migrate_tenant_credentials.sql`** (placeholder existente) — DROP `wa_phone_number_id`, `wa_waba_id`, `wa_token` de `tenants`. Diferida hasta ADR-045. Backend ya no depende de estas columnas.
- **`20260420000004_supervisor_channel_access.sql`** — **VERIFICAR URGENTE** si fue aplicada en prod. La tabla `supervisor_channel_access` no aparece en `information_schema` al 2026-04-26. Si no fue aplicada, re-ejecutar en SQL Editor.
- DROP de `_deprecated_operator_channels` — diferido hasta confirmar que ningún código la referencia.
- Formalizar correcciones manuales de `phone` y `telegram_chat_id` como scripts de datos versionados.
- Evaluar DROP de `user_roles` legacy.
- Evaluar DROP de `sessions` y `flow_events` (tablas creadas pero con escasa integración real).
- Confirmar estado real de migration `20260420000003` en prod — si no fue aplicada, actualizar historial y marcar como NO APLICADA definitivamente.
- Eliminar endpoint temporal `POST /channels/backfill-telegram-usernames` en sprint siguiente.
- DROP de `reactions JSONB` en `wa_messages` — columna huérfana (candidata a DROP).
- DROP de `_deprecated_reply_to_message_id` en `wa_messages` — diferido hasta confirmar que ningún código la referencia.
- Resolver colisión de timestamp `20260423000001` (dos migrations con mismo timestamp).
- Implementar escritura de `created_by`/`updated_by` en backend al POST/PUT de operadores (ID-058).
- **`20260425000000_add_template_components_to_wa_templates.sql`** — pendiente de crear y aplicar. Columnas: `header_type`, `header_text`, `footer_text`, `buttons` (ID-062).
- Verificar si `origin='broadcast'` requiere actualizar CHECK constraint `wa_messages_origin_check` [REVISAR CON EQUIPO].
- Limpiar duplicado de `CREAR_VIAJE` en `flow_definitions` del tenant `conectamos-demo` (ID-069).
- Crear migration formal para asignar permisos `escalations.view` y `escalations.manage` a roles en seeds de `POST /tenants` (ID-064).
- Definir threshold de inactividad para `flow_executions.status = 'paused'` (ID-074).
- Agregar `'supervisor'` al CHECK de `sessions.status` o documentar `sessions` como en desuso.
- Lógica de retry con `is_processed` — columnas existen, falta el proceso de reintento (ID-067).

---

## 7. Áreas sensibles — cambios prohibidos sin aprobación

- `tenants.wa_token`, `wa_phone_number_id`, `wa_waba_id` — columnas legacy en `tenants`. El código ya no las usa; pendiente DROP físico (migration 000002). No modificar hasta ejecutar la migration.
- `channels.channel_config.credentials.access_token` — credencial Meta activa. Nunca devolver en claro en API (usar `_mask_channel_token()`). Para cambiar credenciales de canal con historial: desactivar y crear canal nuevo (ver ADR-094).
- `tenants.rfc`, `regimen_fiscal`, `uso_cfdi`, `email_contacto` — datos fiscales con impacto legal/facturación.
- `wa_messages` — históricos operativos. No DELETE masivo; soft delete preferido.
- `invitations.token` — no regenerar tokens activos.

---

## 8. Historial de actualizaciones del documento

| Fecha | Quién | Qué se actualizó |
|---|---|---|
| 2026-04-17 | Miguel Kohn | Consolidación inicial desde 11 conversaciones. Schema completo registrado. |
| 2026-04-20 | Miguel Kohn | Schema actualizado: `channels` sin columnas top-level; 8 migrations nuevas (12–19); nuevas tablas `operator_flows`, `operator_field_definitions`, `supervisor_channel_access`, `worker_catalog_tenant_visibility`. |
| 2026-04-21 | Miguel Kohn | `channels` con `signup_source`; `ai_worker_catalog` corregido; nueva tabla `telegram_linking_tokens`; migrations 20–23. |
| 2026-04-24 | Miguel Kohn | `operators` con columnas nuevas (sprint 04-23); migrations 24–29. |
| 2026-04-26 | Miguel Kohn | Nueva tabla `escalations`; `flow_executions` con `active_channel_id`; `wa_messages` con `broadcast_id`; migrations 30–32. |
| 2026-04-26 | Claude (Cowork) | **Verificación contra `information_schema` real de Supabase.** Corregidos ~20 PROD-DIFF: nombres de columna incorrectos (`field_label`→`label`, `display_order`, `message_text`, `sent_by_user_id`, `behavior`), columnas inexistentes en prod (`channel_id` en broadcasts/escalations, `mode`/`permissions` en flow_definitions), columnas sin documentar (`icon_url`, `whatsapp_verified`, `display_name` en channels, `raw_payload`, `chat_name`, `context_from`, etc.), migration faltante `20260423000002_panel_read_wa_messages.sql`, alerta sobre `supervisor_channel_access` posiblemente no aplicada. |
