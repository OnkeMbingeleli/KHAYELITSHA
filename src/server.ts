// SSR entry point. wrangler.jsonc points "main" here, and vite.config.ts's
// tanstackStart.server.entry redirects the bundled server build here too.
// Wrapped in try/catch so a render-time crash returns a plain error page
// instead of a blank Cloudflare Worker failure.
import {
  createStartHandler,
  defaultStreamHandler,
} from "@tanstack/react-start/server";

const startHandler = createStartHandler(defaultStreamHandler);

export default {
  async fetch(request: Request): Promise<Response> {
    try {
      return await startHandler(request);
    } catch (err) {
      console.error("SSR render error:", err);
      return new Response(
        `<!doctype html><html><head><meta charset="utf-8" />
        <title>This page didn't load</title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <style>
          body{font:15px/1.5 system-ui,-apple-system,sans-serif;background:#fafafa;color:#111;
            display:grid;place-items:center;min-height:100vh;margin:0;padding:1.5rem}
          .card{max-width:28rem;width:100%;text-align:center;padding:2rem}
          h1{font-size:1.25rem;margin:0 0 .5rem} p{color:#4b5563;margin:0 0 1.5rem}
          a{padding:.5rem 1rem;border-radius:.375rem;background:#111;color:#fff;text-decoration:none}
        </style></head>
        <body><div class="card"><h1>This page didn't load</h1>
        <p>Something went wrong on our end. Try refreshing or head back home.</p>
        <a href="/">Go home</a></div></body></html>`,
        { status: 500, headers: { "content-type": "text/html; charset=utf-8" } }
      );
    }
  },
};
