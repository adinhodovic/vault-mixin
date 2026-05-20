{
  local clusterVariableQueryString = if $._config.showMultiCluster then '&var-%(clusterLabel)s={{ $labels.%(clusterLabel)s }}' % $._config else '',
  local instanceGroupLabels = if $._config.showMultiCluster then '%(clusterLabel)s, job, instance' % $._config else 'job, instance',
  local vaultClusterGroupLabels = '%(vaultClusterLabel)s' % $._config,
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'vault',
        rules: if $._config.alerts.enabled then std.prune([
          if $._config.alerts.sealed.enabled then {
            alert: 'VaultSealed',
            expr: |||
              vault_core_unsealed{
                %(vaultSelector)s
              } == 0
            ||| % $._config,
            'for': $._config.alerts.sealed.interval,
            labels: {
              severity: $._config.alerts.sealed.severity,
            },
            annotations: {
              summary: 'Vault is sealed.',
              description: 'Vault instance {{ $labels.instance }} is sealed.',
              dashboard_url: $._config.dashboardUrls['vault-overview'] + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
          if $._config.alerts.down.enabled then {
            alert: 'VaultDown',
            expr: |||
              up{
                %(vaultSelector)s
              } == 0
            ||| % $._config,
            'for': $._config.alerts.down.interval,
            labels: {
              severity: $._config.alerts.down.severity,
            },
            annotations: {
              summary: 'Vault is down.',
              description: 'Vault instance {{ $labels.instance }} is down.',
              dashboard_url: $._config.dashboardUrls['vault-overview'] + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
          if $._config.alerts.tooManyPendingTokens.enabled then {
            alert: 'VaultTooManyPendingTokens',
            expr: |||
              avg(
                vault_token_create_count{
                  %(vaultSelector)s
                }
                -
                vault_token_store_count{
                  %(vaultSelector)s
                }
              ) by (%(groupLabels)s)
              > %(threshold)s
            ||| % (
              $._config
              {
                threshold: $._config.alerts.tooManyPendingTokens.threshold,
                groupLabels: instanceGroupLabels,
              }
            ),
            'for': $._config.alerts.tooManyPendingTokens.interval,
            labels: {
              severity: $._config.alerts.tooManyPendingTokens.severity,
            },
            annotations: {
              summary: 'Vault has too many pending tokens.',
              description: 'More than %(threshold)s tokens created but not yet stored on instance {{ $labels.instance }} the past %(interval)s.' % $._config.alerts.tooManyPendingTokens,
              dashboard_url: $._config.dashboardUrls['vault-overview'] + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
          if $._config.alerts.tooManyInfinityTokens.enabled then {
            alert: 'VaultTooManyInfinityTokens',
            expr: |||
              vault_token_count_by_ttl{
                %(vaultSelector)s,
                creation_ttl="+Inf"
              }
              > %(threshold)s
            ||| % (
              $._config
              {
                threshold: $._config.alerts.tooManyInfinityTokens.threshold,
              }
            ),
            'for': $._config.alerts.tooManyInfinityTokens.interval,
            labels: {
              severity: $._config.alerts.tooManyInfinityTokens.severity,
            },
            annotations: {
              summary: 'Vault has too many non-expiring tokens.',
              description: 'More than %(threshold)s non-expiring tokens on instance {{ $labels.instance }} for the past %(interval)s.' % $._config.alerts.tooManyInfinityTokens,
              dashboard_url: $._config.dashboardUrls['vault-overview'] + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
          if $._config.alerts.clusterHealth.enabled then {
            alert: 'VaultClusterHealth',
            expr: |||
              sum(
                vault_core_unsealed{
                  %(vaultSelector)s
                }
              ) by (%(groupLabels)s)
              /
              count(
                vault_core_unsealed{
                  %(vaultSelector)s
                }
              ) by (%(groupLabels)s)
              <= %(threshold)s
            ||| % (
              $._config
              {
                threshold: $._config.alerts.clusterHealth.threshold,
                groupLabels: vaultClusterGroupLabels,
              }
            ),
            'for': $._config.alerts.clusterHealth.interval,
            labels: {
              severity: $._config.alerts.clusterHealth.severity,
            },
            annotations: {
              summary: 'Vault cluster is not healthy.',
              description: 'Vault cluster is not healthy: only {{ $value | humanizePercentage }} of nodes are unsealed.',
              dashboard_url: $._config.dashboardUrls['vault-overview'] + ('?var-exported_cluster={{ $labels.%(vaultClusterLabel)s }}' % $._config) + clusterVariableQueryString,
            },
          },
          if $._config.alerts.autopilotUnhealthy.enabled then {
            alert: 'VaultAutopilotUnhealthy',
            expr: |||
              min(
                vault_autopilot_healthy{
                  %(vaultSelector)s
                }
              ) by (%(groupLabels)s)
              == 0
            ||| % ($._config { groupLabels: instanceGroupLabels }),
            'for': $._config.alerts.autopilotUnhealthy.interval,
            labels: {
              severity: $._config.alerts.autopilotUnhealthy.severity,
            },
            annotations: {
              summary: 'Vault Autopilot is unhealthy.',
              description: 'Vault Autopilot is unhealthy on instance {{ $labels.instance }} for the past %(interval)s.' % $._config.alerts.autopilotUnhealthy,
              dashboard_url: $._config.dashboardUrls['vault-overview'] + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
          if $._config.alerts.autopilotNodeUnhealthy.enabled then {
            alert: 'VaultAutopilotNodeUnhealthy',
            expr: |||
              vault_autopilot_node_healthy{
                %(vaultSelector)s
              } == 0
            ||| % $._config,
            'for': $._config.alerts.autopilotNodeUnhealthy.interval,
            labels: {
              severity: $._config.alerts.autopilotNodeUnhealthy.severity,
            },
            annotations: {
              summary: 'Vault Autopilot node is unhealthy.',
              description: 'Vault Autopilot node {{ $labels.node_id }} is unhealthy for the past %(interval)s.' % $._config.alerts.autopilotNodeUnhealthy,
              dashboard_url: $._config.dashboardUrls['vault-overview'] + clusterVariableQueryString,
            },
          },
          if $._config.alerts.noActiveNode.enabled then {
            alert: 'VaultNoActiveNode',
            expr: |||
              sum(
                vault_core_active{
                  %(vaultSelector)s
                }
              ) by (%(groupLabels)s)
              < 1
            ||| % ($._config { groupLabels: vaultClusterGroupLabels }),
            'for': $._config.alerts.noActiveNode.interval,
            labels: {
              severity: $._config.alerts.noActiveNode.severity,
            },
            annotations: {
              summary: 'Vault has no active node.',
              description: 'Vault cluster {{ $labels.%(vaultClusterLabel)s }} has no active node for the past %(interval)s.' % ($._config + $._config.alerts.noActiveNode),
              dashboard_url: $._config.dashboardUrls['vault-overview'] + ('?var-exported_cluster={{ $labels.%(vaultClusterLabel)s }}' % $._config) + clusterVariableQueryString,
            },
          },
          if $._config.alerts.highResponseErrorRate.enabled then {
            alert: 'VaultHighResponseErrorRate',
            expr: |||
              (
                sum(
                  rate(
                    vault_core_response_status_code{
                      %(vaultSelector)s,
                      type=~"4xx|5xx"
                    }[%(interval)s]
                  )
                ) by (%(groupLabels)s)
                /
                sum(
                  rate(
                    vault_core_response_status_code{
                      %(vaultSelector)s
                    }[%(interval)s]
                  )
                ) by (%(groupLabels)s)
                * 100
              ) > %(threshold)s
              and
              sum(
                rate(
                  vault_core_response_status_code{
                    %(vaultSelector)s,
                    type=~"4xx|5xx"
                  }[%(interval)s]
                )
              ) by (%(groupLabels)s)
              > %(minErrors)s
            ||| % (
              $._config
              {
                interval: $._config.alerts.highResponseErrorRate.interval,
                threshold: $._config.alerts.highResponseErrorRate.threshold,
                minErrors: $._config.alerts.highResponseErrorRate.minErrors,
                groupLabels: instanceGroupLabels,
              }
            ),
            'for': '1m',
            labels: {
              severity: $._config.alerts.highResponseErrorRate.severity,
            },
            annotations: {
              summary: 'Vault has a high response error rate.',
              description: 'More than %(threshold)s%% Vault responses are errors on instance {{ $labels.instance }} the past %(interval)s.' % $._config.alerts.highResponseErrorRate,
              dashboard_url: $._config.dashboardUrls['vault-overview'] + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
          if $._config.alerts.raftFSMPendingHigh.enabled then {
            alert: 'VaultRaftFSMPendingHigh',
            expr: |||
              vault_raft_storage_stats_fsm_pending{
                %(vaultSelector)s
              }
              > %(threshold)s
            ||| % ($._config { threshold: $._config.alerts.raftFSMPendingHigh.threshold }),
            'for': $._config.alerts.raftFSMPendingHigh.interval,
            labels: {
              severity: $._config.alerts.raftFSMPendingHigh.severity,
            },
            annotations: {
              summary: 'Vault Raft FSM pending operations are high.',
              description: 'Vault Raft peer {{ $labels.peer_id }} has more than %(threshold)s pending FSM operations for the past %(interval)s.' % $._config.alerts.raftFSMPendingHigh,
              dashboard_url: $._config.dashboardUrls['vault-overview'] + clusterVariableQueryString,
            },
          },
          if $._config.alerts.auditFailures.enabled then {
            alert: 'VaultAuditFailures',
            expr: |||
              sum(
                (
                  rate(
                    vault_audit_log_request_failure{
                      %(vaultSelector)s
                    }[%(interval)s]
                  )
                )
                or
                (
                  rate(
                    vault_audit_log_response_failure{
                      %(vaultSelector)s
                    }[%(interval)s]
                  )
                )
              ) by (%(groupLabels)s)
              > %(threshold)s
            ||| % (
              $._config
              {
                interval: $._config.alerts.auditFailures.interval,
                threshold: $._config.alerts.auditFailures.threshold,
                groupLabels: instanceGroupLabels,
              }
            ),
            'for': $._config.alerts.auditFailures.interval,
            labels: {
              severity: $._config.alerts.auditFailures.severity,
            },
            annotations: {
              summary: 'Vault audit log failures detected.',
              description: 'Vault audit log failures are occurring on instance {{ $labels.instance }} for the past %(interval)s.' % $._config.alerts.auditFailures,
              dashboard_url: $._config.dashboardUrls['vault-overview'] + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
        ]),
      },
    ],
  },
}
