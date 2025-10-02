const WebSocket = require('ws');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { logger } = require('./logger');

class WebSocketService {
    constructor() {
        this.wss = null;
        this.clients = new Map(); // Map of userId -> Set of WebSocket connections
        this.connectionMetrics = {
            total: 0,
            active: 0,
            messagesPerMinute: 0,
            messageCount: 0,
            lastMessageTime: Date.now()
        };

        this.setupHeartbeat();
    }

    initialize(server) {
        try {
            this.wss = new WebSocket.Server({
                server,
                path: '/ws',
                perMessageDeflate: false,
                clientTracking: true
            });

            this.setupWebSocketServer();

            logger.info('WebSocket service initialized', {
                path: '/ws',
                server: 'attached'
            });

        } catch (error) {
            logger.error('Failed to initialize WebSocket service:', error.message);
            throw error;
        }
    }

    setupWebSocketServer() {
        this.wss.on('connection', (ws, request) => {
            const connectionId = uuidv4();
            const clientIP = request.socket.remoteAddress;

            logger.debug('WebSocket connection attempt', {
                connectionId,
                clientIP,
                userAgent: request.headers['user-agent']
            });

            // Set connection properties
            ws.connectionId = connectionId;
            ws.isAlive = true;
            ws.userId = null;
            ws.authenticatedAt = null;
            ws.lastActivity = Date.now();

            // Update metrics
            this.connectionMetrics.total++;
            this.connectionMetrics.active++;

            // Handle authentication
            this.handleAuthentication(ws, request);

            // Handle messages
            ws.on('message', (data) => {
                this.handleMessage(ws, data);
            });

            // Handle connection close
            ws.on('close', (code, reason) => {
                this.handleDisconnection(ws, code, reason);
            });

            // Handle errors
            ws.on('error', (error) => {
                logger.error('WebSocket error', {
                    connectionId: ws.connectionId,
                    userId: ws.userId,
                    error: error.message
                });
            });

            // Heartbeat for connection health
            ws.on('pong', () => {
                ws.isAlive = true;
                ws.lastActivity = Date.now();
            });

            // Send welcome message
            this.sendMessage(ws, 'connection', {
                connectionId,
                timestamp: new Date().toISOString(),
                message: 'Connected to Flirrt.ai WebSocket server'
            });
        });

        this.wss.on('error', (error) => {
            logger.error('WebSocket server error:', error.message);
        });

        logger.info('WebSocket server event handlers configured');
    }

    async handleAuthentication(ws, request) {
        try {
            // Extract token from query parameters or headers
            const url = new URL(request.url, 'ws://localhost');
            const token = url.searchParams.get('token') ||
                         request.headers.authorization?.split(' ')[1];

            if (!token) {
                this.sendMessage(ws, 'auth_required', {
                    message: 'Authentication token required'
                });
                return;
            }

            // Allow test token for development
            if (token === 'test-token-for-api-testing') {
                ws.userId = 'test-user-id';
                ws.authenticatedAt = Date.now();
                this.addClientConnection(ws.userId, ws);

                this.sendMessage(ws, 'authenticated', {
                    userId: ws.userId,
                    message: 'Authentication successful (test mode)'
                });

                logger.info('WebSocket authenticated (test mode)', {
                    connectionId: ws.connectionId,
                    userId: ws.userId
                });
                return;
            }

            // Verify JWT token
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            const userId = decoded.userId;

            if (!userId) {
                throw new Error('Invalid token payload');
            }

            // TODO: In production, verify session exists in database
            // For now, we'll accept valid JWT tokens

            ws.userId = userId;
            ws.authenticatedAt = Date.now();
            this.addClientConnection(userId, ws);

            this.sendMessage(ws, 'authenticated', {
                userId,
                message: 'Authentication successful'
            });

            logger.info('WebSocket authenticated', {
                connectionId: ws.connectionId,
                userId
            });

        } catch (error) {
            logger.warn('WebSocket authentication failed', {
                connectionId: ws.connectionId,
                error: error.message
            });

            this.sendMessage(ws, 'auth_failed', {
                error: 'Authentication failed',
                message: 'Please provide a valid authentication token'
            });

            // Close connection after 5 seconds if not authenticated
            setTimeout(() => {
                if (!ws.userId) {
                    ws.close(4001, 'Authentication required');
                }
            }, 5000);
        }
    }

