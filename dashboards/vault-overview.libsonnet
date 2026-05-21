local mixinUtils = import 'github.com/adinhodovic/mixin-utils/utils.libsonnet';
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local util = import 'util.libsonnet';

local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

{
  local dashboardName = 'vault-overview',
  grafanaDashboards+:: {
    ['%s.json' % dashboardName]:

      local defaultVariables = util.variables($._config);

      local variables = [
        defaultVariables.datasource,
        defaultVariables.cluster,
        defaultVariables.namespace,
        defaultVariables.job,
        defaultVariables.exportedCluster,
        defaultVariables.exportedNamespace,
        defaultVariables.instance,
      ];

      local defaultFilters = util.filters($._config);
      local queries = {
        // Summary
        sealed: |||
          sum(
            vault_core_unsealed{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        nodes: |||
          count(
            vault_core_unsealed{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        up: |||
          sum(
            up{
              %(default)s
            }
          )
        ||| % defaultFilters,

        responseRateByType: |||
          sum by (type) (
            rate(
              vault_core_response_status_code{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        responseRateByCode: |||
          sum by (type) (
            rate(
              vault_core_response_status_code{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        responseSuccessRate: |||
          (
            1 -
            (
              sum(
                rate(
                  vault_core_response_status_code{
                    %(default)s,
                    type="5xx"
                  }[$__rate_interval]
                )
              )
              /
              sum(
                rate(
                  vault_core_response_status_code{
                    %(default)s
                  }[$__rate_interval]
                )
              )
            )
          )
          * 100
        ||| % defaultFilters,

        leases: |||
          max(
            vault_expire_num_leases{
              %(default)s
            }
          )
        ||| % defaultFilters,

        irrevocableLeases: |||
          max(
            vault_expire_num_irrevocable_leases{
              %(default)s
            }
          )
        ||| % defaultFilters,

        mountEntriesByType: |||
          sum by (type, local) (
            vault_core_mount_table_num_entries{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        mountTableSizeByType: |||
          sum by (type, local) (
            vault_core_mount_table_size{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        // Cluster / Raft
        activeNode: |||
          vault_core_active{
            %(clustered)s
          }
        ||| % defaultFilters,

        autopilotHealthy: |||
          min(
            vault_autopilot_healthy{
              %(default)s
            }
          )
        ||| % defaultFilters,

        autopilotFailureTolerance: |||
          min(
            vault_autopilot_failure_tolerance{
              %(default)s
            }
          )
        ||| % defaultFilters,

        autopilotNodeHealthy: |||
          min by (node_id) (
            vault_autopilot_node_healthy{
              %(default)s
            }
          )
        ||| % defaultFilters,

        replicationDrPrimary: |||
          max(
            vault_core_replication_dr_primary{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        replicationDrSecondary: |||
          max(
            vault_core_replication_dr_secondary{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        replicationPerformancePrimary: |||
          max(
            vault_core_replication_performance_primary{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        replicationPerformanceSecondary: |||
          max(
            vault_core_replication_performance_secondary{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        leadershipLostRate: |||
          sum(
            rate(
              vault_core_leadership_lost_count{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        raftFSMCommitIndex: |||
          max by (peer_id) (
            vault_raft_storage_stats_commit_index{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        raftFSMAppliedIndex: |||
          max by (peer_id) (
            vault_raft_storage_stats_applied_index{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        raftFSMPending: |||
          max by (peer_id) (
            vault_raft_storage_stats_fsm_pending{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        raftTerm: |||
          max by (peer_id) (
            vault_raft_storage_stats_term{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        raftLeaderOldestLogAge: |||
          max(
            vault_raft_leader_oldestLogAge{
              %(default)s
            }
          )
        ||| % defaultFilters,

        raftBoltPageBytesByDatabase: |||
          sum by (database) (
            vault_raft_storage_bolt_page_bytes_allocated{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        raftBoltFreePagesByDatabase: |||
          sum by (database) (
            vault_raft_storage_bolt_freelist_free_pages{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        raftBoltWriteCountByDatabase: |||
          sum by (database) (
            vault_raft_storage_bolt_write_count{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        raftBoltWriteTimeRateByDatabase: |||
          sum by (database) (
            rate(
              vault_raft_storage_bolt_write_time{
                %(clustered)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        stepDownRate: |||
          sum(
            rate(
              vault_core_step_down_count{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        raftCommitTimeP99: |||
          max(
            vault_raft_commitTime{
              %(default)s,
              quantile="0.99"
            }
          )
        ||| % defaultFilters,

        raftApplyRate: |||
          sum(
            rate(
              vault_raft_apply{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        // Requests
        inFlightRequests: |||
          sum(
            vault_core_in_flight_requests{
              %(clustered)s
            }
          )
        ||| % defaultFilters,

        requestRate: |||
          sum(
            rate(
              vault_core_handle_request_count{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        loginRequestRate: |||
          sum(
            rate(
              vault_core_handle_login_request_count{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        requestLatencyP50: |||
          max(
            vault_core_handle_request{
              %(default)s,
              quantile="0.5"
            }
          )
        ||| % defaultFilters,

        requestLatencyP99: |||
          max(
            vault_core_handle_request{
              %(default)s,
              quantile="0.99"
            }
          )
        ||| % defaultFilters,

        // Tokens
        availableTokens: |||
          sum(
            vault_token_count_by_auth{
              %(tokenScoped)s
            }
          )
        ||| % defaultFilters,

        pendingTokens: |||
          sum(
            vault_token_create_count{
              %(default)s
            }
            -
            vault_token_store_count{
              %(default)s
            }
          )
        ||| % defaultFilters,

        tokensByAuth: |||
          sum by (auth_method) (
            vault_token_count_by_auth{
              %(tokenScoped)s
            }
          )
        ||| % defaultFilters,

        tokenCreateRate: |||
          sum(
            rate(
              vault_token_create_count{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        tokenStoreRate: |||
          sum(
            rate(
              vault_token_store_count{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        tokenLookupRate: |||
          sum(
            rate(
              vault_token_lookup_count{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        // Audit
        auditRequestRate: |||
          sum(
            rate(
              vault_audit_log_request_count{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        auditResponseRate: |||
          sum(
            rate(
              vault_audit_log_response_count{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        auditRequestFailureRate: |||
          sum(
            rate(
              vault_audit_log_request_failure{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        auditResponseFailureRate: |||
          sum(
            rate(
              vault_audit_log_response_failure{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        // Runtime
        allocatedBytes: |||
          avg(
            vault_runtime_alloc_bytes{
              %(default)s
            }
          )
        ||| % defaultFilters,

        sysBytes: |||
          avg(
            vault_runtime_sys_bytes{
              %(default)s
            }
          )
        ||| % defaultFilters,

        goroutines: |||
          avg(
            vault_runtime_num_goroutines{
              %(default)s
            }
          )
        ||| % defaultFilters,

        heapObjects: |||
          avg(
            vault_runtime_heap_objects{
              %(default)s
            }
          )
        ||| % defaultFilters,

        gcRuns: |||
          sum(
            vault_runtime_total_gc_runs{
              %(default)s
            }
          )
        ||| % defaultFilters,

        gcPause: |||
          sum(
            vault_runtime_total_gc_pause_ns{
              %(default)s
            }
          )
        ||| % defaultFilters,

        mallocs: |||
          sum(
            vault_runtime_malloc_count{
              %(default)s
            }
          )
        ||| % defaultFilters,

        frees: |||
          sum(
            vault_runtime_free_count{
              %(default)s
            }
          )
        ||| % defaultFilters,

        processCpuRate: |||
          sum(
            rate(
              process_cpu_seconds_total{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        processResidentMemory: |||
          avg(
            process_resident_memory_bytes{
              %(default)s
            }
          )
        ||| % defaultFilters,

        openFDPercent: |||
          max(
            process_open_fds{
              %(default)s
            }
            /
            process_max_fds{
              %(default)s
            }
            * 100
          )
        ||| % defaultFilters,

        processNetworkRate: |||
          sum(
            rate(
              process_network_receive_bytes_total{
                %(default)s
              }[$__rate_interval]
            )
          )
          +
          sum(
            rate(
              process_network_transmit_bytes_total{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        cacheHitRate: |||
          sum(
            rate(
              vault_cache_hit{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,
      };

      local panels = {
        // Summary
        sealedStat:
          mixinUtils.dashboards.statPanel(
            'Unsealed Nodes',
            'short',
            queries.sealed,
            steps=[
              { color: 'red', value: 0 },
              { color: 'green', value: 1 },
            ],
          ),

        nodesStat:
          mixinUtils.dashboards.statPanel(
            'Total Nodes',
            'short',
            queries.nodes,
          ),

        upStat:
          mixinUtils.dashboards.statPanel(
            'Scrape Up',
            'short',
            queries.up,
            steps=[
              { color: 'red', value: 0 },
              { color: 'green', value: 1 },
            ],
          ),

        responseRateByTypePieChart:
          mixinUtils.dashboards.pieChartPanel(
            'Response Rate by Type',
            'reqps',
            queries.responseRateByType,
            '{{ type }}',
          ),

        responseRateByCodeTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Response Rate by Code',
            'reqps',
            queries.responseRateByCode,
            '{{ type }}',
            stack='normal',
          ),

        responseSuccessRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Response Success Rate',
            'percent',
            queries.responseSuccessRate,
            'Success Rate',
            min=0,
            max=100,
          ),

        leasesStat:
          mixinUtils.dashboards.statPanel(
            'Active Leases',
            'short',
            queries.leases,
          ),

        irrevocableLeasesStat:
          mixinUtils.dashboards.statPanel(
            'Irrevocable Leases',
            'short',
            queries.irrevocableLeases,
            steps=[
              { color: 'green', value: 0 },
              { color: 'orange', value: 1 },
              { color: 'red', value: 10 },
            ],
          ),

        mountEntriesByTypePieChart:
          mixinUtils.dashboards.pieChartPanel(
            'Mount Entries by Type',
            'short',
            queries.mountEntriesByType,
            '{{ type }} local={{ local }}',
          ),

        mountTableSizeByTypePieChart:
          mixinUtils.dashboards.pieChartPanel(
            'Mount Table Size by Type',
            'bytes',
            queries.mountTableSizeByType,
            '{{ type }} local={{ local }}',
          ),

        // Cluster / Raft
        autopilotHealthyTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Autopilot Healthy',
            'short',
            queries.autopilotHealthy,
            'Healthy',
          ),

        autopilotFailureToleranceTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Autopilot Failure Tolerance',
            'short',
            queries.autopilotFailureTolerance,
            'Tolerance',
          ),

        autopilotNodeHealthyTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Autopilot Node Healthy',
            'short',
            queries.autopilotNodeHealthy,
            '{{ node_id }}',
          ),

        replicationStatusTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Replication Status',
            'short',
            [
              { expr: queries.replicationDrPrimary, legend: 'DR Primary' },
              { expr: queries.replicationDrSecondary, legend: 'DR Secondary' },
              { expr: queries.replicationPerformancePrimary, legend: 'Performance Primary' },
              { expr: queries.replicationPerformanceSecondary, legend: 'Performance Secondary' },
            ],
          ),

        activeNodeTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Active Node',
            'short',
            queries.activeNode,
            '{{ instance }}',
          ),

        leadershipChangesTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Leadership Changes',
            'short',
            [
              { expr: queries.leadershipLostRate, legend: 'Leadership lost' },
              { expr: queries.stepDownRate, legend: 'Step down' },
            ],
          ),

        raftCommitTimeTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Raft Commit Time (p99)',
            'ms',
            queries.raftCommitTimeP99,
            'p99',
          ),

        raftApplyRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Raft Apply Rate',
            'ops',
            queries.raftApplyRate,
            'apply/s',
          ),

        raftPeerIndexesTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Raft Peer Indexes',
            'short',
            [
              { expr: queries.raftFSMCommitIndex, legend: 'Commit {{ peer_id }}' },
              { expr: queries.raftFSMAppliedIndex, legend: 'Applied {{ peer_id }}' },
            ],
          ),

        raftFSMPendingTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Raft FSM Pending',
            'short',
            queries.raftFSMPending,
            '{{ peer_id }}',
          ),

        raftTermTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Raft Term',
            'short',
            queries.raftTerm,
            '{{ peer_id }}',
          ),

        raftLeaderOldestLogAgeTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Raft Leader Oldest Log Age',
            's',
            queries.raftLeaderOldestLogAge,
            'Oldest Log Age',
          ),

        raftBoltPageBytesByDatabasePieChart:
          mixinUtils.dashboards.pieChartPanel(
            'Raft Bolt Page Bytes by Database',
            'bytes',
            queries.raftBoltPageBytesByDatabase,
            '{{ database }}',
          ),

        raftBoltFreePagesByDatabaseTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Raft Bolt Free Pages',
            'short',
            queries.raftBoltFreePagesByDatabase,
            '{{ database }}',
          ),

        raftBoltWriteCountByDatabaseTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Raft Bolt Write Count',
            'short',
            queries.raftBoltWriteCountByDatabase,
            '{{ database }}',
          ),

        raftBoltWriteTimeRateByDatabaseTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Raft Bolt Write Time Rate',
            'ns',
            queries.raftBoltWriteTimeRateByDatabase,
            '{{ database }}',
          ),

        // Requests
        inFlightRequestsStat:
          mixinUtils.dashboards.statPanel(
            'In-Flight Requests',
            'short',
            queries.inFlightRequests,
          ),

        requestRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Request Rate',
            'reqps',
            [
              { expr: queries.requestRate, legend: 'Requests' },
              { expr: queries.loginRequestRate, legend: 'Login requests' },
            ],
          ),

        requestLatencyTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Request Latency',
            'ms',
            [
              { expr: queries.requestLatencyP50, legend: 'p50' },
              { expr: queries.requestLatencyP99, legend: 'p99' },
            ],
          ),

        // Tokens
        availableTokensTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Available Tokens',
            'short',
            queries.availableTokens,
            'Tokens',
            stack='normal',
          ),

        pendingTokensTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Pending Tokens',
            'short',
            queries.pendingTokens,
            'Pending',
            stack='normal',
          ),

        tokensByAuthTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Tokens by Auth Method',
            'short',
            queries.tokensByAuth,
            '{{ auth_method }}',
            stack='normal',
          ),

        tokenOperationsTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Token Operations',
            'ops',
            [
              { expr: queries.tokenCreateRate, legend: 'Create' },
              { expr: queries.tokenStoreRate, legend: 'Store' },
              { expr: queries.tokenLookupRate, legend: 'Lookup' },
            ],
            stack='normal',
          ),

        // Audit
        auditRequestsTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Audit Log Requests',
            'reqps',
            [
              { expr: queries.auditRequestRate, legend: 'Request' },
              { expr: queries.auditResponseRate, legend: 'Response' },
            ],
          ),

        auditFailuresTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Audit Log Failures',
            'reqps',
            [
              { expr: queries.auditRequestFailureRate, legend: 'Request failure' },
              { expr: queries.auditResponseFailureRate, legend: 'Response failure' },
            ],
          ),

        // Runtime
        memoryTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Memory',
            'decbytes',
            [
              { expr: queries.allocatedBytes, legend: 'Allocated' },
              { expr: queries.sysBytes, legend: 'System' },
            ],
          ),

        goroutinesTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Goroutines',
            'short',
            queries.goroutines,
            'Goroutines',
          ),

        heapObjectsTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Heap Objects',
            'short',
            queries.heapObjects,
            'Objects',
          ),

        gcTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'GC Activity',
            'short',
            [
              { expr: queries.gcRuns, legend: 'GC Runs' },
              { expr: queries.gcPause, legend: 'GC Pause ns' },
            ],
          ),

        allocationsTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Runtime Allocations',
            'short',
            [
              { expr: queries.mallocs, legend: 'Mallocs' },
              { expr: queries.frees, legend: 'Frees' },
            ],
          ),

        processResourcesTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Process Resources',
            'short',
            [
              { expr: queries.processCpuRate, legend: 'CPU seconds/s' },
              { expr: queries.openFDPercent, legend: 'Open FDs %' },
            ],
          ),

        processMemoryTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Process Resident Memory',
            'decbytes',
            queries.processResidentMemory,
            'RSS',
          ),

        processNetworkTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Process Network Rate',
            'Bps',
            queries.processNetworkRate,
            'Network I/O',
          ),

        cacheHitRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Cache Hit Rate',
            'ops',
            queries.cacheHitRate,
            'Hits',
          ),
      };

      local rows =
        [
          row.new('Summary') +
          row.gridPos.withX(0) +
          row.gridPos.withY(0) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.sealedStat,
            panels.nodesStat,
            panels.upStat,
            panels.leasesStat,
            panels.irrevocableLeasesStat,
            panels.inFlightRequestsStat,
          ],
          panelWidth=4,
          panelHeight=4,
          startY=1
        ) +
        [
          row.new('Responses') +
          row.gridPos.withX(0) +
          row.gridPos.withY(5) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.responseRateByTypePieChart,
            panels.responseRateByCodeTimeSeries,
            panels.responseSuccessRateTimeSeries,
          ],
          panelWidth=8,
          panelHeight=6,
          startY=6
        ) +
        [
          row.new('Mounts') +
          row.gridPos.withX(0) +
          row.gridPos.withY(12) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.mountEntriesByTypePieChart,
            panels.mountTableSizeByTypePieChart,
          ],
          panelWidth=12,
          panelHeight=6,
          startY=13
        ) +
        [
          row.new('Cluster') +
          row.gridPos.withX(0) +
          row.gridPos.withY(19) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.autopilotHealthyTimeSeries,
            panels.autopilotFailureToleranceTimeSeries,
            panels.autopilotNodeHealthyTimeSeries,
            panels.replicationStatusTimeSeries,
            panels.activeNodeTimeSeries,
            panels.leadershipChangesTimeSeries,
            panels.raftCommitTimeTimeSeries,
            panels.raftApplyRateTimeSeries,
            panels.raftPeerIndexesTimeSeries,
            panels.raftFSMPendingTimeSeries,
            panels.raftTermTimeSeries,
            panels.raftLeaderOldestLogAgeTimeSeries,
          ],
          panelWidth=12,
          panelHeight=8,
          startY=20
        ) +
        [
          row.new('Raft Storage') +
          row.gridPos.withX(0) +
          row.gridPos.withY(68) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.raftBoltPageBytesByDatabasePieChart,
            panels.raftBoltFreePagesByDatabaseTimeSeries,
            panels.raftBoltWriteCountByDatabaseTimeSeries,
            panels.raftBoltWriteTimeRateByDatabaseTimeSeries,
          ],
          panelWidth=12,
          panelHeight=8,
          startY=69
        ) +
        [
          row.new('Requests') +
          row.gridPos.withX(0) +
          row.gridPos.withY(85) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.requestRateTimeSeries,
            panels.requestLatencyTimeSeries,
          ],
          panelWidth=12,
          panelHeight=8,
          startY=86
        ) +
        [
          row.new('Tokens') +
          row.gridPos.withX(0) +
          row.gridPos.withY(94) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.availableTokensTimeSeries,
            panels.pendingTokensTimeSeries,
            panels.tokensByAuthTimeSeries,
            panels.tokenOperationsTimeSeries,
          ],
          panelWidth=12,
          panelHeight=8,
          startY=95
        ) +
        [
          row.new('Audit') +
          row.gridPos.withX(0) +
          row.gridPos.withY(111) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.auditRequestsTimeSeries,
            panels.auditFailuresTimeSeries,
          ],
          panelWidth=12,
          panelHeight=8,
          startY=112
        ) +
        [
          row.new('Runtime') +
          row.gridPos.withX(0) +
          row.gridPos.withY(120) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.memoryTimeSeries,
            panels.goroutinesTimeSeries,
            panels.heapObjectsTimeSeries,
            panels.gcTimeSeries,
            panels.allocationsTimeSeries,
            panels.processResourcesTimeSeries,
            panels.processMemoryTimeSeries,
            panels.processNetworkTimeSeries,
            panels.cacheHitRateTimeSeries,
          ],
          panelWidth=8,
          panelHeight=6,
          startY=121
        );

      mixinUtils.dashboards.bypassDashboardValidation +
      dashboard.new(
        'Vault / Overview',
      ) +
      dashboard.withDescription('A dashboard that monitors Vault. It is created using the [vault-mixin](https://github.com/adinhodovic/vault-mixin). For an in-depth view of Go runtime internals (CPU, memory, GC, scheduling, contention, file descriptor pressure), pair this dashboard with the [Go / Overview dashboard](https://grafana.com/grafana/dashboards/25063-go-overview/) from the [go-mixin](https://github.com/adinhodovic/go-mixin) project.') +
      dashboard.withUid($._config.dashboardIds[dashboardName]) +
      dashboard.withTags($._config.tags) +
      dashboard.withTimezone('utc') +
      dashboard.withEditable(false) +
      dashboard.time.withFrom('now-6h') +
      dashboard.time.withTo('now') +
      dashboard.withVariables(variables) +
      dashboard.withPanels(rows) +
      dashboard.withAnnotations(
        mixinUtils.dashboards.annotations($._config, defaultFilters)
      ),
  },
}
