{ ... }:
{
  _file = "fixture:service-product-overlay";
  config.desiredLifecycle = {
    maxRestarts = 10;
    reconcileIntervalSeconds = 30;
  };
}
