/// Shared role sets for gating Phase 4 manager/admin screens. There is no
/// "has direct reports" concept in the backend — `leave:approve` and
/// `attendance:approve` are only ever granted via these two roles, so
/// plan.txt's Tier A ("anyone with direct reports") is gated identically to
/// Tier B in practice.
const kManagerRoles = {'HR_MANAGER', 'ORG_ADMIN'};

/// Employee invite (`POST /employees/{id}/invite`) requires `user:create`,
/// which only `ORG_ADMIN`/`SUPER_ADMIN` hold — `HR_MANAGER` does not, and
/// that's a deliberate least-privilege boundary, not a bug. Gate invite UI
/// to this narrower set rather than [kManagerRoles].
const kOrgAdminRoles = {'ORG_ADMIN'};
