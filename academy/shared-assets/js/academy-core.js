/**
 * Seekapa Trading Academy - Core JavaScript
 * Handles gamification, language switching, and localStorage management
 */

// ========== GAMIFICATION SYSTEM ==========
const AcademyGameSystem = {
    // XP and Progress
    addXP(points) {
        const currentXP = parseInt(localStorage.getItem('seekapa_xp') || '0');
        const newXP = currentXP + points;
        localStorage.setItem('seekapa_xp', newXP.toString());
        this.updateXPDisplay();
        this.checkLevelUp(newXP);
        return newXP;
    },

    getXP() {
        return parseInt(localStorage.getItem('seekapa_xp') || '0');
    },

    updateXPDisplay() {
        const xpElement = document.getElementById('user-xp');
        if (xpElement) {
            xpElement.textContent = this.getXP();
        }
    },

    checkLevelUp(xp) {
        const level = Math.floor(xp / 1000) + 1;
        const currentLevel = parseInt(localStorage.getItem('seekapa_level') || '1');
        if (level > currentLevel) {
            localStorage.setItem('seekapa_level', level.toString());
            this.showLevelUpNotification(level);
        }
    },

    showLevelUpNotification(level) {
        // Level up animation/notification
        console.log(`🎉 Level Up! You are now Level ${level}`);
        // TODO: Implement visual notification
    },

    // Streak System
    checkStreak() {
        const today = new Date().toDateString();
        const lastVisit = localStorage.getItem('seekapa_last_visit');
        const currentStreak = parseInt(localStorage.getItem('seekapa_streak') || '0');

        if (!lastVisit || lastVisit !== today) {
            const yesterday = new Date(Date.now() - 86400000).toDateString();
            if (lastVisit === yesterday) {
                // Continue streak
                const newStreak = currentStreak + 1;
                localStorage.setItem('seekapa_streak', newStreak.toString());
                localStorage.setItem('seekapa_last_visit', today);
                this.updateStreakDisplay(newStreak);
            } else {
                // Reset streak
                localStorage.setItem('seekapa_streak', '1');
                localStorage.setItem('seekapa_last_visit', today);
                this.updateStreakDisplay(1);
            }
        }
    },

    updateStreakDisplay() {
        const streakElement = document.getElementById('user-streak');
        if (streakElement) {
            streakElement.textContent = localStorage.getItem('seekapa_streak') || '0';
        }
    },

    // Lesson Completion
    markLessonComplete(lessonNumber) {
        const completedKey = `seekapa_lesson_${lessonNumber}_complete`;
        localStorage.setItem(completedKey, 'true');
        this.addXP(100); // Award 100 XP for lesson completion
    },

    isLessonComplete(lessonNumber) {
        return localStorage.getItem(`seekapa_lesson_${lessonNumber}_complete`) === 'true';
    },

    getCompletedLessonsCount() {
        let count = 0;
        for (let i = 1; i <= 12; i++) {
            if (this.isLessonComplete(i)) count++;
        }
        return count;
    }
};

// ========== LANGUAGE SYSTEM ==========
const AcademyLanguageSystem = {
    currentLanguage: 'ar', // Default to Arabic

    init() {
        // Load saved language preference
        this.currentLanguage = localStorage.getItem('seekapa_language') || 'ar';
        this.applyLanguage(this.currentLanguage);
        this.setupLanguageSwitchers();
    },

    applyLanguage(lang) {
        // Update HTML lang and dir attributes
        document.documentElement.setAttribute('lang', lang);
        document.documentElement.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');

        // Update all translatable elements
        const elements = document.querySelectorAll('[data-translate]');
        elements.forEach(el => {
            const key = el.getAttribute('data-translate');
            if (window.translations && window.translations[lang] && window.translations[lang][key]) {
                el.textContent = window.translations[lang][key];
            }
        });

        // Update active language button
        document.querySelectorAll('.lang-btn').forEach(btn => {
            btn.classList.toggle('active', btn.getAttribute('data-lang') === lang);
        });

        // Save preference
        localStorage.setItem('seekapa_language', lang);
        this.currentLanguage = lang;
    },

    setupLanguageSwitchers() {
        document.querySelectorAll('.lang-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const lang = btn.getAttribute('data-lang');
                this.applyLanguage(lang);
            });
        });
    }
};

// ========== QUIZ SYSTEM ==========
const AcademyQuizSystem = {
    currentQuestion: 0,
    correctAnswers: 0,
    totalQuestions: 0,

    init(quizData) {
        this.totalQuestions = quizData.questions.length;
        this.renderQuestion(quizData.questions[0]);
    },

    renderQuestion(question) {
        // TODO: Implement quiz question rendering
    },

    submitAnswer(questionIndex, selectedOption) {
        // TODO: Implement answer checking
        // Award XP for correct answers
        if (this.isCorrect(selectedOption)) {
            this.correctAnswers++;
            AcademyGameSystem.addXP(20); // 20 XP per correct answer
        }
    },

    isCorrect(selectedOption) {
        // TODO: Implement answer validation
        return false;
    },

    calculateScore() {
        return Math.round((this.correctAnswers / this.totalQuestions) * 100);
    }
};

// ========== INITIALIZATION ==========
document.addEventListener('DOMContentLoaded', () => {
    // Initialize gamification system
    AcademyGameSystem.checkStreak();
    AcademyGameSystem.updateXPDisplay();
    AcademyGameSystem.updateStreakDisplay();

    // Initialize language system
    AcademyLanguageSystem.init();

    // Mark lesson as viewed
    const lessonNumber = parseInt(document.body.getAttribute('data-lesson'));
    if (lessonNumber && !AcademyGameSystem.isLessonComplete(lessonNumber)) {
        // Award viewing XP (smaller than completion XP)
        AcademyGameSystem.addXP(10);
    }

    console.log('✅ Seekapa Trading Academy - System Initialized');
    console.log(`📊 Total XP: ${AcademyGameSystem.getXP()}`);
    console.log(`🔥 Current Streak: ${localStorage.getItem('seekapa_streak') || 0} days`);
    console.log(`✅ Completed Lessons: ${AcademyGameSystem.getCompletedLessonsCount()}/12`);
});

// Export for use in lesson-specific scripts
window.Seekapa = {
    Game: AcademyGameSystem,
    Language: AcademyLanguageSystem,
    Quiz: AcademyQuizSystem
};
