const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const crypto = require('crypto');
const { authenticateToken, rateLimit } = require('../middleware/auth');

const router = express.Router();

// Database connection
const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

/**
 * User Registration
 * POST /api/v1/auth/register
 */
router.post('/register', rateLimit(5, 15 * 60 * 1000), async (req, res) => {
    try {
        const {
            email,
            password,
            firstName,
            lastName,
            dateOfBirth,
            gender,
            preferences = {}
        } = req.body;

        // Validation
        if (!email || !password) {
            return res.status(400).json({
                success: false,
                error: 'Email and password are required',
                code: 'MISSING_REQUIRED_FIELDS'
            });
        }

        // Email format validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid email format',
                code: 'INVALID_EMAIL'
            });
        }

        // Password strength validation
        if (password.length < 8) {
            return res.status(400).json({
                success: false,
                error: 'Password must be at least 8 characters long',
                code: 'PASSWORD_TOO_SHORT'
            });
        }

        // Check if user already exists
        const existingUserQuery = 'SELECT id FROM users WHERE email = $1';
        const existingUser = await pool.query(existingUserQuery, [email.toLowerCase()]);

        if (existingUser.rows.length > 0) {
            return res.status(409).json({
                success: false,
                error: 'User with this email already exists',
                code: 'EMAIL_ALREADY_EXISTS'
            });
        }

        // Hash password
        const saltRounds = 12;
        const passwordHash = await bcrypt.hash(password, saltRounds);

        // Create user
        const insertUserQuery = `
            INSERT INTO users (email, password_hash, first_name, last_name, date_of_birth, gender, preferences)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, email, first_name, last_name, created_at
        `;

        const newUser = await pool.query(insertUserQuery, [
            email.toLowerCase(),
            passwordHash,
            firstName,
            lastName,
            dateOfBirth,
            gender,
            preferences
        ]);

        const user = newUser.rows[0];

        // Create JWT token
        const token = jwt.sign(
            { userId: user.id },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        // Store session in database
        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

        await pool.query(
            `INSERT INTO user_sessions (user_id, token_hash, expires_at, ip_address, user_agent)
             VALUES ($1, $2, $3, $4, $5)`,
            [user.id, tokenHash, expiresAt, req.ip, req.get('User-Agent')]
        );

        // Log analytics event
        await pool.query(
            `INSERT INTO analytics (user_id, event_type, event_data)
             VALUES ($1, $2, $3)`,
            [user.id, 'user_registered', { method: 'email', ip: req.ip }]
        );

        res.status(201).json({
            success: true,
            data: {
                user: {
                    id: user.id,
                    email: user.email,
                    firstName: user.first_name,
                    lastName: user.last_name,
                    createdAt: user.created_at
                },
                token,
                expiresAt
            },
            message: 'User registered successfully'
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            error: 'Registration failed',
            code: 'REGISTRATION_ERROR'
        });
    }
});

/**
 * User Login
 * POST /api/v1/auth/login
 */
router.post('/login', rateLimit(10, 15 * 60 * 1000), async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                error: 'Email and password are required',
                code: 'MISSING_CREDENTIALS'
            });
        }

        // Find user
        const userQuery = `
            SELECT id, email, password_hash, first_name, last_name, is_active, is_verified, last_login
            FROM users
            WHERE email = $1
        `;

        const userResult = await pool.query(userQuery, [email.toLowerCase()]);

        if (userResult.rows.length === 0) {
            return res.status(401).json({
                success: false,
                error: 'Invalid credentials',
                code: 'INVALID_CREDENTIALS'
            });
        }

        const user = userResult.rows[0];

        // Check if account is active
        if (!user.is_active) {
            return res.status(403).json({
                success: false,
                error: 'Account is deactivated',
                code: 'ACCOUNT_DEACTIVATED'
            });
        }

        // Verify password
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                error: 'Invalid credentials',
                code: 'INVALID_CREDENTIALS'
            });
        }

        // Create JWT token
        const token = jwt.sign(
            { userId: user.id },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        // Store session in database
        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

        await pool.query(
            `INSERT INTO user_sessions (user_id, token_hash, expires_at, ip_address, user_agent)
             VALUES ($1, $2, $3, $4, $5)`,
            [user.id, tokenHash, expiresAt, req.ip, req.get('User-Agent')]
        );

        // Update last login
        await pool.query(
            'UPDATE users SET last_login = NOW() WHERE id = $1',
            [user.id]
        );

        // Log analytics event
        await pool.query(
            `INSERT INTO analytics (user_id, event_type, event_data)
             VALUES ($1, $2, $3)`,
            [user.id, 'user_logged_in', { ip: req.ip, userAgent: req.get('User-Agent') }]
        );

        res.json({
            success: true,
            data: {
                user: {
                    id: user.id,
                    email: user.email,
                    firstName: user.first_name,
                    lastName: user.last_name,
                    isVerified: user.is_verified,
                    lastLogin: user.last_login
                },
                token,
                expiresAt
            },
            message: 'Login successful'
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            error: 'Login failed',
            code: 'LOGIN_ERROR'
        });
    }
});

