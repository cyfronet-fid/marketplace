const path = require('path');
const fs = require('fs');

const sourceDir = path.join(process.cwd(), "app/javascript");

// Same-named files under $CUSTOMIZATION_PATH/javascript override the
// repository's app/javascript files (like views under $CUSTOMIZATION_PATH/views),
// including the application.js entry point. Files that are not customized
// keep coming from the repository, also when imported from a customized file.
const customizationDir = process.env.CUSTOMIZATION_PATH
  ? path.join(process.env.CUSTOMIZATION_PATH, "javascript")
  : null;

function existingFile(base) {
  for (const candidate of [base, `${base}.js`, path.join(base, "index.js")]) {
    if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) {
      return candidate;
    }
  }
  return null;
}

const customizationPlugin = {
  name: "customization-path",
  setup(build) {
    build.onResolve({ filter: /^\.\.?\// }, (args) => {
      const root = args.resolveDir.startsWith(customizationDir) ? customizationDir : sourceDir;
      const relative = path.relative(root, path.resolve(args.resolveDir, args.path));
      if (relative.startsWith("..")) {
        return undefined;
      }
      const resolved =
        existingFile(path.join(customizationDir, relative)) || existingFile(path.join(sourceDir, relative));
      return resolved ? { path: resolved } : undefined;
    });
  },
};

async function result() {
  const options = {
    entryPoints: [(customizationDir && existingFile(path.join(customizationDir, "application"))) || "application.js"],
    bundle: true,
    outdir: path.join(process.cwd(), "app/assets/builds"),
    absWorkingDir: sourceDir,
    nodePaths: [path.join(process.cwd(), "node_modules")],
    plugins: customizationDir ? [customizationPlugin] : [],
    loader: {
      '.eot': 'dataurl',
      '.gif': 'dataurl',
      '.jpg': 'dataurl',
      '.jpeg': 'dataurl',
      '.png': 'dataurl',
      '.svg': 'dataurl',
      '.ttf': 'dataurl',
      '.webp': 'dataurl',
      '.webm': 'dataurl',
      '.woff': 'dataurl',
      '.woff2': 'dataurl',
    }
  }
  try {
    if (process.argv.slice(2).includes('--watch')) {
      let ctx = await require("esbuild").context(options)
      await ctx.watch();
    } else {
      await require("esbuild").build(options);
    }
  } catch(error) { console.log(error); }
}

result();
