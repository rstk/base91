--#selene: allow(undefined_variable)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
	local Base91 = require(ReplicatedStorage.Base91)

	local function RandomBitStream(n)
		local data = table.create(n)
		for i = 1, n do
			data[i] = math.floor(math.random() * (2^32-1))
		end
		return data
	end

	local function RandomEncodedData(n)
		local characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~'"
		local data = table.create(n)
		for i = 1, n do
			local index = math.random(1, 91)
			data[i] = string.sub(characters, index, index)
		end
		return table.concat(data)
	end

	it("Should encode without failing", function()
		for _ = 1, 32 do
			local dataToEncode = RandomBitStream(256)

			expect(function()
				Base91.Encode(dataToEncode)
			end).never.to.throw()
		end
	end)

	it("Should decode without failing", function()
		for _ = 1, 32 do
			local dataToDecode = RandomEncodedData(256)

			expect(function()
				Base91.Decode(dataToDecode)
			end).never.to.throw()
		end
	end)

	it("Should return the same data after encoding/decoding", function()
		local function encodeDecode(data)
			local decoded = Base91.Decode(Base91.Encode(data))
			decoded = Base91.Decode(Base91.Encode(decoded))

			for index, value in ipairs(data) do
				expect(value).to.be.equal(decoded[index])
			end
		end

		for _ = 1, 256 do
			encodeDecode(RandomBitStream(math.random(64, 1024)))
		end
	end)
end