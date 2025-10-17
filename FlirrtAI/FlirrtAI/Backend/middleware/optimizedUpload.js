const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const crypto = require('crypto');
const { logger } = require('../services/logger');

class OptimizedUploadService {
    constructor() {
        this.uploadDir = process.env.UPLOAD_DIR || './uploads';
        this.tempDir = path.join(this.uploadDir, 'temp');
        this.maxFileSize = parseInt(process.env.MAX_FILE_SIZE) || 50 * 1024 * 1024; // 50MB default
        this.allowedMimeTypes = {
            images: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'],
            audio: ['audio/mpeg', 'audio/wav', 'audio/mp3', 'audio/m4a', 'audio/ogg'],
            documents: ['application/pdf', 'text/plain']
        };

        this.initializeDirectories();
    }

    async initializeDirectories() {
        try {
            await fs.mkdir(this.uploadDir, { recursive: true });
            await fs.mkdir(this.tempDir, { recursive: true });
            await fs.mkdir(path.join(this.uploadDir, 'images'), { recursive: true });
            await fs.mkdir(path.join(this.uploadDir, 'audio'), { recursive: true });
            await fs.mkdir(path.join(this.uploadDir, 'documents'), { recursive: true });

            logger.info('Upload directories initialized', {
                uploadDir: this.uploadDir,
                tempDir: this.tempDir,
                maxFileSize: this.maxFileSize
            });
        } catch (error) {
            logger.error('Failed to initialize upload directories:', error.message);
            throw error;
        }
    }

    // Generate unique filename with timestamp and hash
    generateUniqueFilename(originalName, userId = 'anonymous', prefix = '') {
        const timestamp = Date.now();
        const randomHash = crypto.randomBytes(8).toString('hex');
        const ext = path.extname(originalName).toLowerCase();
        const baseName = path.basename(originalName, ext).replace(/[^a-zA-Z0-9]/g, '_');

        return `${prefix}${prefix ? '_' : ''}${userId}_${timestamp}_${randomHash}_${baseName}${ext}`;
    }

    // Determine file category based on mime type
    getFileCategory(mimeType) {
        for (const [category, types] of Object.entries(this.allowedMimeTypes)) {
            if (types.includes(mimeType)) {
                return category;
            }
        }
        return null;
    }

    // Storage configuration for different file types
    createStorage(fileType = 'general') {
        return multer.diskStorage({
            destination: (req, file, cb) => {
                const correlationId = req.correlationId;

                try {
                    // Determine subdirectory based on file type and MIME type
                    let subDir = 'documents'; // default
                    const category = this.getFileCategory(file.mimetype);

                    if (category) {
                        subDir = category;
                    } else if (fileType !== 'general') {
                        subDir = fileType;
                    }

                    const fullPath = path.join(this.uploadDir, subDir);

                    req.logger?.debug('Upload destination determined', {
                        fileType,
                        category,
                        subDir,
                        fullPath,
                        mimeType: file.mimetype
                    });

                    cb(null, fullPath);
                } catch (error) {
                    req.logger?.error('Error determining upload destination:', error.message);
                    cb(error);
                }
            },

            filename: (req, file, cb) => {
                try {
                    const userId = req.user?.id || 'anonymous';
                    const prefix = fileType !== 'general' ? fileType : '';
                    const filename = this.generateUniqueFilename(file.originalname, userId, prefix);

                    req.logger?.info('File upload started', {
                        originalName: file.originalname,
                        generatedName: filename,
                        mimeType: file.mimetype,
                        userId
                    });

                    cb(null, filename);
                } catch (error) {
                    req.logger?.error('Error generating filename:', error.message);
                    cb(error);
                }
            }
        });
    }

