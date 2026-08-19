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

/// The staff directory and the records it opens.
///
/// Either tier: `GET /employees` and `GET /employees/{id}` both accept the department-scoped
/// read, and the backend narrows the list to the caller's own department when that is all they
/// hold. A head of department gets their team; HR gets the organisation; the screen is the same.
///
/// The detail screen shows only what the list already returned — position, department, branch,
/// status, contact details. It does not reach bank accounts, documents or emergency contacts,
/// which stay behind the tenant-wide `employee:read`, so nothing here 403s for a
/// department-scoped caller.
const kDirectoryPermissions = {'employee:read', 'employee:read:dept'};

/// Upcoming birthdays on the home screen.
///
/// `GET /employees/birthdays` has no department tier — it takes the tenant-wide
/// `employee:read` alone. Kept apart from [kDirectoryPermissions] for exactly that reason:
/// gating the panel on the directory set would show a head of department a section whose one
/// request comes back 403.
const kBirthdayPermissions = {'employee:read'};

/// Editing an employee record, including changing their status.
const kEmployeeUpdatePermissions = {'employee:update'};

/// Payroll cycles.
const kPayrollPermissions = {'payroll:read'};

/// Disciplinary cases raised against an employee.
///
/// Either tier, since the module gained a department scope: a head of department holding
/// `discipline:read:dept` sees their own team's cases and nobody else's.
const kDisciplinePermissions = {'discipline:read', 'discipline:read:dept'};

/// Raising a case, as opposed to reading one.
///
/// A separate grant from [kDisciplinePermissions] now that a tenant can set the two
/// independently: a head of department may be given the read to follow their team's cases
/// without the create to open them, and an ungated button would 403 on tap.
const kDisciplineCreatePermissions = {'discipline:create', 'discipline:create:dept'};

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
/// A narrower grant than [kDirectoryPermissions] by design: a stock HR_MANAGER does not hold
/// it, and that is a deliberate least-privilege boundary rather than an oversight.
const kInvitePermissions = {'user:create'};

/// Writing announcements, as opposed to reading them.
const kAnnouncementAuthorPermissions = {'announcement:create'};
