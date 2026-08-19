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

More coming: capability/witness confusion, `public` vs `entry`/`friend` exposure,
generic type-parameter authority, and precision/rounding in fixed-point math.

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
