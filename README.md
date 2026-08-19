# move-security-notes

The same idea as my Solidity
[contract-security-notes](https://github.com/dngr2/contract-security-notes),
carried to Move (Aptos): the ways a Move module loses money or control while every
line looks correct. Each finding is a vulnerable/fixed pair with a Move unit test
that carries out the exploit.

Move closes off a lot of Solidity's footguns — arithmetic aborts on overflow,
resources can't be copied or silently dropped — so the bugs that remain are
different in character. They cluster around **authority**: who holds the `&signer`,
who holds a capability, and which functions trust a bare `address`.

## Findings

| # | Module | Bug |
|---|--------|-----|
| 1 | `access_control` | A function authorizes on a bare `victim: address` argument instead of a `&signer`, so anyone can act on anyone's resource and drain it. The fix keys the operation to `signer::address_of(account)`. |
| 2 | `precision` | Floored integer division mints **zero** shares for a nonzero deposit priced against a high asset:share ratio — the depositor pays and gets nothing, and nothing aborts. The fix rejects a deposit that would mint nothing (or uses a virtual-shares offset). |
| 3 | `missing_exists` | A function borrows a resource that may be absent, so the transaction aborts — and a griefer who never initializes their account can brick any shared flow that touches it (denial of service). The fix checks `exists<T>` and degrades gracefully. |

More coming: capability/witness confusion, `public` vs `entry`/`friend` exposure,
and generic type-parameter authority.

## Run

```bash
aptos move test
```

```
[ PASS ] 0xcafe::access_control::test_vulnerable_lets_attacker_drain
[ PASS ] 0xcafe::access_control::test_safe_only_touches_own_balance
```

## Note on toolchain

`Move.toml` pins `AptosFramework` to the `aptos-cli-v4.1.0` tag so the framework
and the compiler are the same Move edition. Bump both together if you upgrade the
CLI.
