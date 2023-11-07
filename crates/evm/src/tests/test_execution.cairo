use contracts::tests::test_utils as contract_utils;
use evm::execution::execute;
use evm::model::eoa::EOATrait;
use evm::state::StateTrait;
use evm::tests::test_utils::{evm_address, other_evm_address};
use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};

#[test]
#[available_gas(20000000)]
fn test_execute_value_transfer() {
    let (native_token, kakarot_core) = contract_utils::setup_contracts_for_testing();
    // Transfer native tokens to sender
    let sender = EOATrait::deploy(evm_address()).expect('sender deploy failed');
    let recipient = EOATrait::deploy(other_evm_address()).expect('recipient deploy failed');
    // Transfer native tokens to sender
    contract_utils::fund_account_with_native_token(sender.starknet_address, native_token, 10000);
    // When
    let mut exec_result = execute(
        origin: sender.address(),
        target: recipient.address(),
        bytecode: Default::default().span(),
        calldata: Default::default().span(),
        value: 2000,
        gas_price: 0,
        gas_limit: 0,
        read_only: false,
    );
    // `commit_state` is applied in `eth_send_tx` only - to test that `execute` worked correctly, we manually apply it here.
    exec_result.state.commit_state();

    let sender_balance = native_token.balanceOf(sender.starknet_address);
    let recipient_balance = native_token.balanceOf(recipient.starknet_address);

    assert(sender_balance == 8000, 'wrong sender balance');
    assert(recipient_balance == 2000, 'wrong recipient balance');
}