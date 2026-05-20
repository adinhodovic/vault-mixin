rule {
  match {
    name = "VaultSealed"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "VaultDown"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "VaultTooManyPendingTokens"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "VaultTooManyInfinityTokens"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "VaultClusterHealth"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "VaultAutopilotUnhealthy"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "VaultAutopilotNodeUnhealthy"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "VaultNoActiveNode"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "VaultHighResponseErrorRate"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "VaultRaftFSMPendingHigh"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "VaultAuditFailures"
  }
  disable = ["promql/regexp"]
}
