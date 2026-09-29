{
  local clusterVariableQueryString = if $._config.showMultiCluster then '&var-%(clusterLabel)s={{ $labels.%(clusterLabel)s }}' % $._config else '',
  local instanceGroupLabels = if $._config.showMultiCluster then '%(clusterLabel)s, job, instance' % $._config else 'job, instance',
  local healthDashboardUrl = $._config.dashboardUrls['vault-overview'] + (if $._config.showMultiCluster then '?var-%(clusterLabel)s={{ $labels.%(clusterLabel)s }}' % $._config else ''),
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
          if $._config.alerts.lowResponseSuccessRate.enabled then {
            alert: 'VaultLowResponseSuccessRate',
            expr: |||
              (
                1 -
                (
                  sum(
                    rate(
                      vault_core_response_status_code{
                        %(vaultSelector)s,
                        type="5xx"
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
                )
              )
                * 100
              < %(threshold)s
              and
              sum(
                rate(
                  vault_core_response_status_code{
                    %(vaultSelector)s,
                    type="5xx"
                  }[%(interval)s]
                )
              ) by (%(groupLabels)s)
              > %(minErrors)s
            ||| % (
              $._config
              {
                interval: $._config.alerts.lowResponseSuccessRate.interval,
                threshold: $._config.alerts.lowResponseSuccessRate.threshold,
                minErrors: $._config.alerts.lowResponseSuccessRate.minErrors,
                groupLabels: instanceGroupLabels,
              }
            ),
            'for': '1m',
            labels: {
              severity: $._config.alerts.lowResponseSuccessRate.severity,
            },
            annotations: {
              summary: 'Vault has a low response success rate.',
              description: 'Less than %(threshold)s%% of Vault responses are non-5xx on instance {{ $labels.instance }} the past %(interval)s.' % $._config.alerts.lowResponseSuccessRate,
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
    ] + (if $._config.healthProbe.enabled then [
           {
             local healthConfig = $._config {
               healthSelector: $._config.healthProbe.selector,
               statusCodeMetric: $._config.healthProbe.statusCodeMetric,
             },
             name: 'vault-health',
             rules: if $._config.alerts.enabled then std.prune([
               if $._config.alerts.nodeSealed.enabled then {
                 alert: 'VaultNodeSealed',
                 expr: |||
                   %(statusCodeMetric)s{
                     %(healthSelector)s
                   } == 503
                 ||| % healthConfig,
                 'for': $._config.alerts.nodeSealed.interval,
                 labels: {
                   severity: $._config.alerts.nodeSealed.severity,
                 },
                 annotations: {
                   summary: 'Vault node is sealed.',
                   description: 'Vault instance {{ $labels.%(instanceLabel)s }} is reachable but sealed (/v1/sys/health returned HTTP 503) for the past %(interval)s.' % ($._config.alerts.nodeSealed { instanceLabel: $._config.healthProbe.instanceLabel }),
                   dashboard_url: healthDashboardUrl,
                 },
               },
               if $._config.alerts.nodeUninitialized.enabled then {
                 alert: 'VaultNodeUninitialized',
                 expr: |||
                   %(statusCodeMetric)s{
                     %(healthSelector)s
                   } == 501
                 ||| % healthConfig,
                 'for': $._config.alerts.nodeUninitialized.interval,
                 labels: {
                   severity: $._config.alerts.nodeUninitialized.severity,
                 },
                 annotations: {
                   summary: 'Vault node is uninitialized.',
                   description: 'Vault instance {{ $labels.%(instanceLabel)s }} is running but uninitialized (/v1/sys/health returned HTTP 501) for the past %(interval)s.' % ($._config.alerts.nodeUninitialized { instanceLabel: $._config.healthProbe.instanceLabel }),
                   dashboard_url: healthDashboardUrl,
                 },
               },
               if $._config.alerts.instanceUnreachable.enabled then {
                 alert: 'VaultInstanceUnreachable',
                 expr: |||
                   %(statusCodeMetric)s{
                     %(healthSelector)s
                   } == 0
                 ||| % healthConfig,
                 'for': $._config.alerts.instanceUnreachable.interval,
                 labels: {
                   severity: $._config.alerts.instanceUnreachable.severity,
                 },
                 annotations: {
                   summary: 'Vault instance is unreachable.',
                   description: 'Vault instance {{ $labels.%(instanceLabel)s }} has not answered /v1/sys/health probes for the past %(interval)s.' % ($._config.alerts.instanceUnreachable { instanceLabel: $._config.healthProbe.instanceLabel }),
                   dashboard_url: healthDashboardUrl,
                 },
               },
             ]),
           },
         ] else []),
  },
}
