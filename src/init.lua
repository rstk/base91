-- rbase91^0.1.0
-- Copyright (c) 2021, rstk
-- All rights reserved.
-- Distributed under the 3-Clause BSD License.
-- https://github.com/rstk/rbase91

-- BasE91 has been developed by Joachim Henke under the [3-Clause BSD License](http://base91.sourceforge.net/license.txt).

type BitStream = {[number]: number}

local rBasE91 = {}

local Alphabet = {}
local InverseAlphabet = {}
do
	local characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~'"

	for i = 1, 91 do
		local char = string.sub(characters, i, i)
		Alphabet[i-1] = char
		InverseAlphabet[string.byte(char)] = i-1
	end
end

function rBasE91.Encode(stream: BitStream): string
	local streamLength = #stream
	local buffer = stream[1]
	local bufIndex = 0
	local streamIndex = 2
	local output = table.create(32 * streamLength / 13 + 1)
	local outIndex = 1

	while streamIndex <= streamLength+1 do
		-- read the first 13 bits
		local v
		if bufIndex + 13 <= 32 then
			v = bit32.extract(buffer, bufIndex, 13)
			bufIndex += 13
		else
			-- read the first bits
			local b = 32 - bufIndex
			local r = bufIndex - 19
			v = b > 0 and bit32.extract(buffer, bufIndex, b) or 0
			buffer = stream[streamIndex] or 0
			streamIndex += 1
			v = bit32.replace(v, buffer, b, r)
			bufIndex = r
		end

		if v <= 88 then
			if bufIndex ~= 32 then
				v += bit32.extract(buffer, bufIndex, 1) * 8192
				bufIndex += 1
			else
				buffer = stream[streamIndex] or 0
				streamIndex += 1
				v += buffer % 2 * 8192
				bufIndex = 1
			end
		end

		local i0 = v % 91
		local i1 = (v - i0) / 91

		output[outIndex] = Alphabet[i0] .. Alphabet[i1]
		outIndex += 1
	end

	return table.concat(output)
end


function rBasE91.Decode(stream: string): BitStream
	local buffer = 0
	local bufIndex = 0
	local output = table.create(#stream / 2 * 13 / 32 + 1)
	local outIndex = 1

	for streamIndex = 1, #stream/2 do
		local i0, i1 = string.byte(stream, streamIndex * 2 - 1, streamIndex * 2)
		local value = InverseAlphabet[i1] * 91 + InverseAlphabet[i0]
		local nBits = value % 8192 > 88 and 13 or 14

		if bufIndex + nBits <= 32 then
			buffer = bit32.replace(buffer, value, bufIndex, nBits)
			bufIndex += nBits
		else
			local w = 32 - bufIndex
			output[outIndex] = w > 0 and bit32.replace(buffer, value, bufIndex, w) or buffer
			outIndex += 1
			buffer = bit32.extract(value, w, nBits - w)
			bufIndex = (bufIndex + nBits) % 32
		end
	end

	if bufIndex ~= 0 then
		output[outIndex] = buffer
	end

	return output
end

return rBasE91