/**
 * User Logout
 * POST /api/v1/auth/logout
 */
router.post('/logout', authenticateToken, async (req, res) => {
    try {
        // Invalidate current session
        await pool.query(
            'DELETE FROM user_sessions WHERE id = $1',
            [req.user.sessionId]
        );

        // Log analytics event
        await pool.query(
            `INSERT INTO analytics (user_id, event_type, event_data)
             VALUES ($1, $2, $3)`,
            [req.user.id, 'user_logged_out', { sessionId: req.user.sessionId }]
        );

        res.json({
            success: true,
            message: 'Logged out successfully'
        });

    } catch (error) {
        console.error('Logout error:', error);
        res.status(500).json({
            success: false,
            error: 'Logout failed',
            code: 'LOGOUT_ERROR'
        });
    }
});

/**
 * Logout from all devices
 * POST /api/v1/auth/logout-all
 */
router.post('/logout-all', authenticateToken, async (req, res) => {
    try {
        // Invalidate all sessions for this user
        await pool.query(
            'DELETE FROM user_sessions WHERE user_id = $1',
            [req.user.id]
        );

        // Log analytics event
        await pool.query(
            `INSERT INTO analytics (user_id, event_type, event_data)
             VALUES ($1, $2, $3)`,
            [req.user.id, 'user_logged_out_all', { ip: req.ip }]
        );

        res.json({
            success: true,
            message: 'Logged out from all devices successfully'
        });

    } catch (error) {
        console.error('Logout all error:', error);
        res.status(500).json({
            success: false,
            error: 'Logout failed',
            code: 'LOGOUT_ERROR'
        });
    }
});

/**
 * Refresh Token
 * POST /api/v1/auth/refresh
 */
router.post('/refresh', authenticateToken, async (req, res) => {
    try {
        // Create new JWT token
        const token = jwt.sign(
            { userId: req.user.id },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        // Update session with new token hash
        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

        await pool.query(
            `UPDATE user_sessions
             SET token_hash = $1, expires_at = $2, last_used = NOW()
             WHERE id = $3`,
            [tokenHash, expiresAt, req.user.sessionId]
        );

        res.json({
            success: true,
            data: {
                token,
                expiresAt
            },
            message: 'Token refreshed successfully'
        });

    } catch (error) {
        console.error('Token refresh error:', error);
        res.status(500).json({
            success: false,
            error: 'Token refresh failed',
            code: 'TOKEN_REFRESH_ERROR'
        });
    }
});

/**
 * Get Current User Profile
 * GET /api/v1/auth/me
 */
router.get('/me', authenticateToken, async (req, res) => {
    try {
        const userQuery = `
            SELECT id, email, first_name, last_name, date_of_birth, gender,
                   preferences, created_at, last_login, is_verified
            FROM users
            WHERE id = $1
        `;

        const userResult = await pool.query(userQuery, [req.user.id]);

        if (userResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'User not found',
                code: 'USER_NOT_FOUND'
            });
        }

        const user = userResult.rows[0];

        res.json({
            success: true,
            data: {
                user: {
                    id: user.id,
                    email: user.email,
                    firstName: user.first_name,
                    lastName: user.last_name,
                    dateOfBirth: user.date_of_birth,
                    gender: user.gender,
                    preferences: user.preferences,
                    createdAt: user.created_at,
                    lastLogin: user.last_login,
                    isVerified: user.is_verified
                }
            }
        });

    } catch (error) {
        console.error('Get user profile error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get user profile',
            code: 'PROFILE_ERROR'
        });
    }
});

module.exports = router;