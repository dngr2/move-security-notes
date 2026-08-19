/// A percentage fee floored by integer division rounds to ZERO for small
/// amounts, so a user splits one large transfer into many tiny ones and pays no
/// fee at all - a fee-bypass value leak for the protocol. The fix charges a
/// minimum fee (or rounds up) on any nonzero transfer.
module move_security_notes::fee_bypass {
    /// VULNERABLE: fee floors to 0 below 10000/bps units.
    public fun fee_vulnerable(amount: u64, bps: u64): u64 {
        amount * bps / 10000
    }

    /// FIXED: charge at least 1 unit on any nonzero fee'd transfer.
    public fun fee_safe(amount: u64, bps: u64): u64 {
        let f = amount * bps / 10000;
        if (f == 0 && amount > 0 && bps > 0) { 1 } else { f }
    }

    #[test]
    fun test_vulnerable_small_amount_pays_zero_fee() {
        // 0.01% (1 bps) on 9_999 rounds to 0 - split a big transfer into 9_999 chunks and pay nothing.
        assert!(fee_vulnerable(9_999, 1) == 0, 1);
    }

    #[test]
    fun test_safe_charges_minimum_and_keeps_normal_case() {
        assert!(fee_safe(9_999, 1) == 1, 2);          // dust transfer now pays the floor
        assert!(fee_safe(1_000_000, 30) == 3000, 3);  // 0.3% normal case unchanged
    }
}
