const React = require('react');
const { useState, useEffect } = require('react');
const { render, Box, Text, useInput, useApp } = require('ink');
const Spinner = require('ink-spinner');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// Load ASCII ART safely from file
const asciiArtPath = path.join(process.cwd(), 'assets', 'ascii_art.txt');
const ASCII_ART = fs.existsSync(asciiArtPath) ? fs.readFileSync(asciiArtPath, 'utf8') : '';

const Badge = ({ label, value, status }) => {
    const color = status === 'ready' ? 'green' : status === 'error' ? 'red' : 'yellow';
    const statusIcon = status === 'ready' ? '🟢' : status === 'error' ? '🔴' : '🟡';

    return (
        <Box borderStyle="single" borderColor="gray" paddingX={1} marginX={1}>
            <Text bold>{label}: </Text>
            <Text color={color}>{value} {statusIcon}</Text>
        </Box>
    );
};

const Dashboard = () => {
    const { exit } = useApp();
    const [view, setView] = useState('logs');
    const [status, setStatus] = useState({
        server: 'loading',
        assistant: 'loading',
        tools: 0,
        connectedServers: [],
        toolsMap: {}
    });
    const [logs, setLogs] = useState([]);
    const [progress, setProgress] = useState({ servers: 0, tools: 0 });

    useInput((input, key) => {
        if (input === 'q') exit();
        if (input === 'l') setView('logs');
        if (input === 't') setView('tools');
    });

    useEffect(() => {
        const proxy = spawn('mcp-superassistant-proxy.cmd', [
            '--host', '127.0.0.1',
            '--port', '4003',
            '--config', 'config.json',
            '--baseUrl', 'http://127.0.0.1:4003',
            '--logLevel', 'info'
        ], { shell: true });

        const handleLine = (data) => {
            const rawLines = data.toString().split('\n');
            rawLines.forEach(line => {
                const trimmed = line.trim();
                if (!trimmed) return;

                setLogs((prev) => [...prev.slice(-100), trimmed]);

                if (trimmed.includes('Connected to server:')) {
                    const serverMatch = trimmed.split('Connected to server:')[1]?.trim();
                    if (serverMatch) {
                        setStatus(prev => {
                            if (!prev.connectedServers.includes(serverMatch)) {
                                return {
                                    ...prev,
                                    connectedServers: [...prev.connectedServers, serverMatch]
                                };
                            }
                            return prev;
                        });
                        setProgress(prev => ({ ...prev, servers: Math.min(prev.servers + 50, 100) }));
                    }
                }

                if (trimmed.includes('has') && trimmed.includes('tools')) {
                    const match = trimmed.match(/Server (.*) has (\d+) tools/);
                    if (match) {
                        const sName = match[1].trim();
                        const tCount = parseInt(match[2]);
                        setStatus(prev => {
                            if (!prev.toolsMap[sName]) {
                                return {
                                    ...prev,
                                    toolsMap: { ...prev.toolsMap, [sName]: tCount },
                                    tools: prev.tools + tCount
                                };
                            }
                            return prev;
                        });
                        setProgress(prev => ({ ...prev, tools: Math.min(prev.tools + 50, 100) }));
                    }
                }

                if (trimmed.includes('gateway ready') || trimmed.includes('POST to SSE')) {
                    setStatus(prev => ({ ...prev, assistant: 'ready', server: 'ready' }));
                }
            });
        };

        proxy.stdout.on('data', handleLine);
        proxy.stderr.on('data', handleLine);

        proxy.on('close', () => exit());

        return () => proxy.kill();
    }, []);

    const allReady = status.server === 'ready' && status.assistant === 'ready';

    return (
        <Box flexDirection="column" paddingX={2} paddingY={1}>
            <Text cyan>{ASCII_ART}</Text>
            <Box justifyContent="center" marginBottom={1}>
                <Text dimColor italic>Created by jesval</Text>
            </Box>

            <Box flexDirection="row" justifyContent="center" marginBottom={1}>
                <Badge label="SERVER" value={status.server === 'ready' ? 'OK' : 'WAIT'} status={status.server} />
                <Badge label="ASSISTANT" value={status.assistant === 'ready' ? 'READY' : 'SYNCING'} status={status.assistant} />
                <Box borderStyle="single" borderColor="gray" paddingX={1} marginX={1}>
                    <Text bold>TOOLS: </Text>
                    <Text yellow>{status.tools}</Text>
                </Box>
            </Box>

            {!allReady && (
                <Box flexDirection="column" alignItems="center" marginBottom={1}>
                    <Text dimColor>INITIALIZING MCP SYSTEM...</Text>
                    <Box borderStyle="single" borderColor="cyan" width={42}>
                        <Text backgroundColor="cyan">{" ".repeat(Math.floor((progress.servers + progress.tools) / 2 * 0.4))}</Text>
                    </Box>
                    <Text>{Math.floor((progress.servers + progress.tools) / 2)}% <Spinner type="dots" /></Text>
                </Box>
            )}

            <Box borderStyle="double" borderColor="cyan" flexDirection="column" paddingX={1} minHeight={12}>
                <Box borderStyle="bold" borderColor="blue" paddingX={1} marginTop={-1} alignSelf="center">
                    <Text bold white>{view === 'logs' ? " LIVE SYSTEM LOGS " : " TOOLS LIST SUMMARY "}</Text>
                </Box>

                {view === 'logs' ? (
                    <Box flexDirection="column" paddingY={1}>
                        {logs.length === 0 ? (
                            <Text dimColor italic>Waiting for system logs...</Text>
                        ) : (
                            logs.slice(-10).map((log, i) => (
                                <Text key={i} color="gray" wrap="truncate-end">
                                    <Text dimColor>[{new Date().toLocaleTimeString()}]</Text> {log.replace('mcp-superassistant-proxy', 'Proxy')}
                                </Text>
                            ))
                        )}
                    </Box>
                ) : (
                    <Box flexDirection="column" paddingY={1}>
                        {Object.keys(status.toolsMap).map((srv) => (
                            <Text key={srv} yellow bold> - {srv}: {status.toolsMap[srv]} tools</Text>
                        ))}
                        {Object.keys(status.toolsMap).length === 0 && <Text dimColor>No tools discovered yet.</Text>}
                    </Box>
                )}
            </Box>

            <Box marginTop={1} justifyContent="center">
                <Box flexDirection="row">
                    <Text bold color="white" backgroundColor="blue"> L </Text><Text dimColor> Logs </Text>
                    <Text marginX={1}>|</Text>
                    <Text bold color="white" backgroundColor="green"> T </Text><Text dimColor> Tools </Text>
                    <Text marginX={1}>|</Text>
                    <Text bold color="white" backgroundColor="red"> Q </Text><Text dimColor> Quit </Text>
                </Box>
            </Box>
        </Box>
    );
};

render(<Dashboard />);
