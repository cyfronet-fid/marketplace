const path = require("path");
const fs = require("fs");
const sass = require("sass");

const sourceDir = path.join(process.cwd(), "app/assets/stylesheets");
const outFile = path.join(process.cwd(), "app/assets/builds/application.css");

// Same-named files under $CUSTOMIZATION_PATH/stylesheets override the
// repository's app/assets/stylesheets files (like views under
// $CUSTOMIZATION_PATH/views), including the application.scss entry and
// partials imported from a repository file. Files that are not customized
// keep coming from the repository; bare imports resolve from node_modules.
const customizationDir = process.env.CUSTOMIZATION_PATH
  ? path.join(process.env.CUSTOMIZATION_PATH, "stylesheets")
  : null;
const roots = customizationDir ? [customizationDir, sourceDir] : [sourceDir];

function candidates(relative) {
  const dir = path.dirname(relative);
  const name = path.basename(relative);
  if (/\.(scss|css)$/.test(name)) {
    return [name, `_${name}`].map((n) => path.join(dir, n));
  }
  return [
    `_${name}.scss`,
    `${name}.scss`,
    path.join(name, "_index.scss"),
    path.join(name, "index.scss"),
    `_${name}.css`,
    `${name}.css`,
  ].map((n) => path.join(dir, n));
}

function findFile(relative) {
  for (const root of roots) {
    for (const candidate of candidates(relative)) {
      const file = path.join(root, candidate);
      if (fs.existsSync(file) && fs.statSync(file).isFile()) {
        return { file, canonical: candidate };
      }
    }
  }
  return null;
}

// Stylesheets are addressed as `mp:/<path relative to the stylesheets dir>`,
// so relative imports inside them are resolved by this importer as well.
const importer = {
  canonicalize(url) {
    const relative = url.startsWith("mp:/") ? decodeURIComponent(url.slice("mp:/".length)) : url;
    if (path.isAbsolute(relative) || relative.startsWith("..")) {
      return null;
    }
    const found = findFile(relative);
    return found ? new URL(`mp:/${found.canonical}`) : null;
  },
  load(canonicalUrl) {
    const found = findFile(decodeURIComponent(canonicalUrl.pathname.slice(1)));
    return { contents: fs.readFileSync(found.file, "utf8"), syntax: found.file.endsWith(".css") ? "css" : "scss" };
  },
};

function compile() {
  const entry = findFile("application.scss");
  let deprecations = 0;
  const result = sass.compileString(fs.readFileSync(entry.file, "utf8"), {
    url: new URL(`mp:/${entry.canonical}`),
    importer,
    importers: [importer],
    loadPaths: [path.join(process.cwd(), "node_modules")],
    sourceMap: false,
    // The sass CLI prints only a few deprecation warnings; the API prints
    // every one, so count them instead of flooding the build output.
    logger: {
      warn(message, options) {
        if (options.deprecation) {
          deprecations += 1;
        } else {
          console.warn(message);
        }
      },
    },
  });
  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  fs.writeFileSync(outFile, `${result.css}\n`);
  if (deprecations > 0) {
    console.warn(`${deprecations} Sass deprecation warnings (run sass directly to see them)`);
  }
}

function build() {
  try {
    compile();
    console.log(`Compiled ${path.relative(process.cwd(), outFile)}`);
  } catch (error) {
    console.error(error.message);
    if (!process.argv.includes("--watch")) {
      process.exit(1);
    }
  }
}

build();

if (process.argv.includes("--watch")) {
  let timer;
  for (const root of roots) {
    fs.watch(root, { recursive: true }, () => {
      clearTimeout(timer);
      timer = setTimeout(build, 100);
    });
  }
  console.log(`Watching ${roots.map((root) => path.relative(process.cwd(), root) || root).join(", ")}`);
}
