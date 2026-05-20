local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;

local variable = dashboard.variable;
local datasource = variable.datasource;
local query = variable.query;

{
  filters(config):: {
    local this = self,
    cluster: '%(clusterLabel)s="$cluster"' % config,
    exportedCluster: '%(vaultClusterLabel)s=~"$exported_cluster"' % config,
    exportedNamespace: '%(vaultNamespaceLabel)s=~"$exported_namespace"' % config,
    namespace: 'namespace=~"$namespace"',
    job: 'job=~"$job"',
    instance: 'instance=~"$instance"',

    scrape: if config.showMultiCluster then |||
      %(cluster)s,
      %(namespace)s,
      %(job)s,
      %(instance)s
    ||| % this else |||
      %(job)s,
      %(instance)s
    ||| % this,

    // Filter set for metrics without any Vault-internal labels (most
    // subsystem metrics: expire, autopilot, raft, runtime, leadership
    // summaries). Filters by Prometheus-injected labels only.
    default: |||
      %(scrape)s
    ||| % this,

    // Filter set for metrics that carry Vault's internal `cluster` label
    // (vault_core_unsealed, vault_core_active, vault_core_in_flight_requests).
    // Adds exported_cluster to drill into a single Vault cluster.
    clustered: |||
      %(default)s,
      %(exportedCluster)s
    ||| % this,

    // Filter set for metrics that carry both Vault's `cluster` and `namespace`
    // labels (vault_token_count_by_auth, vault_token_count_by_ttl). Adds both
    // exported_cluster and exported_namespace.
    tokenScoped: |||
      %(clustered)s,
      %(exportedNamespace)s
    ||| % this,
  },

  variables(config):: {
    local this = self,

    local defaultFilters = $.filters(config),

    datasource:
      datasource.new(
        'datasource',
        'prometheus',
      ) +
      datasource.generalOptions.withLabel('Data source') +
      {
        current: {
          selected: true,
          text: config.datasourceName,
          value: config.datasourceName,
        },
      },

    cluster:
      query.new(
        'cluster',
        'label_values(vault_core_unsealed{%(vaultSelector)s}, %(clusterLabel)s)' % config,
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Cluster') +
      query.refresh.onLoad() +
      query.refresh.onTime() +
      (
        if config.showMultiCluster
        then query.generalOptions.showOnDashboard.withLabelAndValue()
        else query.generalOptions.showOnDashboard.withNothing()
      ),

    namespace:
      query.new(
        'namespace',
        if config.showMultiCluster then
          'label_values(up{%(vaultSelector)s, %(cluster)s}, namespace)' % (config { cluster: defaultFilters.cluster })
        else
          'label_values(up{%(vaultSelector)s}, namespace)' % config,
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Namespace') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    job:
      query.new(
        'job',
        if config.showMultiCluster then
          'label_values(up{%(vaultSelector)s, %(cluster)s, %(namespace)s}, job)' % (config { cluster: defaultFilters.cluster, namespace: defaultFilters.namespace })
        else
          'label_values(up{%(vaultSelector)s}, job)' % config,
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Job') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    exportedCluster:
      query.new(
        'exported_cluster',
        if config.showMultiCluster then
          'label_values(vault_core_unsealed{%(cluster)s, %(namespace)s, %(job)s}, %(vaultClusterLabel)s)' % (config { cluster: defaultFilters.cluster, namespace: defaultFilters.namespace, job: defaultFilters.job })
        else
          'label_values(vault_core_unsealed{%(job)s}, %(vaultClusterLabel)s)' % (config { job: defaultFilters.job }),
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Exported Cluster') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    exportedNamespace:
      query.new(
        'exported_namespace',
        if config.showMultiCluster then
          'label_values(vault_token_count_by_auth{%(cluster)s, %(namespace)s, %(job)s}, %(vaultNamespaceLabel)s)' % (config { cluster: defaultFilters.cluster, namespace: defaultFilters.namespace, job: defaultFilters.job })
        else
          'label_values(vault_token_count_by_auth{%(job)s}, %(vaultNamespaceLabel)s)' % (config { job: defaultFilters.job }),
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Exported Namespace') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    instance:
      query.new(
        'instance',
        if config.showMultiCluster then
          'label_values(up{%(cluster)s, %(namespace)s, %(job)s}, instance)' % (config { cluster: defaultFilters.cluster, namespace: defaultFilters.namespace, job: defaultFilters.job })
        else
          'label_values(up{%(job)s}, instance)' % (config { job: defaultFilters.job }),
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Instance') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),
  },
}
