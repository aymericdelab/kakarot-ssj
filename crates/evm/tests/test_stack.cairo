// Core lib imports

// Internal imports
use evm::stack::StackTrait;
use utils::constants;

#[test]
fn test_stack_new_should_return_empty_stack() {
    // When
    let mut stack = StackTrait::new();

    // Then
    assert(stack.len() == 0, 'stack length should be 0');
}

#[test]
fn test_empty_should_return_if_stack_is_empty() {
    // Given
    let mut stack = StackTrait::new();

    // Then
    assert(stack.is_empty() == true, 'stack should be empty');

    // When
    stack.push(1).unwrap();
    // Then
    assert(stack.is_empty() == false, 'stack should not be empty');
}

#[test]
fn test_len_should_return_the_length_of_the_stack() {
    // Given
    let mut stack = StackTrait::new();

    // Then
    assert(stack.len() == 0, 'stack length should be 0');

    // When
    stack.push(1).unwrap();
    // Then
    assert(stack.len() == 1, 'stack length should be 1');
}

mod push {
    use evm::errors::{EVMError};
    use super::StackTrait;

    use super::constants;

    #[test]
    fn test_should_add_an_element_to_the_stack() {
        // Given
        let mut stack = StackTrait::new();

        // When
        stack.push(1).unwrap();

        // Then
        let res = stack.peek().unwrap();

        assert(stack.is_empty() == false, 'stack should not be empty');
        assert(stack.len() == 1, 'len should be 1');
        assert(res == 1, 'wrong result');
    }

    #[test]
    fn test_should_fail_when_overflow() {
        // Given
        let mut stack = StackTrait::new();
        let mut i = 0;

        // When
        loop {
            if i == constants::STACK_MAX_DEPTH {
                break;
            }
            i += 1;

            stack.push(1).unwrap();
        };

        // Then
        let res = stack.push(1);
        assert(stack.len() == constants::STACK_MAX_DEPTH, 'wrong length');
        assert(res.is_err(), 'should return error');
        assert(res.unwrap_err() == EVMError::StackOverflow, 'should return StackOverflow');
    }
}

mod pop {
    use evm::errors::{EVMError, TYPE_CONVERSION_ERROR};
    use starknet::storage_base_address_const;
    use super::StackTrait;
    use utils::traits::StorageBaseAddressPartialEq;

    #[test]
    fn test_should_pop_an_element_from_the_stack() {
        // Given
        let mut stack = StackTrait::new();
        stack.push(1).unwrap();
        stack.push(2).unwrap();
        stack.push(3).unwrap();

        // When
        let last_item = stack.pop().unwrap();

        // Then
        assert(last_item == 3, 'wrong result');
        assert(stack.len() == 2, 'wrong length');
    }


    #[test]
    fn test_should_pop_N_elements_from_the_stack() {
        // Given
        let mut stack = StackTrait::new();
        stack.push(1).unwrap();
        stack.push(2).unwrap();
        stack.push(3).unwrap();

        // When
        let elements = stack.pop_n(3).unwrap();

        // Then
        assert(stack.len() == 0, 'wrong length');
        assert(elements.len() == 3, 'wrong returned array length');
        assert(*elements[0] == 3, 'wrong result at index 0');
        assert(*elements[1] == 2, 'wrong result at index 1');
        assert(*elements[2] == 1, 'wrong result at index 2');
    }


    #[test]
    fn test_pop_return_err_when_stack_underflow() {
        // Given
        let mut stack = StackTrait::new();

        // When & Then
        let result = stack.pop();
        assert(result.is_err(), 'should return Err ');
        assert!(result.unwrap_err() == EVMError::StackUnderflow, "should return StackUnderflow");
    }

    #[test]
    fn test_pop_n_should_return_err_when_stack_underflow() {
        // Given
        let mut stack = StackTrait::new();
        stack.push(1).unwrap();

        // When & Then
        let result = stack.pop_n(2);
        assert(result.is_err(), 'should return Error');
        assert!(result.unwrap_err() == EVMError::StackUnderflow, "should return StackUnderflow");
    }
}

mod peek {
    use evm::errors::{EVMError};
    use super::StackTrait;

    #[test]
    fn test_should_return_last_item() {
        // Given
        let mut stack = StackTrait::new();

        // When
        stack.push(1).unwrap();
        stack.push(2).unwrap();

        // Then
        let last_item = stack.peek().unwrap();
        assert(last_item == 2, 'wrong result');
    }


    #[test]
    fn test_should_return_stack_at_given_index_when_value_is_0() {
        // Given
        let mut stack = StackTrait::new();
        stack.push(1).unwrap();
        stack.push(2).unwrap();
        stack.push(3).unwrap();

        // When
        let result = stack.peek_at(0).unwrap();

        // Then
        assert(result == 3, 'wrong result');
    }

    #[test]
    fn test_should_return_stack_at_given_index_when_value_is_1() {
        // Given
        let mut stack = StackTrait::new();
        stack.push(1).unwrap();
        stack.push(2).unwrap();
        stack.push(3).unwrap();

        // When
        let result = stack.peek_at(1).unwrap();

        // Then
        assert(result == 2, 'wrong result');
    }

    #[test]
    fn test_should_return_err_when_underflow() {
        // Given
        let mut stack = StackTrait::new();

        // When & Then
        let result = stack.peek_at(1);

        assert(result.is_err(), 'should return an EVMError');
        assert!(result.unwrap_err() == EVMError::StackUnderflow, "should return StackUnderflow");
    }
}

mod swap {
    use evm::errors::{EVMError};
    use super::StackTrait;

    #[test]
    fn test_should_swap_2_stack_items() {
        // Given
        let mut stack = StackTrait::new();
        stack.push(1).unwrap();
        stack.push(2).unwrap();
        stack.push(3).unwrap();
        stack.push(4).unwrap();
        let index3 = stack.peek_at(3).unwrap();
        assert(index3 == 1, 'wrong index3');
        let index2 = stack.peek_at(2).unwrap();
        assert(index2 == 2, 'wrong index2');
        let index1 = stack.peek_at(1).unwrap();
        assert(index1 == 3, 'wrong index1');
        let index0 = stack.peek_at(0).unwrap();
        assert(index0 == 4, 'wrong index0');

        // When
        stack.swap_i(2).expect('swap failed');

        // Then
        let index3 = stack.peek_at(3).unwrap();
        assert(index3 == 1, 'post-swap: wrong index3');
        let index2 = stack.peek_at(2).unwrap();
        assert(index2 == 4, 'post-swap: wrong index2');
        let index1 = stack.peek_at(1).unwrap();
        assert(index1 == 3, 'post-swap: wrong index1');
        let index0 = stack.peek_at(0).unwrap();
        assert(index0 == 2, 'post-swap: wrong index0');
    }

    #[test]
    fn test_should_return_err_when_index_1_is_underflow() {
        // Given
        let mut stack = StackTrait::new();

        // When & Then
        let result = stack.swap_i(1);

        assert(result.is_err(), 'should return an EVMError');
        assert!(result.unwrap_err() == EVMError::StackUnderflow, "should return StackUnderflow");
    }

    #[test]
    fn test_should_return_err_when_index_2_is_underflow() {
        // Given
        let mut stack = StackTrait::new();
        stack.push(1).unwrap();

        // When & Then
        let result = stack.swap_i(2);

        assert(result.is_err(), 'should return an EVMError');
        assert!(result.unwrap_err() == EVMError::StackUnderflow, "should return StackUnderflow");
    }
}
