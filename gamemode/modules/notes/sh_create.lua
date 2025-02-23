
-- Create notes
if (SERVER) then
	util.AddNetworkString("CreateNote")

	hook.Add("KeyPress", "notes_create_KeyPress", function(client, key)
		if (key != IN_RELOAD) then return end

		-- Prevent creating notes too close to any spawn points
		for _, spawn in ipairs(ents.FindByClass("info_player_start")) do
			if (client:GetShootPos():DistToSqr(spawn:GetPos()) >= 10000) then continue end

			EchoNotify(client, "A good message gives breathing room to those beyond. You are too close to a spawn point.")

			return
		end

		-- Prevent creating notes outside the world
		if (!util.IsInWorld(client:GetPos())) then
			EchoNotify(client, "A good message is grounded in reality. You are outside the world.")

			return
		end

		-- Prevent creating notes in the air
		if (!client:IsOnGround()) then
			EchoNotify(client, "A good message is built on solid ground. You are in the air.")

			return
		end

		net.Start("CreateNote")
		net.Send(client)
	end)
else
	function CreateNote(message)
		message = string.Trim(message)
		if (message == "") then return end

		local client = LocalPlayer()
		local position = client:GetPos() + Vector(0, 0, 32)
		local isOffensive = IsOffensive(message)

		-- I kindly ask that you do not abuse this or act with malice.
		-- This game is meant to be a positive experience for everyone.
		-- Please do not ruin that for others.
		http.Post("https://hl2rp.net/echoes/submit.php", {
			map = game.GetMap(),
			pos = position.x .. "," .. position.y .. "," .. position.z,
			explicit = isOffensive and "1" or "0",
			text = message,
		}, function(body, size, headers, code)
			FetchNotes()

			-- If we're here, the note was properly successfully created, so let's save it
			local savedNotes = file.Read("echoesbeyond/writtennotes.txt", "DATA")
			savedNotes = util.JSONToTable(savedNotes and savedNotes != "" and savedNotes or "[]")

			savedNotes[#savedNotes + 1] = {
				map = game.GetMap(),
				pos = position,
				text = message,
				id = tonumber(body),
			}

			file.Write("echoesbeyond/writtennotes.txt", util.TableToJSON(savedNotes))

			if (isOffensive) then
				local profanity = GetConVar("echoes_profanity")

				profanity:SetBool(true)
			end
		end)
	end

	net.Receive("CreateNote", function()
		local ratelimit = nextNote + 60 * #notes

		if (ratelimit > os.time()) then
			EchoNotify("A good message bides its time. You must wait another " .. (string.NiceTime(ratelimit - os.time())) .. " before creating a new Echo.")

			return
		end

		local client = LocalPlayer()

		-- Prevent creating notes too close to other notes
		for _, note in ipairs(notes) do
			if (note.explicit) then continue end
			if ((client:GetPos() + Vector(0, 0, 32)):DistToSqr(note.pos) >= 1000) then continue end

			EchoNotify("A good message needs an identity of its own. You are too close to another Echo.")

			return
		end

		vgui.Create("echoEntry")
	end)
end
