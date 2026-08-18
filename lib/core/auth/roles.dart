/// Shared permission sets for gating manager/admin screens.
///
/// These replaced role-name sets once tenants could edit what a role may do. An organisation
/// can grant its HOD `payroll:read`, take `leave:approve:dept` away, or invent a role of its
/// own, so `HOD` no longer tells you what its holder can reach — only a permission does. The
/// strings here are exactly what the backend's `@PreAuthorize` compares against, so what the
/// app offers and what the server allows cannot drift.
///
/// Each set is an OR: hold any one of them and the screen is offered. That matches the
/// endpoints, several of which accept either the organisation-wide permission or its `:dept`
/// variant.
library;

/// Tenant-wide sight of staff: the directory and every employee record.
///
/// The department-scoped read is deliberately absent. These screens reach sub-resources —
/// bank accounts, documents, emergency contacts — that stay behind the tenant-wide
/// `employee:read`, so somebody holding only `employee:read:dept` would get a 403.
const kManagerPermissions = {'employee:read'};

/// The attendance register.
///
/// Either tier reaches it: the backend confines a caller holding only the `:dept` permission
/// to the department on their own staff record, so the same screen shows HR the organisation
/// and shows a head their team — no client-side filtering, nothing extra to pass.
const kTeamAttendancePermissions = {'attendance:read', 'attendance:read:dept'};

/// The leave approval queue, on the same either-tier rule as the register above.
const kTeamLeavePermissions = {'leave:approve', 'leave:approve:dept'};

/// Both team screens together, for gating the pair in one place.
const kTeamScopedPermissions = {
  ...kTeamAttendancePermissions,
  ...kTeamLeavePermissions,
};

/// Inviting an employee to sign in (`POST /employees/{id}/invite`) needs `user:create`.
///
/// A narrower grant than [kManagerPermissions] by design: a stock HR_MANAGER does not hold
/// it, and that is a deliberate least-privilege boundary rather than an oversight.
const kInvitePermissions = {'user:create'};

/// Writing announcements, as opposed to reading them.
const kAnnouncementAuthorPermissions = {'announcement:create'};
