import { execFileSync } from "node:child_process";
import { chmodSync, mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { createServer, type Server, type Socket } from "node:net";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const OPTION = "@pi_nvim_socket";
const MAX_MESSAGE = 64 * 1024;

type Request = { id: string; message: string };

function tmux(...args: string[]): string {
  return execFileSync("tmux", args, { encoding: "utf8" }).trim();
}

export default function (pi: ExtensionAPI) {
  let server: Server | undefined;
  let directory: string | undefined;
  let pane: string | undefined;
  let socketPath: string | undefined;
  const clients = new Set<Socket>();
  const pending = new Map<Socket, Request & { queued: boolean }>();

  function reply(socket: Socket, data: object) {
    if (!socket.destroyed) socket.write(JSON.stringify(data) + "\n");
  }

  async function stop(ctx: ExtensionContext) {
    if (ctx.mode === "tui") ctx.ui.setStatus("nvim-bridge", undefined);
    for (const socket of clients) socket.destroy();
    clients.clear();
    pending.clear();
    if (pane && socketPath) {
      try {
        if (tmux("show-options", "-p", "-v", "-t", pane, OPTION) === socketPath) {
          tmux("set-option", "-p", "-u", "-t", pane, OPTION);
        }
      } catch {
        // The pane may have closed already.
      }
    }
    if (server) await new Promise<void>((resolve) => server!.close(() => resolve()));
    if (directory) rmSync(directory, { recursive: true, force: true });
    server = undefined;
    directory = undefined;
    socketPath = undefined;
    pane = undefined;
  }

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui" || !process.env.TMUX_PANE) return;
    await stop(ctx);
    try {
      pane = process.env.TMUX_PANE;
      if (tmux("display-message", "-p", "-t", pane, "#{pane_id}") !== pane) {
        throw new Error("Pi's tmux pane is unavailable");
      }
      if (!process.env.XDG_RUNTIME_DIR) throw new Error("XDG_RUNTIME_DIR is required");
      const root = join(process.env.XDG_RUNTIME_DIR, `pi-nvim-${process.getuid()}`);
      mkdirSync(root, { recursive: true, mode: 0o700 });
      directory = mkdtempSync(join(root, "bridge-"));
      chmodSync(directory, 0o700);
      socketPath = join(directory, "socket");

      server = createServer((socket) => {
        clients.add(socket);
        let buffer = "";
        socket.setTimeout(10000, () => {
          if (!pending.has(socket)) socket.destroy();
        });
        socket.on("data", (chunk: Buffer) => {
          if (pending.has(socket)) return;
          buffer += chunk.toString("utf8");
          if (Buffer.byteLength(buffer) > MAX_MESSAGE) {
            reply(socket, { status: "error", error: "Message is too long" });
            socket.end();
            return;
          }
          const newline = buffer.indexOf("\n");
          if (newline < 0) return;
          try {
            const request = JSON.parse(buffer.slice(0, newline)) as Request;
            if (typeof request.id !== "string" || !request.id ||
                typeof request.message !== "string" || !request.message.trim() ||
                Buffer.byteLength(request.message) > MAX_MESSAGE) {
              throw new Error("Invalid prompt");
            }
            const busy = !ctx.isIdle();
            pi.sendUserMessage(request.message, busy ? { deliverAs: "followUp" } : undefined);
            pending.set(socket, { ...request, queued: busy });
            socket.setTimeout(0);
            reply(socket, { id: request.id, status: busy ? "queued" : "running" });
          } catch (error) {
            reply(socket, { status: "error", error: String(error) });
            socket.end();
          }
        });
        socket.on("close", () => {
          clients.delete(socket);
          pending.delete(socket);
        });
        socket.on("error", () => {});
      });
      await new Promise<void>((resolve, reject) => {
        server!.once("error", reject);
        server!.listen(socketPath, () => {
          server!.removeListener("error", reject);
          resolve();
        });
      });
      chmodSync(socketPath, 0o600);
      tmux("set-option", "-p", "-t", pane, OPTION, socketPath);
      ctx.ui.setStatus("nvim-bridge", "nvim-bridge:on");
    } catch (error) {
      console.error("Pi Neovim bridge:", error);
      await stop(ctx);
    }
  });

  pi.on("before_agent_start", (event) => {
    for (const [socket, request] of pending) {
      if (request.queued && request.message === event.prompt) {
        request.queued = false;
        reply(socket, { id: request.id, status: "running" });
        break;
      }
    }
  });

  pi.on("agent_settled", () => {
    for (const socket of pending.keys()) {
      reply(socket, { status: "done" });
      socket.end();
    }
    pending.clear();
  });

  pi.on("session_shutdown", async (_event, ctx) => stop(ctx));
}
