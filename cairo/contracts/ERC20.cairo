%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_check, uint256_le, uint256_lt, uint256_sub)
from starkware.starknet.common.syscalls import get_caller_address

# from starkware.starknet.apps.starkgate.cairo.ERC20_base import (
#     ERC20_allowances, ERC20_approve, ERC20_burn, ERC20_initializer, ERC20_mint, ERC20_transfer,
#     allowance, balanceOf, decimals, name, symbol, totalSupply)
# from starkware.starknet.apps.starkgate.cairo.permitted import (
#     permitted_initializer, permitted_minter, permitted_minter_only, permittedMinter)

# Own contracts
from contracts.ERC20_base import (
    ERC20_allowances, ERC20_approve, ERC20_burn, ERC20_initializer, ERC20_mint, ERC20_transfer,
    allowance, balanceOf, decimals, name, symbol, totalSupply)
from contracts.permitted import (
    permitted_initializer, permitted_minter, permitted_minter_only, permittedMinter)


@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, symbol : felt, decimals : felt, minter_address : felt):
    permitted_initializer(minter_address)
    ERC20_initializer(name, symbol, decimals)
    return ()
end

# Externals.

@external
func transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        recipient : felt, amount : Uint256) -> (success : felt):
    let (sender) = get_caller_address()
    ERC20_transfer(sender, recipient, amount)

    # Cairo equivalent to 'return (true)'
    return (1)
end

@external
func transferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, amount : Uint256) -> (success : felt):
    alloc_locals
    let (local caller) = get_caller_address()
    let (local caller_allowance : Uint256) = ERC20_allowances.read(owner=sender, spender=caller)

    # Validates amount <= caller_allowance and returns 1 if true.
    let (enough_allowance) = uint256_le(amount, caller_allowance)
    assert_not_zero(enough_allowance)

    ERC20_transfer(sender, recipient, amount)

    # Subtract allowance.
    let (new_allowance : Uint256) = uint256_sub(caller_allowance, amount)
    ERC20_allowances.write(sender, caller, new_allowance)

    # Cairo equivalent to 'return (true)'
    return (1)
end

@external
func approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        spender : felt, amount : Uint256) -> (success : felt):
    let (caller) = get_caller_address()
    ERC20_approve(caller, spender, amount)

    # Cairo equivalent to 'return (true)'
    return (1)
end

@external
func increaseAllowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        spender : felt, added_value : Uint256) -> (success : felt):
    alloc_locals
    uint256_check(added_value)
    let (local caller) = get_caller_address()
    let (local current_allowance : Uint256) = ERC20_allowances.read(caller, spender)

    # Add allowance.
    let (local new_allowance : Uint256, is_overflow) = uint256_add(current_allowance, added_value)
    assert (is_overflow) = 0

    ERC20_approve(caller, spender, new_allowance)

    # Cairo equivalent to 'return (true)'
    return (1)
end

@external
func decreaseAllowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        spender : felt, subtracted_value : Uint256) -> (success : felt):
    alloc_locals
    uint256_check(subtracted_value)
    let (local caller) = get_caller_address()
    let (local current_allowance : Uint256) = ERC20_allowances.read(owner=caller, spender=spender)
    let (local new_allowance : Uint256) = uint256_sub(current_allowance, subtracted_value)

    # Validates new_allowance < current_allowance and returns 1 if true.
    let (enough_allowance) = uint256_lt(new_allowance, current_allowance)
    assert_not_zero(enough_allowance)

    ERC20_approve(caller, spender, new_allowance)

    # Cairo equivalent to 'return (true)'
    return (1)
end

@external
func permissionedMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        recipient : felt, amount : Uint256):
    alloc_locals
    permitted_minter_only()
    local syscall_ptr : felt* = syscall_ptr

    ERC20_mint(recipient=recipient, amount=amount)

    return ()
end

@external
func permissionedBurn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account : felt, amount : Uint256):
    alloc_locals
    permitted_minter_only()
    local syscall_ptr : felt* = syscall_ptr

    ERC20_burn(account=account, amount=amount)

    return ()
end