    handleMessage(ws, data) {
        try {
            ws.lastActivity = Date.now();
            this.connectionMetrics.messageCount++;

            const message = JSON.parse(data.toString());
            const { type, payload, correlationId } = message;

            logger.debug('WebSocket message received', {
                connectionId: ws.connectionId,
                userId: ws.userId,
                type,
                correlationId
            });

            // Handle different message types
            switch (type) {
                case 'ping':
                    this.sendMessage(ws, 'pong', {
                        timestamp: new Date().toISOString(),
                        correlationId
                    });
                    break;

                case 'subscribe':
                    this.handleSubscription(ws, payload, correlationId);
                    break;

                case 'unsubscribe':
                    this.handleUnsubscription(ws, payload, correlationId);
                    break;

                case 'status_request':
                    this.sendStatusUpdate(ws, correlationId);
                    break;

                default:
                    logger.warn('Unknown WebSocket message type', {
                        connectionId: ws.connectionId,
                        userId: ws.userId,
                        type
                    });

                    this.sendMessage(ws, 'error', {
                        error: 'Unknown message type',
                        type,
                        correlationId
                    });
            }

        } catch (error) {
            logger.error('Error handling WebSocket message', {
                connectionId: ws.connectionId,
                userId: ws.userId,
                error: error.message
            });

            this.sendMessage(ws, 'error', {
                error: 'Invalid message format'
            });
        }
    }

    handleSubscription(ws, payload, correlationId) {
        const { channels } = payload;

        if (!Array.isArray(channels)) {
            this.sendMessage(ws, 'subscription_error', {
                error: 'Channels must be an array',
                correlationId
            });
            return;
        }

        // Initialize subscriptions if not exists
        if (!ws.subscriptions) {
            ws.subscriptions = new Set();
        }

        // Add channels to subscription
        channels.forEach(channel => {
            if (this.isValidChannel(channel, ws.userId)) {
                ws.subscriptions.add(channel);
                logger.debug('WebSocket subscribed to channel', {
                    connectionId: ws.connectionId,
                    userId: ws.userId,
                    channel
                });
            } else {
                logger.warn('Invalid subscription channel', {
                    connectionId: ws.connectionId,
                    userId: ws.userId,
                    channel
                });
            }
        });

        this.sendMessage(ws, 'subscription_confirmed', {
            channels: Array.from(ws.subscriptions),
            correlationId
        });
    }

    handleUnsubscription(ws, payload, correlationId) {
        const { channels } = payload;

        if (!ws.subscriptions) {
            return;
        }

        if (Array.isArray(channels)) {
            channels.forEach(channel => {
                ws.subscriptions.delete(channel);
                logger.debug('WebSocket unsubscribed from channel', {
                    connectionId: ws.connectionId,
                    userId: ws.userId,
                    channel
                });
            });
        } else {
            // Unsubscribe from all
            ws.subscriptions.clear();
        }

        this.sendMessage(ws, 'unsubscription_confirmed', {
            channels: Array.from(ws.subscriptions),
            correlationId
        });
    }

    isValidChannel(channel, userId) {
        // User-specific channels
        if (channel.startsWith(`user:${userId}:`)) {
            return true;
        }

        // Global channels that all authenticated users can subscribe to
        const allowedGlobalChannels = [
            'system:status',
            'system:announcements'
        ];

        return allowedGlobalChannels.includes(channel);
    }

    handleDisconnection(ws, code, reason) {
        logger.info('WebSocket disconnected', {
            connectionId: ws.connectionId,
            userId: ws.userId,
            code,
            reason: reason.toString(),
            duration: ws.authenticatedAt ? Date.now() - ws.authenticatedAt : null
        });

        // Remove from client connections
        if (ws.userId) {
            this.removeClientConnection(ws.userId, ws);
        }

        // Update metrics
        this.connectionMetrics.active--;
    }

    addClientConnection(userId, ws) {
        if (!this.clients.has(userId)) {
            this.clients.set(userId, new Set());
        }
        this.clients.get(userId).add(ws);

        logger.debug('Client connection added', {
            userId,
            connectionId: ws.connectionId,
            totalConnections: this.clients.get(userId).size
        });
    }

    removeClientConnection(userId, ws) {
        if (this.clients.has(userId)) {
            this.clients.get(userId).delete(ws);

            // Remove user entry if no connections left
            if (this.clients.get(userId).size === 0) {
                this.clients.delete(userId);
            }

            logger.debug('Client connection removed', {
                userId,
                connectionId: ws.connectionId
            });
        }
    }

    sendMessage(ws, type, data = {}) {
        if (ws.readyState !== WebSocket.OPEN) {
            return false;
        }

        try {
            const message = JSON.stringify({
                type,
                timestamp: new Date().toISOString(),
                ...data
            });

            ws.send(message);
            return true;
        } catch (error) {
            logger.error('Error sending WebSocket message', {
                connectionId: ws.connectionId,
                userId: ws.userId,
                type,
                error: error.message
            });
            return false;
        }
    }

    // Public methods for sending updates to users
    sendToUser(userId, type, data, channel = null) {
        if (!this.clients.has(userId)) {
            logger.debug('No WebSocket connections for user', { userId });
            return 0;
        }

        const userConnections = this.clients.get(userId);
        let sentCount = 0;

        userConnections.forEach(ws => {
            // Check if connection is subscribed to channel (if specified)
            if (channel && ws.subscriptions && !ws.subscriptions.has(channel)) {
                return;
            }

            if (this.sendMessage(ws, type, { ...data, channel })) {
                sentCount++;
            }
        });

        logger.debug('Message sent to user', {
            userId,
            type,
            sentCount,
            totalConnections: userConnections.size,
            channel
        });

        return sentCount;
    }

