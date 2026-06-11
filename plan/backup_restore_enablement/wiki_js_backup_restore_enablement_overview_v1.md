# Wiki.js Backup-Restore Enablement Overview

## 1. Purpose

This document defines the high-level direction for modernizing `swarm/wiki-js` so it can participate cleanly in the new custom backup/restore architecture while staying backward compatible with the already running production deployment on `ionos`.

The immediate objective is not a full rewrite.

The immediate objective is:

```text
Give wiki-js a guided deployment/maintenance entry point.
Make it aware of existing deployments.
Add a clean path for enabling backup-restore DB connectivity.
Keep current production compatibility.
```

This is a planning document only.

---

## 2. Related Documents

The detailed implementation planning for this repository is defined here:

- [Wiki.js Backup-Restore Enablement Plan](./wiki_js_backup_restore_enablement_plan_v1.md)

This document is also closely related to:

```text
d:/Development/Code/swarm/swarm-backup-restore/plan/wiki_js_backup_restore/
d:/Development/Code/python/backup-restore/plan/swarm_rollout/
```

---

## 3. Current Assessed State

The current repo is still on a simple older deployment model.

Observed from the current assessment:

```text
- No quick-start script exists.
- No interactive setup/menu flow exists.
- README still recommends /gluster_storage/swarm/wiki/<DOMAINNAME>.
- .env.template still uses /gluster_storage/swarm/wiki/wiki.fe-wi.com as DATA_ROOT.
- .env.template currently includes a real-looking DB password value and should later be sanitized.
- docker-compose.yml.template already defines the app and db services plus the wiki_js_backend overlay network.
```

The important production fact from the migration handoff is:

```text
Wiki.js is already recovered and running on ionos from /swarm/wiki/wiki.fe-wi.com.
```

That means the repo now needs operational modernization without assuming a greenfield deployment.

---

## 4. Main Compatibility Decision

The future wiki-js quick-start flow must support both of these situations:

```text
- fresh deployment setup
- existing deployment adoption / detection / guided maintenance
```

The second case is mandatory because the user already has an active Wiki.js installation created with the older deployment style.

The repo therefore should not behave as though first-time setup is the only supported path.

---

## 5. Scope

### 5.1 In scope

```text
- Add a modern quick-start or equivalent guided entry point.
- Add a backward-compatible detection flow for existing deployments.
- Align documentation and templates with /swarm instead of /gluster_storage.
- Add an operator path for enabling backup-restore DB connectivity.
- Keep current compose/service assumptions understandable and inspectable.
```

### 5.2 Out of scope

```text
- Replacing Wiki.js itself.
- Replacing the running production deployment immediately.
- Rebuilding the entire repo around a different deployment technology.
- Implementing backup-restore app logic in this repo.
```

---

## 6. Why This Repo Still Matters

Even if the backup-restore deployment workflow primarily lives in `swarm-backup-restore`, the `wiki-js` repo still matters because it should define:

```text
- how a Wiki.js deployment is structured
- how existing config is detected
- what the canonical DB service/network naming expectations are
- how operators maintain or re-enter the deployment flow later
```

Without that, the integration will remain a one-off server memory exercise instead of a repeatable repo-driven workflow.

---

## 7. Target Mental Model

The target operator mental model should become:

```text
Clone/open wiki-js deployment repo
  ↓
Run quick-start
  ↓
Tool detects existing deployment state or offers fresh setup
  ↓
Tool shows current stack/data/config paths
  ↓
Tool offers maintenance actions, including backup-restore integration help
  ↓
Operator can safely keep or modernize the deployment without guessing
```

---

## 8. Main Documentation Correction Required

The repo currently still documents the deprecated Gluster-backed path model.

That must later be corrected so the repo clearly supports the new production truth:

```text
Use /swarm for active production stack data on the active node.
Do not recommend /gluster_storage as the active production path.
Do not treat GlusterFS replication as database backup.
Prefer logical DB dumps for PostgreSQL backup/recovery.
```

This is not just a README cleanup.

It is part of preventing future operators from rebuilding the old architecture by accident.

---

## 9. Backup-Restore Integration Direction

The future integration should help surface the information needed by `swarm-backup-restore`.

At a high level, the repo should later be able to support or document:

```text
- current stack name
- current DB service name
- current backend network name
- current DATA_ROOT
- whether the deployment appears already active and healthy
```

The repo should not try to own the entire backup-restore deployment flow.

It should provide the Wiki.js-side clarity and maintenance entry point.

---

## 10. Risks

```text
- Existing live deployment details may have diverged from the current repo templates.
- Operators may assume quick-start should recreate everything instead of detecting current state.
- Direct edits made historically on the server may not yet be represented in repo defaults.
- Old docs may continue to mislead until they are updated thoroughly.
```

---

## 11. Target Outcome

After later implementation based on this plan, the repo should be able to:

```text
- support fresh setup more cleanly than today
- detect and work with an already deployed Wiki.js instance
- guide operators toward /swarm-based production conventions
- help enable backup-restore DB connectivity without breaking the current deployment
```
