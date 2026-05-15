/// Activar con --dart-define=MOCK_MODE=true para datos simulados.
const kMockMode = bool.fromEnvironment('MOCK_MODE', defaultValue: false);

/// Usuario simulado cuando [kMockMode] es true.
const kMockEmail = 'supervisor@conectamos.mx';
const kMockTenant = 'Demo Tenant';
const kMockRole = 'supervisor';
