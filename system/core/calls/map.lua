local value, low, high, low_2, high_2 = ...

local relative_value = (value - low) / (high - low)
local scaled_value = low_2 + (high_2 - low_2) * relative_value
return scaled_value