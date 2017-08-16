module("luci.phicommproduct", package.seeall)

local uci = require("luci.model.uci").cursor()
softversion = uci:get("system", "system", "fw_ver") or "0.0.0.0"
