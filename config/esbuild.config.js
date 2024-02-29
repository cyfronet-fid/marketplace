const path = require('path');

async function result() {
  const options = {
    entryPoints: ["application.js"],
    bundle: true,
    outdir: path.join(process.cwd(), "app/assets/builds"),
    absWorkingDir: path.join(process.cwd(), "app/javascript"),
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
