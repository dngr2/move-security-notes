/// Move aborts on overflow, but it does NOT save you from rounding a value down
/// to zero. A small deposit priced against a high asset:share ratio mints zero
/// shares - the depositor pays assets and receives nothing, and nothing aborts.
/// The same "failure that doesn't crash" as the Solidity ERC-4626 inflation bug.
module move_security_notes::precision {
    /// VULNERABLE: floored integer division can return 0 shares for a nonzero
    /// deposit.
    public fun shares_for_vulnerable(deposit: u64, total_assets: u64, total_shares: u64): u64 {
        if (total_shares == 0) { deposit } else { deposit * total_shares / total_assets }
    }

    /// FIXED: reject a deposit that would mint nothing (a virtual-shares offset
    /// is the other common fix).
    public fun shares_for_safe(deposit: u64, total_assets: u64, total_shares: u64): u64 {
        let s = if (total_shares == 0) { deposit } else { deposit * total_shares / total_assets };
        assert!(s > 0, 1);
        s
    }

    #[test]
    fun test_vulnerable_rounds_deposit_to_zero() {
        // Vault holds 1_000_000 assets against a single share.
        let s = shares_for_vulnerable(999_999, 1_000_000, 1);
        assert!(s == 0, 100); // paid 999_999, minted 0
    }

    #[test]
    fun test_safe_normal_deposit_ok() {
        let s = shares_for_safe(500_000, 1_000_000, 1_000_000);
        assert!(s == 500_000, 101);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_safe_rejects_dust_deposit() {
        shares_for_safe(999_999, 1_000_000, 1); // would mint 0 -> aborts
    }
}
