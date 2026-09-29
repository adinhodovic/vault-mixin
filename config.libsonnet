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

    // blackbox_exporter probing of /v1/sys/health. When /v1/sys/metrics
    // requires a token, sealed nodes fail the scrape and only show `up == 0`.
    // The health endpoint needs no token and returns the node state as an HTTP
    // status code: 200 active, 429 standby, 472 DR secondary, 473 performance
    // standby, 501 uninitialized, 503 sealed.
    healthProbe: {
      // Adds the health alerts and the Health Probe dashboard row.
      enabled: false,
      // Selects the blackbox_exporter probe series for Vault.
      selector: this.vaultSelector,
      // HTTP status code returned by /v1/sys/health, 0 when unreachable.
      statusCodeMetric: 'probe_http_status_code',
      // Label identifying the probed node, used in alerts and the dashboard.
      instanceLabel: 'instance',
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
        // VaultNodeSealed replaces this when health probing is enabled.
        enabled: !this.healthProbe.enabled,
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

      // The alerts below require healthProbe.enabled.
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
