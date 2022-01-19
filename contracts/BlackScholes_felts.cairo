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
@external
func ln{
        range_check_ptr
    }(x : felt) -> (res : felt):
    alloc_locals
    local res : felt
    %{
        import math
        full_res = math.log((ids.x.high << 128) +  x.low)
        #log of any 256 bit number is less than 128 bits
        ids.res.high = 0
        ids.res.low = math.floor(full_res)
    %}

    #@dev now we have to assert that e^(result) > x and that e^(result + 1) < x
    
    #low part 
    assert pow(EULER,  )
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
        ids.res = math.exp(ids.x) 
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