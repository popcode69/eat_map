/// All backend endpoint paths in one place.
///
/// Paths are relative to [ApiConfig.baseUrl]. Use the builder functions for
/// any path that embeds an id so callers never hand-concatenate strings.
///
/// See `API_REFERENCE.md` for the full request/response contract of each.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ────────────────────────────────────────────────────────────
  static const String authGoogle = '/auth/google';
  static const String verifyPhone = '/auth/verify-phone';
  static const String me = '/auth/me';
  static const String meAvatar = '/auth/me/avatar';
  static const String meLocation = '/auth/me/location';

  // ── Zones ───────────────────────────────────────────────────────────
  static const String nearbyZones = '/zones/nearby';
  static String zoneDetail(String zoneId) => '/zones/$zoneId';
  static String customizeZone(String zoneId) => '/zones/$zoneId/customize';
  static String zoneRaiders(String zoneId) => '/zones/$zoneId/raiders';

  // ── Users ────────────────────────────────────────────────────────────
  static String userProfile(String userId) => '/users/$userId';

  // ── Devices ──────────────────────────────────────────────────────────
  static const String devicesRegister = '/devices/register';

  // ── Raids ───────────────────────────────────────────────────────────
  static const String startRaid = '/raids/start';
  static String verifyRaid(String raidId) => '/raids/$raidId/verify';

  // ── Wallet ──────────────────────────────────────────────────────────
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletWithdraw = '/wallet/withdraw';

  // ── Earnings ────────────────────────────────────────────────────────
  // Mixed-unit ledger: point rows (zone_capture/raid_earn/passive_earn)
  // and cash rows (warlord_payout/weekly_prize), plus pre-existing types.
  static const String earnings = '/earnings';

  // ── Payouts ─────────────────────────────────────────────────────────
  // Live projection of the user's monthly Warlord pool share (read-only).
  static const String warlordEstimate = '/payouts/warlord/estimate';

  // ── Place Requests ──────────────────────────────────────────────────
  static const String submitPlaceRequest = '/places/requests';

  // ── Leaderboard ─────────────────────────────────────────────────────
  static const String leaderboard = '/leaderboard'; // kept for reference
  static const String leaderboardCity = '/leaderboard/city';
  static const String leaderboardGlobal = '/leaderboard/global';
  static const String leaderboardSquad = '/leaderboard/squad';
}
