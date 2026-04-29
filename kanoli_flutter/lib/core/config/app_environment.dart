enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment fromDartDefine() {
    const env = String.fromEnvironment('KANOLI_ENV', defaultValue: 'dev');

    switch (env.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.dev;
    }
  }
}