    // File filter for validation
    createFileFilter(allowedTypes = null) {
        return (req, file, cb) => {
            const correlationId = req.correlationId;

            try {
                // Check file type if specific types are allowed
                if (allowedTypes) {
                    const allowed = Array.isArray(allowedTypes) ? allowedTypes : [allowedTypes];
                    let isAllowed = false;

                    // Check against specific categories or mime types
                    for (const type of allowed) {
                        if (this.allowedMimeTypes[type]) {
                            // It's a category (e.g., 'images')
                            if (this.allowedMimeTypes[type].includes(file.mimetype)) {
                                isAllowed = true;
                                break;
                            }
                        } else if (file.mimetype === type) {
                            // It's a specific mime type
                            isAllowed = true;
                            break;
                        }
                    }

                    if (!isAllowed) {
                        const error = new Error(`File type not allowed: ${file.mimetype}`);
                        error.code = 'INVALID_FILE_TYPE';

                        req.logger?.warn('File type rejected', {
                            filename: file.originalname,
                            mimeType: file.mimetype,
                            allowedTypes
                        });

                        return cb(error, false);
                    }
                } else {
                    // Check against all allowed types
                    const allAllowed = Object.values(this.allowedMimeTypes).flat();
                    if (!allAllowed.includes(file.mimetype)) {
                        const error = new Error(`File type not supported: ${file.mimetype}`);
                        error.code = 'UNSUPPORTED_FILE_TYPE';

                        req.logger?.warn('Unsupported file type', {
                            filename: file.originalname,
                            mimeType: file.mimetype
                        });

                        return cb(error, false);
                    }
                }

                // Additional security checks
                const suspiciousExtensions = ['.exe', '.bat', '.cmd', '.scr', '.pif', '.vbs', '.js'];
                const ext = path.extname(file.originalname).toLowerCase();

                if (suspiciousExtensions.includes(ext)) {
                    const error = new Error(`Dangerous file extension: ${ext}`);
                    error.code = 'DANGEROUS_FILE_EXTENSION';

                    req.logger?.error('Dangerous file extension blocked', {
                        filename: file.originalname,
                        extension: ext
                    });

                    return cb(error, false);
                }

                req.logger?.debug('File validation passed', {
                    filename: file.originalname,
                    mimeType: file.mimetype,
                    extension: ext
                });

                cb(null, true);

            } catch (error) {
                req.logger?.error('File filter error:', error.message);
                cb(error, false);
            }
        };
    }

    // Create multer instance for screenshots
    createScreenshotUpload() {
        return multer({
            storage: this.createStorage('screenshot'),
            limits: {
                fileSize: 10 * 1024 * 1024, // 10MB for screenshots
                files: 1 // Only one screenshot at a time
            },
            fileFilter: this.createFileFilter(['images'])
        });
    }

    // Create multer instance for voice files
    createVoiceUpload() {
        return multer({
            storage: this.createStorage('voice'),
            limits: {
                fileSize: this.maxFileSize, // Full size for voice files
                files: 5 // Allow multiple voice files for cloning
            },
            fileFilter: this.createFileFilter(['audio'])
        });
    }

    // Create multer instance for documents
    createDocumentUpload() {
        return multer({
            storage: this.createStorage('document'),
            limits: {
                fileSize: 20 * 1024 * 1024, // 20MB for documents
                files: 3
            },
            fileFilter: this.createFileFilter(['documents'])
        });
    }

    // General purpose upload
    createGeneralUpload(options = {}) {
        const {
            maxFileSize = this.maxFileSize,
            maxFiles = 1,
            allowedTypes = null
        } = options;

        return multer({
            storage: this.createStorage('general'),
            limits: {
                fileSize: maxFileSize,
                files: maxFiles
            },
            fileFilter: this.createFileFilter(allowedTypes)
        });
    }

    // Middleware for upload progress tracking
    trackUploadProgress() {
        return (req, res, next) => {
            const startTime = Date.now();
            let totalBytes = 0;

            // Track content length if available
            if (req.headers['content-length']) {
                totalBytes = parseInt(req.headers['content-length']);

                req.logger?.info('Upload started', {
                    contentLength: totalBytes,
                    contentType: req.headers['content-type']
                });
            }

            // Track when upload completes
            res.on('finish', () => {
                const duration = Date.now() - startTime;
                const success = res.statusCode < 400;

                req.logger?.info('Upload completed', {
                    success,
                    statusCode: res.statusCode,
                    duration: `${duration}ms`,
                    totalBytes: totalBytes || 'unknown'
                });
            });

            next();
        };
    }

    // Middleware to validate uploaded files
    validateUploadedFiles() {
        return async (req, res, next) => {
            if (!req.files && !req.file) {
                return next();
            }

            try {
                const files = req.files ? (Array.isArray(req.files) ? req.files : Object.values(req.files).flat()) : [req.file];

                for (const file of files) {
                    // Verify file exists and is readable
                    try {
                        await fs.access(file.path);
                        const stats = await fs.stat(file.path);

                        req.logger?.debug('File validated', {
                            filename: file.filename,
                            originalName: file.originalname,
                            size: stats.size,
                            mimeType: file.mimetype
                        });

                        // Add file stats to file object
                        file.stats = stats;
                    } catch (error) {
                        req.logger?.error('File validation failed', {
                            filename: file.filename,
                            error: error.message
                        });

                        // Clean up the file
                        try {
                            await fs.unlink(file.path);
                        } catch (unlinkError) {
                            req.logger?.error('Failed to clean up invalid file:', unlinkError.message);
                        }

                        return res.status(400).json({
                            success: false,
                            error: 'File validation failed',
                            filename: file.originalname,
                            code: 'FILE_VALIDATION_ERROR'
                        });
                    }
                }

                next();

            } catch (error) {
                req.logger?.error('Upload validation error:', error.message);
                res.status(500).json({
                    success: false,
                    error: 'Upload validation failed',
                    code: 'UPLOAD_VALIDATION_ERROR'
                });
            }
        };
    }

