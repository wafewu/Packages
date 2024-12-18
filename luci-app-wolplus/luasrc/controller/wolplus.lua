module("luci.controller.wolplus", package.seeall)
local NIXIO_FS = require("nixio.fs")
local LUCI_HTTP = require("luci.http")
local LUCI_UCI = require("luci.model.uci").cursor()

function index()
	if not NIXIO_FS.access("/etc/config/wolplus") then return end
	entry({"admin", "services", "wolplus"}, cbi("wolplus"), _("Wake on LAN +"), 95).dependent = true
	entry( {"admin", "services", "wolplus", "awake"}, post("awake") ).leaf = true
end

function awake(sections)
	lan = LUCI_UCI:get("wolplus", sections, "maceth")
	mac = LUCI_UCI:get("wolplus", sections, "macaddr")
	cmd = "/usr/bin/etherwake -D -i " .. lan .. " -b " .. mac .. " 2>&1"
	local e = {}
	local p = io.popen(cmd)
	local msg = ""
	if p then
		while true do
			local l = p:read("*l")
			if l then
				if #l > 100 then l = l:sub(1, 100) .. "..." end
				msg = msg .. l
			else
				break
			end
		end
		p:close()
	end
	e["data"] = msg
	LUCI_HTTP.prepare_content("application/json")
	LUCI_HTTP.write_json(e)
end
