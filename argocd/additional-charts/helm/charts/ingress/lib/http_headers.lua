-- Copyright (c) 2013, James Hurst
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:

--   Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.

--   Redistributions in binary form must reproduce the above copyright notice, this
--   list of conditions and the following disclaimer in the documentation and/or
--   other materials provided with the distribution.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
-- ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

local rawget, rawset, setmetatable =
    rawget, rawset, setmetatable

local str_lower = string.lower

local _M = {
    _VERSION = '0.16.1',
}


-- Returns an empty headers table with internalised case normalisation.
function _M.new()
    local mt = {
        normalised = {},
    }

    mt.__index = function(t, k)
        return rawget(t, mt.normalised[str_lower(k)])
    end

    mt.__newindex = function(t, k, v)
        local k_normalised = str_lower(k)

        -- First time seeing this header field?
        if not mt.normalised[k_normalised] then
            -- Create a lowercased entry in the metatable proxy, with the value
            -- of the given field case
            mt.normalised[k_normalised] = k

            -- Set the header using the given field case
            rawset(t, k, v)
        else
            -- We're being updated just with a different field case. Use the
            -- normalised metatable proxy to give us the original key case, and
            -- perorm a rawset() to update the value.
            rawset(t, mt.normalised[k_normalised], v)
        end
    end

    return setmetatable({}, mt)
end


return _M