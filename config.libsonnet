{
  _config+:: {
    local this = self,

    vaultSelector: 'job=~".*vault.*"',

    // Default datasource name
    datasourceName: 'default',

    // Opt-in to multiCluster dashboards by overriding this and the clusterLabel.
    showMultiCluster: false,
    clusterLabel: 'cluster',
    // Vault emits built-in `cluster` and `namespace` labels (set to its
    // internal cluster_name and Vault namespace, e.g. "root"). When the
    // Prometheus scrape config injects external labels of the same name (the
    // typical k8s mixin pattern), Prometheus renames Vault's built-in labels
    // to `exported_cluster` / `exported_namespace`. Default to the exported_*
    // form when showMultiCluster is enabled, otherwise the native names.
    vaultClusterLabel: if this.showMultiCluster then 'exported_cluster' else 'cluster',
    vaultNamespaceLabel: if this.showMultiCluster then 'exported_namespace' else 'namespace',

    // Synthetic /v1/sys/health probing. Vault's /v1/sys/metrics endpoint stops
    // responding on sealed or uninitialized nodes, so `up == 0` cannot tell a
    // dead node from a sealed one. A probe (blackbox_exporter, OpenTelemetry
    // httpcheck, Grafana Alloy) against /v1/sys/health reports the node state
    // as an HTTP status code: 200 active, 429 standby, 472 DR secondary,
    // 473 performance standby, 501 uninitialized, 503 sealed.
    // The health alerts and dashboard row show nothing until probe series
    // exist. Set dashboardEnabled to false to hide the row.
    healthProbe: {
      dashboardEnabled: true,
      // Probe series usually come from a different job than the metrics scrape.
      selector: this.vaultSelector,
      // Gauge holding the HTTP status code returned by /v1/sys/health.
      statusCodeMetric: 'vault_health_status_code',
      // 1 when the probe got an HTTP response, whatever the status code.
      upMetric: 'vault_health_up',
    },

    grafanaUrl: 'https://grafana.com',

    dashboardIds: {
      'vault-overview': 'vault-overview-skj2',
    },
    dashboardUrls: {
      'vault-overview': '%s/d/%s/vault-overview' % [this.grafanaUrl, this.dashboardIds['vault-overview']],
    },

    tags: ['vault', 'vault-mixin'],

    // Vault alert configuration
    alerts: {
      enabled: true,

      sealed: {
        enabled: true,
        severity: 'critical',
        interval: '0m',
      },

      tooManyInfinityTokens: {
        enabled: true,
        severity: 'warning',
        interval: '5m',
        threshold: '3',  // number of tokens with creation_ttl="+Inf"
      },

      autopilotUnhealthy: {
        enabled: true,
        severity: 'critical',
        interval: '5m',
      },

      noActiveNode: {
        enabled: true,
        severity: 'critical',
        interval: '5m',
      },

      lowResponseSuccessRate: {
        enabled: true,
        severity: 'warning',
        interval: '5m',
        threshold: '95',  // percent of non-5xx responses
        minErrors: '1',  // 5xx responses per second
      },

      raftFSMPendingHigh: {
        enabled: true,
        severity: 'warning',
        interval: '5m',
        threshold: '100',
      },

      auditFailures: {
        enabled: true,
        severity: 'warning',
        interval: '5m',
        threshold: '0',
      },

      // The alerts below use the healthProbe metrics.
      nodeSealed: {
        enabled: true,
        severity: 'critical',
        interval: '1m',
      },

      nodeUninitialized: {
        enabled: true,
        severity: 'warning',
        interval: '5m',
      },

      instanceUnreachable: {
        enabled: true,
        severity: 'critical',
        interval: '2m',
      },
    },

    // Custom annotations to display in graphs
    annotation: {
      enabled: false,
      name: 'Custom Annotation',
      tags: [],
      datasource: '-- Grafana --',
      iconColor: 'blue',
      type: 'tags',
    },
  },
}
