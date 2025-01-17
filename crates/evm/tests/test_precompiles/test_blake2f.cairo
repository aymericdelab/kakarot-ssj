use contracts::test_utils::{setup_contracts_for_testing};
use core::array::SpanTrait;
use evm::errors::EVMError;
use evm::instructions::memory_operations::MemoryOperationTrait;
use evm::instructions::system_operations::SystemOperationsTrait;
use evm::interpreter::EVMTrait;
use evm::memory::InternalMemoryTrait;
use evm::memory::MemoryTrait;
use evm::precompiles::blake2f::Blake2f;
use evm::stack::StackTrait;
use evm::test_utils::{VMBuilderTrait, native_token, other_starknet_address};
use starknet::testing::set_contract_address;
use super::test_data::test_data_blake2f::{
    blake2_precompile_fail_wrong_length_input_1_test_case,
    blake2_precompile_fail_wrong_length_input_2_test_case,
    blake2_precompile_fail_wrong_length_input_3_test_case, blake2_precompile_pass_1_test_case,
    blake2_precompile_pass_0_test_case, blake2_precompile_pass_2_test_case
};
use utils::helpers::FromBytes;

#[test]
fn test_blake2_precompile_fail_empty_input() {
    let calldata = array![];

    let res = Blake2f::exec(calldata.span());
    assert_eq!(res, Result::Err(EVMError::InvalidParameter('Blake2: wrong input length')));
}

#[test]
fn test_blake2_precompile_fail_wrong_length_input_1() {
    let (calldata, _) = blake2_precompile_fail_wrong_length_input_1_test_case();

    let res = Blake2f::exec(calldata);
    assert_eq!(res, Result::Err(EVMError::InvalidParameter('Blake2: wrong input length')));
}
#[test]
fn test_blake2_precompile_fail_wrong_length_input_2() {
    let (calldata, _) = blake2_precompile_fail_wrong_length_input_2_test_case();

    let res = Blake2f::exec(calldata);
    assert_eq!(res, Result::Err(EVMError::InvalidParameter('Blake2: wrong input length')));
}

#[test]
fn test_blake2_precompile_fail_wrong_final_block_indicator_flag() {
    let (calldata, _) = blake2_precompile_fail_wrong_length_input_3_test_case();

    let res = Blake2f::exec(calldata);
    assert_eq!(res, Result::Err(EVMError::InvalidParameter('Blake2: wrong final indicator')));
}

#[test]
fn test_blake2_precompile_pass_1() {
    let (calldata, expected_result) = blake2_precompile_pass_1_test_case();
    let rounds: u32 = calldata.slice(0, 4).from_be_bytes().unwrap();

    let (gas, result) = Blake2f::exec(calldata).unwrap();

    assert_eq!(result, expected_result);
    assert_eq!(gas, rounds.into());
}

#[test]
fn test_blake2_precompile_pass_0() {
    let (calldata, expected_result) = blake2_precompile_pass_0_test_case();
    let rounds: u32 = calldata.slice(0, 4).from_be_bytes().unwrap();

    let (gas, result) = Blake2f::exec(calldata).unwrap();

    assert_eq!(result, expected_result);
    assert_eq!(gas, rounds.into());
}

#[test]
fn test_blake2_precompile_pass_2() {
    let (calldata, expected_result) = blake2_precompile_pass_2_test_case();
    let rounds: u32 = calldata.slice(0, 4).from_be_bytes().unwrap();

    let (gas, result) = Blake2f::exec(calldata).unwrap();

    assert_eq!(result, expected_result);
    assert_eq!(gas, rounds.into());
}

// source: <https://www.evm.codes/playground?unit=Wei&codeType=Mnemonic&code='yExecuteBest%20vector%205%20from%20https:Keips.Ghereum.org/EIPS/eip-152XroundJ12~3DhZ48c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5~4jZd182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b~36jXmZ616263))))*~68jXt~3~196Df~1~212DCallW(rGS!rGOVQargsSize~0_argsOV~9_addresJ0xFFFFFFFF_gaswSTATICCALLXRGurnBhe%20result%20ofWwPOP(s!oVwRETURN'~Y1_K%20w%5Cnq***0jwMSTORE_%20yZY32%200xYwPUSHXwwyW%20blake2fVffsGQ~213_K//JsY4%20GetDj8XB%20t*00)qq(~64_!izeQ%01!()*BDGJKQVWXYZ_jqwy~_>
#[test]
fn test_blake2_precompile_static_call() {
    let (_, _) = setup_contracts_for_testing();

    let mut vm = VMBuilderTrait::new_with_presets().build();

    // rounds
    vm.stack.push(12).unwrap();
    vm.stack.push(3).unwrap();
    vm.exec_mstore8().unwrap();

    // h
    vm.stack.push(0x48c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5).unwrap();
    vm.stack.push(4).unwrap();
    vm.exec_mstore().unwrap();
    vm.stack.push(0xd182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b).unwrap();
    vm.stack.push(36).unwrap();
    vm.exec_mstore().unwrap();

    // m
    vm.stack.push(0x6162630000000000000000000000000000000000000000000000000000000000).unwrap();
    vm.stack.push(68).unwrap();
    vm.exec_mstore().unwrap();

    // t
    vm.stack.push(3).unwrap();
    vm.stack.push(196).unwrap();
    vm.exec_mstore8().unwrap();

    // f
    vm.stack.push(1).unwrap();
    vm.stack.push(212).unwrap();
    vm.exec_mstore8().unwrap();

    vm.stack.push(64).unwrap(); // retSize
    vm.stack.push(213).unwrap(); // retOffset
    vm.stack.push(213).unwrap(); // argsSize
    vm.stack.push(0).unwrap(); // argsOffset
    vm.stack.push(9).unwrap(); // address
    vm.stack.push(0xFFFFFFFF).unwrap(); // gas

    vm.exec_staticcall().unwrap();

    let mut result: Array<u8> = Default::default();
    vm.memory.load_n(64, ref result, 213);

    let (_, expected_result) = blake2_precompile_pass_1_test_case();

    assert_eq!(result.span(), expected_result);
}
