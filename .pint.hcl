rule {
  match {
    name = "VaultSealed"
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
    name = "VaultAutopilotUnhealthy"
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
    name = "VaultLowResponseSuccessRate"
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