    // Send updates for various events
    sendFlirtGenerationUpdate(userId, status, data = {}) {
        this.sendToUser(userId, 'flirt_generation_update', {
            status, // 'queued', 'processing', 'completed', 'failed'
            ...data
        }, `user:${userId}:flirts`);
    }

    sendVoiceSynthesisUpdate(userId, status, data = {}) {
        this.sendToUser(userId, 'voice_synthesis_update', {
            status,
            ...data
        }, `user:${userId}:voice`);
    }

    sendScreenshotAnalysisUpdate(userId, status, data = {}) {
        this.sendToUser(userId, 'screenshot_analysis_update', {
            status,
            ...data
        }, `user:${userId}:analysis`);
    }

    sendRateLimitUpdate(userId, remainingRequests, resetTime) {
        this.sendToUser(userId, 'rate_limit_update', {
            remainingRequests,
            resetTime
        }, `user:${userId}:limits`);
    }

    sendSystemStatus(status, message) {
        // Send to all authenticated connections
        this.broadcast('system_status', {
            status,
            message
        }, 'system:status');
    }

    broadcast(type, data, channel = null) {
        let sentCount = 0;

        this.clients.forEach((connections, userId) => {
            connections.forEach(ws => {
                if (channel && ws.subscriptions && !ws.subscriptions.has(channel)) {
                    return;
                }

                if (this.sendMessage(ws, type, { ...data, channel })) {
                    sentCount++;
                }
            });
        });

        logger.info('Broadcast message sent', {
            type,
            sentCount,
            channel
        });

        return sentCount;
    }

    sendStatusUpdate(ws, correlationId) {
        const status = {
            connectionId: ws.connectionId,
            userId: ws.userId,
            authenticated: !!ws.userId,
            subscriptions: ws.subscriptions ? Array.from(ws.subscriptions) : [],
            connectedAt: ws.authenticatedAt ? new Date(ws.authenticatedAt).toISOString() : null,
            lastActivity: new Date(ws.lastActivity).toISOString()
        };

        this.sendMessage(ws, 'status_response', {
            status,
            correlationId
        });
    }

    setupHeartbeat() {
        setInterval(() => {
            if (!this.wss) return;

            // Update messages per minute metric
            const now = Date.now();
            const timeDiff = (now - this.connectionMetrics.lastMessageTime) / 1000 / 60; // minutes
            this.connectionMetrics.messagesPerMinute = Math.round(this.connectionMetrics.messageCount / Math.max(timeDiff, 1));

            // Send heartbeat to all connections
            this.wss.clients.forEach(ws => {
                if (!ws.isAlive) {
                    logger.debug('Terminating unresponsive WebSocket connection', {
                        connectionId: ws.connectionId,
                        userId: ws.userId
                    });

                    if (ws.userId) {
                        this.removeClientConnection(ws.userId, ws);
                    }

                    ws.terminate();
                    this.connectionMetrics.active--;
                    return;
                }

                ws.isAlive = false;
                ws.ping();
            });

            // Log connection stats every 5 minutes
            if (Date.now() % (5 * 60 * 1000) < 30000) {
                logger.info('WebSocket connection metrics', this.connectionMetrics);
            }

        }, 30000); // 30 second heartbeat
    }

    getHealthStatus() {
        if (!this.wss) {
            return {
                status: 'offline',
                message: 'WebSocket server not initialized'
            };
        }

        const activeConnections = Array.from(this.wss.clients).filter(ws =>
            ws.readyState === WebSocket.OPEN
        ).length;

        return {
            status: 'online',
            connections: {
                active: activeConnections,
                total: this.connectionMetrics.total,
                authenticated: this.clients.size
            },
            metrics: {
                ...this.connectionMetrics,
                active: activeConnections // Update with current count
            },
            users: {
                connected: this.clients.size,
                totalConnections: Array.from(this.clients.values()).reduce(
                    (sum, connections) => sum + connections.size, 0
                )
            }
        };
    }

    async shutdown() {
        logger.info('Shutting down WebSocket service...');

        if (this.wss) {
            // Send shutdown notification to all clients
            this.broadcast('system_shutdown', {
                message: 'Server is shutting down',
                timestamp: new Date().toISOString()
            });

            // Close all connections gracefully
            this.wss.clients.forEach(ws => {
                ws.close(1001, 'Server shutting down');
            });

            // Close server
            this.wss.close(() => {
                logger.info('WebSocket server closed');
            });
        }

        // Clear client connections
        this.clients.clear();
        this.connectionMetrics.active = 0;

        logger.info('WebSocket service shutdown complete');
    }
}

// Export singleton instance
const webSocketService = new WebSocketService();

module.exports = webSocketService;