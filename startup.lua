-- startup.lua v1.0
-- Author: Egobooster
-- 22-07-2022
-- startup script for fancymine.lua v1.0 https://pastebin.com/hnQYGiXX

enabled = true
if enabled then
        function mysplit (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
        end

        run_conf = fs.open("run.conf","r")
        line = run_conf.readLine()
        if run_conf == nil or line == nil or line == "" then
                error("nothing to resume;this is not an error don't worry about it")
        end

        run_conf.close()

        c = mysplit(line,";")

        facing = c[1]
        radius = c[2]
        starting_y = c[3]
        search_ore = c[4]

        shell.run("fancymine.lua",
                facing,
                radius,
                starting_y,
                search_ore,
                "--resume")
end