/// Shared role sets for gating manager/admin screens.
///
/// `SUPER_ADMIN` is included because registration grants it to the founder, who
/// holds every permission in the catalogue — omitting it hid these screens from
/// the one account every new tenant starts with.
///
/// Tenant-wide sight of staff: the whole directory, every announcement, every
/// employee record. `HOD` is deliberately absent — a head of department holds
/// only the `:dept` variants and would get a 403 from anything gated here.
const kManagerRoles = {'HR_MANAGER', 'ORG_ADMIN', 'SUPER_ADMIN'};

/// The team-scoped screens: the attendance register and the leave approval
/// queue.
///
/// These are the two places `HOD` belongs. The backend confines a head of
/// department to the department on their own staff record, so the same screen
/// shows HR the organisation and shows a head their team — no client-side
/// filtering, and nothing extra to pass.
///
/// Kept separate from [kManagerRoles] rather than widening it: that set also
/// gates creating announcements and editing employee records, neither of which
/// a head of department can do.
const kTeamScopedRoles = {'HR_MANAGER', 'ORG_ADMIN', 'SUPER_ADMIN', 'HOD'};

/// Employee invite (`POST /employees/{id}/invite`) requires `user:create`,
/// which only `ORG_ADMIN`/`SUPER_ADMIN` hold — `HR_MANAGER` does not, and
/// that's a deliberate least-privilege boundary, not a bug. Gate invite UI
/// to this narrower set rather than [kManagerRoles].
const kOrgAdminRoles = {'ORG_ADMIN', 'SUPER_ADMIN'};
