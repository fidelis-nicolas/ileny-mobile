/// Display helpers for the raw enum names the employee endpoints return.
///
/// The qualification labels match the web client's word for word, so the same
/// record does not read "Bachelor's degree" on one screen and BACHELORS on
/// another. They are a table and not a derivation because deriving turns the
/// half of this list that is an acronym into words nobody writes — "Ssce",
/// "Ond", "Hnd".
///
/// Anything the table does not know still renders, derived the way the
/// discipline screens derive theirs: a value the backend adds later shows as
/// "Trade certificate" rather than as a blank until the app ships again.
const _qualificationLabels = <String, String>{
  'PRIMARY': 'Primary school',
  'SSCE': 'SSCE / WAEC / NECO',
  'NCE': 'NCE',
  'OND': 'OND',
  'HND': 'HND',
  'BACHELORS': "Bachelor's degree",
  'PGD': 'Postgraduate diploma',
  'MASTERS': "Master's degree",
  'DOCTORATE': 'Doctorate',
  'PROFESSIONAL': 'Professional certification',
  'OTHER': 'Other',
};

/// Null in, null out — an employee with no qualification recorded has nothing
/// to say here, and the info tiles already render that as a dash.
String? qualificationLabel(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final known = _qualificationLabels[raw];
  if (known != null) return known;
  final words = raw.toLowerCase().replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}
