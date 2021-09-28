
require("dotenv")
require("@metis.io/hardhat-mvm")

module.exports = require("@chimera-defi/hardhat-framework").config.hardhat(require("./settings").hardhat)

// flattener
require("@chimera-defi/hardhat-framework").flattener();

const fs = require("fs");
const path = require("path");

task("flattenAll", "Flatten all files we care about").setAction(async ({ }, { run }) => {
  let srcpath = "contracts";
  let files = fs.readdirSync(srcpath).map(file => `${srcpath}/${file}`);

  await Promise.all(
    files.map(async file => {
      if (path.extname(file) == ".sol") {
        await run("flat:get-flattened-sources", {
          files: [file],
          output: `./flats/${file}`,
        });
      }
    }),
  );
});
