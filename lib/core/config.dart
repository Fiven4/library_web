const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

const apiDefaultToken = String.fromEnvironment('API_TOKEN', defaultValue: '');
