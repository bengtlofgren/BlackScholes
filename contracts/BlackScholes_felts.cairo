%builtin range_check_ptr

from starkware.cairo.common.math import (unsigned_div_rem, floor, sqrt, abs_value)


const SECONDS_PER_YEAR = 31536000
const PRECISE_UNIT = 10**27
const LN_2_PRECISE = 693147180559945309417232122
const SQRT_TWOPI = 2506628274631000502415765285
const MIN_CDF_STD_DIST_INPUT = ((PRECISE_UNIT) * -45) / 10
const MAX_CDF_STD_DIST_INPUT = PRECISE_UNIT * 10
const MIN_EXP = -63 * PRECISE_UNIT
const MAX_EXP = 100 * PRECISE_UNIT
const MIN_T_ANNUALISED = PRECISE_UNIT / SECONDS_PER_YEAR
const MIN_VOLATILITY = PRECISE_UNIT / 10000
const VEGA_STANDARDISATION_MIN_DAYS = 7 # days TODO

#@dev note that eulers is to 18 decimals here!! 27 seemed excessive imo
const EULER = 271828182845904523
#@dev log2(EULER) = 59.6 ... so 60 is upper bound
#@dev for reference: const EULER = 2 7182 8182 8459 0452 3536 0287 4713 527

#
# @dev Returns absolute value of an int as a uint.
#

from starkware.cairo.common.math_cmp import is_le_felt
func lnFrac{range_check_ptr}(frac: felt, delta : felt) -> (res:felt):
    alloc_locals
    
    #This is broken, but should give a good answer. If we can use this for ln,  
    # then we can use it in verifying exp

    let (end_reached) = is_le_felt(delta, 2)
    if end_reached == 1:
        # When last iteration is reached, return 0.
        return (res=0)
    end

    let (local new_delta, _) = unsigned_div_rem(delta,2)
    let (is_g_2) = is_le_felt(frac*frac*10, 2*PRECISION*PRECISION)
    let (local new_frac, _) = unsigned_div_rem(frac*frac, (1+is_g_2)*PRECISION)
    let (res) = lnFrac(new_frac, new_delta)
    
    # Add the new value `n` to the sum.
    let new_res = res + delta*(1-is_g_2)
    
    return (res=new_res)
end


# @dev Returns the floor of a PRECISE_UNIT (x - (x % 1e27))
func floor{
        range_check_ptr
    }(x : felt) -> (res : felt):
    alloc_locals
    local res : felt
    %{
        ids.res = ids.x - (ids.x % ids.PRECISE_UNIT)
    %}
    assert res 
    return (res)
end

#
# @dev Returns the natural log of the value using Halley's method.
#
func ln{
        range_check_ptr
    }(x : felt) -> (res : felt):
    alloc_locals
    local res : felt
    %{
        import math
        full_res = math.log(ids.x)/math.log(ids.EULER)
        ids.res= math.floor(full_res)
    %}
    

     #@dev now we have to assert that e^(result) > x and that e^(result + 1) < x
     # NOTE THAT X CANNOT BE > 2^190 and assumes x is already with 18 decimals
    let (local low) = pow(EULER, res)
    tempvar check = low*EULER - low
    let (local c) = is_le_felt(check, test*EULER*EULER)
    let (local d) = is_le_felt(test*EULER, check)
    assert c+d = 2

    return (res)
end

#
# @dev Returns the exponent of the value using taylor expansion with range reduction.
#
@external
func exp{
        range_check_ptr
    }(x : felt) -> (res : felt):
    alloc_locals
    local res : felt
    %{
        import math
        assert ids.x <= MAX_EXP
        if x == 0:
            ids.res = PRECISE_UNIT
        ids.res = math.exp(ids.x) * math.pow(10,ids.x)
    %}
    return (res)
end

# func d1{
#     syscall_ptr : felt*, 
#     pedersen_ptr : HashBuiltin*, 
#     range_check_ptr
# }(tAnnualised : Uint256,
#         volatility : Uint256,
#         spot : Uint256,
#         strike : Uint256,
#         rate : Uint256) -> (res: Uint256):
#     alloc_locals
#     let (local sqrtT) : Uint256 = 
#     let 

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
const PRECISION1 = 10**18
const SHIFT = 2 ** 128

#Make all decimals fit in final 64 bits 
struct Uint128x64:
    # The low 64 bits of the decimal value.
    member decimal : felt
    # The high 128 bits of the integer value.
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

    let (res0, carry) = split_64(a.decimal * b.decimal)
    let (res1, carry) = split_64(a.high * b.low + a.low * b.high + carry)
    let (res2, carry) = split_64(a.high*b.high + carry)
    
    tempvar low = res1*HALF_SHIFT + res0
    tempvar high = carry*SHIFT + res2*HALF_SHIFT
    local lowfix : felt
    local remainder : felt
    
    %{
    ids.lowfix = ids.low // ids.PRECISION1
        %}
    let (check) = is_le_felt(lowfix*PRECISION1, low)
    let (check2) = is_le_felt(low, lowfix*PRECISION1*10)
    assert check+check2 = 2
    return (
        # Uint128x128(low= res0 + res1*HALF_SHIFT , high= carry*HALF_SHIFT + res2 ),
        Uint128x64(low= lowfix, high= high )
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
