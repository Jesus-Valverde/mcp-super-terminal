import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import express from "express";
import cors from "cors";
import { spawn } from "child_process";

const app = express();

// ESTA ES LA CLAVE: Permitir el origen de tu extensión específicamente
app.use(cors({
  origin: "chrome-extension://kngiafgkdnlkgmefdafaibkibegkcaef",
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use(express.json());

let sseTransport;

app.get("/sse", async (req, res) => {
    console.log("🚀 Extensión conectada. Saltando seguridad de origen...");
    sseTransport = new SSEServerTransport("/message", res);
    
    const serverProcess = spawn("npx", ["-y", "@modelcontextprotocol/server-filesystem", "C:/Users/jesus/Desktop"], {
        shell: true
    });

    serverProcess.stdout.on('data', (data) => {
        if (sseTransport) sseTransport.handleData(data);
    });
});

app.post("/message", async (req, res) => {
    if (sseTransport) {
        await sseTransport.handlePostMessage(req, res);
    } else {
        res.status(200).end();
    }
});

app.listen(3006, () => console.log("⚡ Servidor con CORS en puerto 3006"));