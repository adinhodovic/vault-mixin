# Prometheus Monitoring Mixin for Vault

A set of Grafana dashboards and Prometheus alerts for [HashiCorp Vault](https://github.com/hashicorp/vault).

## How to use

This mixin is designed to be vendored into the repo with your infrastructure config. To do this, use [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler):

You then have three options for deploying your dashboards

1. Generate the config files and deploy them yourself
2. Use jsonnet to deploy this mixin along with Prometheus and Grafana
3. Use prometheus-operator to deploy this mixin

Or import the dashboard using json in `./dashboards_out`, alternatively import them from the `Grafana.com` dashboard page.

## Generate config files

You can manually generate the alerts, dashboards and rules files, but first you must install some tools:

```sh
go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
brew install jsonnet
```

Then, grab the mixin and its dependencies:

```sh
git clone https://github.com/adinhodovic/vault-mixin
cd vault-mixin
jb install
```

Finally, build the mixin:

```sh
make prometheus_alerts.yaml
make dashboards_out
```

The `prometheus_alerts.yaml` file then need to passed to your Prometheus server, and the files in `dashboards_out` need to be imported into you Grafana server. The exact details will depending on how you deploy your monitoring stack.

## Scraping Vault

Vault's metrics endpoint is `/v1/sys/metrics?format=prometheus` on the API port (default `8200`). Set `telemetry { unauthenticated_metrics_access = true }` in the Vault config so Prometheus can scrape it.

Some dashboard panels use Vault telemetry gauges that are emitted only when the corresponding Vault features are configured. Token breakdown panels require token usage gauge collection, and audit log panels require Vault audit telemetry metrics.

### ServiceMonitor (prometheus-operator)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vault
  namespace: vault
  labels:
    app.kubernetes.io/name: vault
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: vault
  endpoints:
    - port: http
      path: /v1/sys/metrics
      params:
        format: ["prometheus"]
      scheme: http
      interval: 30s
      scrapeTimeout: 10s
      metricRelabelings:
        # Rename Vault's built-in `cluster` label (set to its internal
        # cluster_name) to `exported_cluster` so it does not collide with the
        # Prometheus external `cluster` label used by other mixins.
        - sourceLabels: [cluster]
          targetLabel: exported_cluster
          action: replace
        - regex: ^cluster$
          action: labeldrop
```

## Runtime metrics

The Runtime row on the overview dashboard surfaces just the high-signal Go runtime metrics (memory, goroutines, GC, allocations, process I/O, cache hit rate). For an in-depth view of Go runtime internals (CPU, memory, GC, scheduling, contention, file descriptor pressure), pair this dashboard with the [Go / Overview dashboard](https://grafana.com/grafana/dashboards/25063-go-overview/) from the [go-mixin](https://github.com/adinhodovic/go-mixin) project.

## Multi-cluster setups

Vault emits a built-in `cluster` label set to its internal `cluster_name`. When the Prometheus scrape config injects its own `cluster` external label (the typical multi-cluster mixin pattern), Prometheus renames Vault's built-in label to `exported_cluster`.

The mixin handles this automatically: `vaultClusterLabel` defaults to `exported_cluster` when `showMultiCluster` is `true`, and to `cluster` otherwise. Override `_config.vaultClusterLabel` if your scrape config relabels differently (for example via `honor_labels: true` or `metric_relabel_configs`). See the `metricRelabelings` block in the ServiceMonitor example above for a concrete relabel to `exported_cluster`.

## Alerts

The mixin follows the [monitoring-mixins guidelines](https://github.com/monitoring-mixins/docs#guidelines-for-alert-names-labels-and-annotations) for alerts.

The following alerts are included:

- `VaultSealed` — fires when a Vault instance is sealed.
- `VaultTooManyInfinityTokens` — fires when too many tokens have an infinite TTL.
- `VaultAutopilotUnhealthy` — fires when Vault Autopilot reports the cluster as unhealthy.
- `VaultNoActiveNode` — fires when no active Vault node is reported for a cluster.
- `VaultLowResponseSuccessRate` — fires when Vault returns too many 5xx responses.
- `VaultRaftFSMPendingHigh` — fires when Raft FSM pending operations are high.
- `VaultAuditFailures` — fires when audit request or response logging failures occur.
