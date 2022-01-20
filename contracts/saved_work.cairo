# The following code prints the sum of the numbers from 1 to 10.
# Modify the function `compute_sum` to print all the intermediate sums:
# 1, 1 + 2, 1 + 2 + 3, ..., 1 + 2 + ... + 10.
# Note: you'll have to add the implicit argument output_ptr to the
# declaration of compute_sum (in order to use the serialize_word function):
#   func compute_sum{output_ptr : felt*}(n : felt) -> (sum : felt):

# Use the output builtin.
%builtins output range_check

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.pow import pow
# from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.uint256 import split_64

const HALF_SHIFT = 2 ** 64
const TEST = 27182818284590452353602
const PRECISION = 10000000000000000000000
const PRECISION2 = 19
const SHIFT = 2 ** 128

#Make all decimals fit in final 64 bits 
#18 decimals points is 60 shifts

struct Uint128x64:
    # The low 64 bits of the value.
    member low : felt
    # The high 128 bits of the value.
    member high : felt
end

struct Uint128x128:
    # The low 128 bits of the value.
    member low : felt
    # The high 128 bits of the value.
    member high : felt
end

func mul_64{range_check_ptr}(a : Uint128x64, b : Uint128x64) -> (res: Uint128x64):
    alloc_locals
    let (a1, a2) = split_64(a.high)
    let (b1, b2) = split_64(b.high)
    
    let (res0, carry) = split_64(a.low * b.low)
    let (res1, carry) = split_64(a1 * b.low + a.low * b1 + carry)
    let (res2, carry) = split_64(a2 * b.low + a1 * b1 + a.low * b2 + carry)
    let (res3, carry) = split_64(a2 * b1 + a1 * b2 + carry)
    let (res4, carry) = split_64(a2*b2 + carry)
    
    local fix : felt
    %{
    import math
    ids.fix = math.floor(
        ids.res0/(ids.SHIFT) + ids.res1/(ids.HALF_SHIFT) + 
        ids.res2 + ids.res3*ids.HALF_SHIFT + ids.res4*ids.SHIFT
        + ids.carry*ids.SHIFT*ids.HALF_SHIFT
        %}
    let (check1) = is_le_felt(fix*PRECISION2, low + high*SHIFT)
    let (check2) = is_le_felt(low+ high*SHIFT, fix*PRECISION1*10)
    assert check1+check2 = 2
    
    let (lowfix, highfix) = split_64(fix)
    return (
        # Uint128x128(low= res0 + res1*HALF_SHIFT , high= carry*HALF_SHIFT + res2 ),
        Uint128x64(low= lowfix, high= highfix)
        )
end


func main{output_ptr : felt*, range_check_ptr: felt}():
    alloc_locals
    let (local a, b) = split_64(TEST)
    let (local c,d)  = split_64(PRECISION)
    let (res) = mul_64(Uint128x64(low=a,high= b), Uint128x64(low =c, high = d)) 

    # Output the result.
    serialize_word(a)
    serialize_word(b)
    serialize_word(a + b*HALF_SHIFT)
    serialize_word(c)
    serialize_word(d)
    serialize_word(c + d*HALF_SHIFT)
    serialize_word(res.low)
    serialize_word(res.low - PRECISION1)
    serialize_word(res.high)
    tempvar result = res.low + res.high*HALF_SHIFT
    # let (res2low, res2high) = split_64(result)
    serialize_word(result)
    serialize_word(res.high*HALF_SHIFT)
    # serialize_word(res2low + res2high*HALF_SHIFT)
    return ()
end
