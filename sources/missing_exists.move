/// A function that borrows a resource which may not exist aborts - and in Move an
/// abort reverts the whole transaction. A griefer who never initializes their
/// account can then brick any shared flow that touches it (a denial of service).
/// The fix is to check `exists<T>` and degrade gracefully.
module move_security_notes::missing_exists {
    use std::signer;

    struct Vault has key { balance: u64 }

    public fun open(account: &signer) {
        move_to(account, Vault { balance: 0 });
    }

    /// VULNERABLE: aborts when `user` never opened a Vault.
    public fun balance_vulnerable(user: address): u64 acquires Vault {
        borrow_global<Vault>(user).balance
    }

    /// FIXED: treat an absent resource as zero instead of aborting.
    public fun balance_safe(user: address): u64 acquires Vault {
        if (exists<Vault>(user)) { borrow_global<Vault>(user).balance } else { 0 }
    }

    #[test(user = @0xB)]
    fun test_open_then_read(user: &signer) acquires Vault {
        open(user);
        assert!(balance_safe(signer::address_of(user)) == 0, 1);
        assert!(balance_vulnerable(signer::address_of(user)) == 0, 2);
    }

    #[test]
    #[expected_failure]
    fun test_vulnerable_aborts_on_missing_account() acquires Vault {
        balance_vulnerable(@0xDEAD); // no Vault at 0xDEAD -> abort (DoS)
    }

    #[test]
    fun test_safe_returns_zero_on_missing_account() acquires Vault {
        assert!(balance_safe(@0xDEAD) == 0, 3);
    }
}
