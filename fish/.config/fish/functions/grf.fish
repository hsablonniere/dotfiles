function grf --description "Git reflog CSV output piped to tw"
  begin
    echo "Commit|Date|Time|Command|Details|Comment|Branches|Tags"
    git --no-pager reflog --pretty='format:%h|%gD|%gs|%d' --date=iso --decorate=short $argv | node -e '
      let data = "";
      process.stdin.on("data", (chunk) => data += chunk);
      process.stdin.on("end", () => {
        const lines = data.split("\n");
        for (const line of lines) {
          if (!line.trim()) {
            continue
          }
          const parts = line.split("|");
          if (parts.length < 3) {
            continue;
          }
          
          const [commit, gd, gs, decorationsRaw = ""] = parts;
          const [date, time] = gd.match(/^HEAD@{(.*)}$/)[1].split(" ");
          const [command, details = "", comment] = gs.match(/^([^\s:]+)(?:\s+\(([^)]+)\))?\s*:\s+(.+)$/).slice(1);
          const decorations = decorationsRaw.replace(" (", "").replace(")", "");
          const branches = decorations.split(",").filter((d) => !d.startsWith("tag:")).join(",");
          const tags = decorations.split(",").filter((d) => d.startsWith("tag:")).map((t) => t.replace("tag: ", "")).join(",");
          
          console.log([commit, date, time, command, details, comment, branches, tags].join("|"));
        }
      });
    '
  end | tw --separator "|"
end