    // Cleanup old temporary files
    async cleanupTempFiles(maxAge = 24 * 60 * 60 * 1000) { // 24 hours default
        try {
            const files = await fs.readdir(this.tempDir);
            const now = Date.now();
            let cleanedCount = 0;

            for (const file of files) {
                const filePath = path.join(this.tempDir, file);

                try {
                    const stats = await fs.stat(filePath);
                    const age = now - stats.mtime.getTime();

                    if (age > maxAge) {
                        await fs.unlink(filePath);
                        cleanedCount++;
                        logger.debug('Cleaned up old temp file', { file, age: `${Math.round(age / 1000 / 60)} minutes` });
                    }
                } catch (error) {
                    logger.warn('Error checking temp file', { file, error: error.message });
                }
            }

            if (cleanedCount > 0) {
                logger.info('Temp file cleanup completed', {
                    filesRemoved: cleanedCount,
                    maxAge: `${maxAge / 1000 / 60} minutes`
                });
            }

            return cleanedCount;

        } catch (error) {
            logger.error('Temp file cleanup failed:', error.message);
            return 0;
        }
    }

    // Get upload statistics
    async getUploadStats() {
        try {
            const stats = {
                directories: {},
                totalSize: 0,
                totalFiles: 0
            };

            const categories = ['images', 'audio', 'documents', 'temp'];

            for (const category of categories) {
                const dirPath = path.join(this.uploadDir, category);

                try {
                    const files = await fs.readdir(dirPath);
                    let categorySize = 0;

                    for (const file of files) {
                        try {
                            const filePath = path.join(dirPath, file);
                            const fileStat = await fs.stat(filePath);
                            if (fileStat.isFile()) {
                                categorySize += fileStat.size;
                            }
                        } catch (error) {
                            // Skip files that can't be accessed
                        }
                    }

                    stats.directories[category] = {
                        files: files.length,
                        size: categorySize,
                        sizeFormatted: `${(categorySize / 1024 / 1024).toFixed(2)}MB`
                    };

                    stats.totalSize += categorySize;
                    stats.totalFiles += files.length;

                } catch (error) {
                    stats.directories[category] = {
                        files: 0,
                        size: 0,
                        error: error.message
                    };
                }
            }

            stats.totalSizeFormatted = `${(stats.totalSize / 1024 / 1024).toFixed(2)}MB`;

            return stats;

        } catch (error) {
            logger.error('Error getting upload stats:', error.message);
            return {
                error: error.message
            };
        }
    }

    // Error handler for multer errors
    handleUploadErrors() {
        return (error, req, res, next) => {
            if (error) {
                req.logger?.error('Upload error', {
                    error: error.message,
                    code: error.code,
                    field: error.field
                });

                // Handle specific multer errors
                if (error.code === 'LIMIT_FILE_SIZE') {
                    return res.status(413).json({
                        success: false,
                        error: 'File too large',
                        maxSize: `${this.maxFileSize / 1024 / 1024}MB`,
                        code: 'FILE_TOO_LARGE'
                    });
                }

                if (error.code === 'LIMIT_FILE_COUNT') {
                    return res.status(400).json({
                        success: false,
                        error: 'Too many files',
                        code: 'TOO_MANY_FILES'
                    });
                }

                if (error.code === 'LIMIT_UNEXPECTED_FILE') {
                    return res.status(400).json({
                        success: false,
                        error: 'Unexpected file field',
                        field: error.field,
                        code: 'UNEXPECTED_FILE_FIELD'
                    });
                }

                if (error.code === 'INVALID_FILE_TYPE' || error.code === 'UNSUPPORTED_FILE_TYPE') {
                    return res.status(400).json({
                        success: false,
                        error: error.message,
                        code: error.code
                    });
                }

                if (error.code === 'DANGEROUS_FILE_EXTENSION') {
                    return res.status(403).json({
                        success: false,
                        error: 'File type not allowed for security reasons',
                        code: 'SECURITY_VIOLATION'
                    });
                }

                // Generic upload error
                return res.status(500).json({
                    success: false,
                    error: 'Upload failed',
                    details: error.message,
                    code: 'UPLOAD_ERROR'
                });
            }

            next();
        };
    }
}

// Export singleton instance and factory methods
const uploadService = new OptimizedUploadService();

module.exports = {
    uploadService,
    screenshotUpload: () => uploadService.createScreenshotUpload(),
    voiceUpload: () => uploadService.createVoiceUpload(),
    documentUpload: () => uploadService.createDocumentUpload(),
    generalUpload: (options) => uploadService.createGeneralUpload(options),
    trackProgress: () => uploadService.trackUploadProgress(),
    validateFiles: () => uploadService.validateUploadedFiles(),
    handleErrors: () => uploadService.handleUploadErrors()
};