-- transfer_summary.lua — Transfer summary formatter for T-Wallet
-- Usage: lua transfer_summary.lua <from_account> <to_account> <from_formatted> <to_formatted>
-- Output: one-line human-readable transfer summary

local from_account   = arg[1] or "?"
local to_account     = arg[2] or "?"
local from_formatted = arg[3] or "?"
local to_formatted   = arg[4] or "?"

-- Trim leading/trailing whitespace (COBOL fixed-width fields may have padding)
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

from_account   = trim(from_account)
to_account     = trim(to_account)
from_formatted = trim(from_formatted)
to_formatted   = trim(to_formatted)

print(string.format(
    "Transfer: %s -> %s | Sender balance: %s | Recipient balance: %s",
    from_account, to_account, from_formatted, to_formatted
))
