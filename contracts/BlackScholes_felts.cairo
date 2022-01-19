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