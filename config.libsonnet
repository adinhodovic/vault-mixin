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
