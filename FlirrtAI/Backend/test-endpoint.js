// Add this to server.js before the error handler
app.get('/api/v1/test', (req, res) => {
    res.json({
        success: true,
        message: "Test endpoint working",
        timestamp: new Date().toISOString(),
        commit: "4fe8b19",
        env_vars_loaded: {
            GROK_API_KEY: process.env.GROK_API_KEY ? 'SET' : 'NOT_SET',
            NODE_ENV: process.env.NODE_ENV
        }
    });
});
