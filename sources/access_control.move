/// Move-specific access-control bug: a function that operates on a resource
/// identified by an `address` parameter, with no `signer` check - so anyone can
/// act on anyone's resource. In Move, authority comes from holding a `&signer`;
/// trusting a plain `address` argument is the mistake.
module move_security_notes::access_control {
    use std::signer;

    struct Balance has key {
        value: u64,
    }

    /// Create a balance under `account`.
    public fun init(account: &signer, amount: u64) {
        move_to(account, Balance { value: amount });
    }

    public fun balance_of(owner: address): u64 acquires Balance {
        borrow_global<Balance>(owner).value
    }

    /// VULNERABLE: authorizes on a bare `victim: address` - no signer. Anyone can
    /// drain anyone's balance.
    public fun withdraw_vulnerable(victim: address, amount: u64): u64 acquires Balance {
        let b = borrow_global_mut<Balance>(victim);
        b.value = b.value - amount;
        amount
    }

    /// FIXED: only the caller's own resource, keyed by their `&signer`.
    public fun withdraw_safe(account: &signer, amount: u64): u64 acquires Balance {
        let b = borrow_global_mut<Balance>(signer::address_of(account));
        b.value = b.value - amount;
        amount
    }

    #[test(attacker = @0xA, victim = @0xB)]
    fun test_vulnerable_lets_attacker_drain(attacker: &signer, victim: &signer) acquires Balance {
        let _ = attacker;
        init(victim, 100);
        // The attacker calls with the victim's address and drains it.
        let stolen = withdraw_vulnerable(signer::address_of(victim), 100);
        assert!(stolen == 100, 100);
        assert!(balance_of(signer::address_of(victim)) == 0, 101);
    }

    #[test(victim = @0xB)]
    fun test_safe_only_touches_own_balance(victim: &signer) acquires Balance {
        init(victim, 100);
        let got = withdraw_safe(victim, 40);
        assert!(got == 40, 200);
        assert!(balance_of(signer::address_of(victim)) == 60, 201);
    }
}
