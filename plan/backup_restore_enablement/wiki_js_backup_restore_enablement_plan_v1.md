# Wiki.js Backup-Restore Enablement Plan

## 1. Purpose

This document defines the phased implementation plan for maturing `swarm/wiki-js` so it can participate in the new backup-restore workflow while remaining backward compatible with the already deployed production Wiki.js stack on `ionos`.

This is a planning document only.

---

## 2. Current Gaps

The current repo still reflects an older manual deployment style.

Current gaps include:

```text
- no quick-start or maintenance menu
- no existing-deployment detection flow
- docs still recommend /gluster_storage paths
- templates still default to /gluster_storage paths
- secrets guidance is outdated and incomplete
- no documented backup-restore integration path exists yet
```

---

## 3. Planning Principle

This repo should evolve from:

```text
static manual deployment scaffold
```

into:

```text
guided deployment and maintenance entry point for Wiki.js in the current /swarm architecture
```

The key requirement is backward-compatible modernization.

---

## 4. Phase 1: Audit Current Repo Versus Live Production Reality

### 4.1 Goal

Understand how the live Wiki.js deployment on `ionos` compares to the current repo state.

### 4.2 Why this phase matters

The active production Wiki.js stack was recovered during migration work and may not exactly match the current repo templates.

The repo should not be modernized under false assumptions.

### 4.3 Required assessment topics

```text
- current live stack name
- current live service names
- current live network names
- current live DATA_ROOT and db_data usage
- any live server edits not represented in the repo
```

### 4.4 Acceptance criteria

```text
- The repo plan is grounded in the actual deployed Wiki.js state, not only in template assumptions.
```

---

## 5. Phase 2: Introduce a Quick-Start / Maintenance Entry Point

### 5.1 Goal

Add a simple, guided operator entry point similar in spirit to the newer swarm repos.

### 5.2 Expected responsibilities

The future quick-start flow should eventually help with:

```text
- checking required local tools
- ensuring .env exists or is detected
- showing current deployment status
- helping the operator re-enter maintenance tasks
- exposing backup-restore integration actions
```

### 5.3 Important rule

The first version does not need to match the full complexity of `swarm-figma-website`.

It needs to be good enough to support real operations safely.

### 5.4 Acceptance criteria

```text
- wiki-js no longer depends purely on README copy/paste for all operator actions.
```

---

## 6. Phase 3: Add Existing-Deployment Detection

### 6.1 Goal

Make the new quick-start safe to run inside an already configured production checkout.

### 6.2 Required detection behavior

The later implementation should determine things such as:

```text
- does .env already exist?
- does a concrete compose/stack file already exist?
- does the current folder look like a deployed Wiki.js instance?
- is the stack likely already running in Swarm?
```

### 6.3 Required UX behavior

When existing state is detected, the flow should:

```text
- explain what was found
- avoid destructive assumptions
- offer maintenance/update actions instead of only first-setup actions
```

### 6.4 Acceptance criteria

```text
- Running quick-start on an existing Wiki.js deployment is safe and useful.
```

---

## 7. Phase 4: Replace Deprecated Path Guidance

### 7.1 Goal

Move the repo’s documented deployment model from deprecated Gluster-based active storage to the current `/swarm` production model.

### 7.2 Required updates later

```text
- README examples
- .env.template DATA_ROOT guidance
- any deploy commands or examples that assume the old path layout
- any text implying Gluster is recommended for active DB datadirs
```

### 7.3 Mandatory guidance direction

The later docs should clearly say:

```text
- /swarm is the active production base path.
- Do not recommend /gluster_storage as the active DB deployment base.
- Logical PostgreSQL dumps are the backup mechanism to prefer.
- Raw datadir replication is not the same as a reliable database backup.
```

### 7.4 Acceptance criteria

```text
- The repo no longer teaches the outdated production storage model.
```

---

## 8. Phase 5: Sanitize Templates and Secrets Guidance

### 8.1 Goal

Remove risky or misleading template defaults and improve secrets handling guidance.

### 8.2 Required planning topics

```text
- replace any real-looking default password strings with obvious placeholders
- define whether DB password should remain env-based or move to Docker secrets in a future step
- align wording with current production expectations
```

### 8.3 Acceptance criteria

```text
- repo templates do not encourage copying unsafe defaults into production.
```

---

## 9. Phase 6: Define Wiki.js-Side Backup-Restore Integration Hooks

### 9.1 Goal

Make the repo explicit about the Wiki.js-side facts required for backup-restore connectivity.

### 9.2 What should be surfaced later

The later maintenance flow should help identify or display:

```text
- stack name
- db service name
- backend overlay network name
- db host from inside the network
- db port
- whether backup-restore connectivity has already been enabled
```

### 9.3 Important separation of concerns

This repo should expose Wiki.js-side integration clarity.

The actual backup-restore deployment-side network attachment flow should still primarily live in `swarm-backup-restore`.

### 9.4 Acceptance criteria

```text
- Operators can use the wiki-js repo to understand and verify the data that swarm-backup-restore needs.
```

---

## 10. Phase 7: Add a Guided Menu Action for Backup-Restore Enablement

### 10.1 Goal

Add a user-facing action that helps the operator bridge the current wiki-js deployment to the backup-restore workflow.

### 10.2 Expected direction

A future menu action should guide the operator through something like:

```text
- inspect current deployment facts
- confirm the active DB service/network
- show what backup-restore needs to connect
- optionally coordinate or output the exact follow-up action to use in swarm-backup-restore
```

This can be lightweight in the first version.

It does not need to fully reconfigure both repos automatically in one step.

### 10.3 Acceptance criteria

```text
- wiki-js operators have a clear guided path toward backup-restore integration instead of undocumented manual knowledge.
```

---

## 11. Phase 8: Commit a Clean Modernized Baseline

### 11.1 Goal

Reach a committed repo baseline after the modernization work is implemented.

### 11.2 Deliverables

```text
- quick-start / maintenance entry point committed
- backward-compatible detection flow committed
- /swarm-aligned docs and templates committed
- backup-restore enablement guidance committed
```

### 11.3 Acceptance criteria

```text
- The repo becomes a trustworthy operational reference for the current production Wiki.js deployment model.
```

---

## 12. Risks

```text
- The live deployment may have naming or network details that differ from repo defaults.
- Existing operators may rely on undocumented manual server knowledge today.
- A too-ambitious first quick-start may become fragile; a smaller maintenance-first entry point may be safer.
- If path/docs cleanup is incomplete, the repo may continue teaching the wrong architecture.
```

---

## 13. Success Criteria

This plan is successful when:

```text
- wiki-js gains a useful quick-start or maintenance entry point
- that flow is safe for already-running deployments
- docs and templates align with /swarm production reality
- backup-restore integration facts are surfaced clearly
- the repo can support the first manual production Wiki.js backup rollout without relying on tribal knowledge
```
