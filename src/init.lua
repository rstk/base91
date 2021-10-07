-- base91^0.1.0
-- Copyright (c) 2021, rstk
-- All rights reserved.
-- Distributed under the 3-Clause BSD License.
-- https://github.com/rstk/base91

-- BasE91 has been developed by Joachim Henke under the [3-Clause BSD License](http://base91.sourceforge.net/license.txt).

type Array<T> = {[number]: T}

local Base91 = {}

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

function Base91.Encode(stream: Array<number>): string
	local streamIndex = 2
	local buffer = stream[1]
	local bufferIndex = 0
	local output = table.create(32 * #stream / 13 + 1)
	local outputIndex = 1

	while streamIndex <= #stream+1 do
		-- read the first 13 bits
		local v
		if bufferIndex + 13 <= 32 then
			v = bit32.extract(buffer, bufferIndex, 13)
			bufferIndex += 13
		else
			-- read the first bits
			local b = 32 - bufferIndex
			local r = bufferIndex - 19
			v = b > 0 and bit32.extract(buffer, bufferIndex, b) or 0
			buffer = stream[streamIndex] or 0
			streamIndex += 1
			v = bit32.replace(v, buffer, b, r)
			bufferIndex = r
		end

		if v <= 88 then
			if bufferIndex ~= 32 then
				v += bit32.extract(buffer, bufferIndex, 1) * 8192
				bufferIndex += 1
			else
				buffer = stream[streamIndex] or 0
				streamIndex += 1
				v += buffer % 2 * 8192
				bufferIndex = 1
			end
		end

		local i0 = v % 91
		local i1 = (v - i0) / 91

		output[outputIndex] = Alphabet[i0] .. Alphabet[i1]
		outputIndex += 1
	end

	return table.concat(output)
end

function Base91.Decode(stream: string): Array<number>
	local buffer = 0
	local bufferIndex = 0
	local output = table.create(#stream / 2 * 13 / 32 + 1)
	local outputIndex = 1

	for streamIndex = 1, #stream/2 do
		local i0, i1 = string.byte(stream, streamIndex * 2 - 1, streamIndex * 2)
		local value = InverseAlphabet[i1] * 91 + InverseAlphabet[i0]
		local nBits = value % 8192 > 88 and 13 or 14

		if bufferIndex + nBits <= 32 then
			buffer = bit32.replace(buffer, value, bufferIndex, nBits)
			bufferIndex += nBits
		else
			local w = 32 - bufferIndex
			output[outputIndex] = w > 0 and bit32.replace(buffer, value, bufferIndex, w) or buffer
			outputIndex += 1
			buffer = bit32.extract(value, w, nBits - w)
			bufferIndex = (bufferIndex + nBits) % 32
		end
	end

	if bufferIndex ~= 0 then
		output[outputIndex] = buffer
	end

	return output
end

return Base91
