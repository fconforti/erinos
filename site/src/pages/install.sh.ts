// erinos.ai/install.sh: the repo's install.sh, read at build time so that file stays the one source.
// The build runs in site/, so the script is one folder up.
import type { APIRoute } from "astro";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

export const GET: APIRoute = async () =>
  new Response(await readFile(resolve(process.cwd(), "../install.sh"), "utf8"), {
    headers: { "Content-Type": "text/x-shellscript; charset=utf-8" },
  });
