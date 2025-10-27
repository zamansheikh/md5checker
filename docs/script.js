// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Navbar background on scroll
const navbar = document.querySelector('.navbar');
window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
        navbar.style.background = 'rgba(15, 23, 42, 0.95)';
        navbar.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.3)';
    } else {
        navbar.style.background = 'rgba(15, 23, 42, 0.8)';
        navbar.style.boxShadow = 'none';
    }
});

// Intersection Observer for fade-in animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Add fade-in animation to elements
document.addEventListener('DOMContentLoaded', () => {
    // Select elements to animate
    const animateElements = document.querySelectorAll(
        '.feature-card, .download-card, .use-case, .doc-card, .workflow-step'
    );
    
    animateElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

// Terminal typing effect
const terminalText = document.querySelector('.terminal-body code');
if (terminalText) {
    const originalText = terminalText.innerHTML;
    terminalText.innerHTML = '';
    
    let charIndex = 0;
    const typingSpeed = 20;
    
    function typeText() {
        if (charIndex < originalText.length) {
            terminalText.innerHTML = originalText.substring(0, charIndex + 1);
            charIndex++;
            setTimeout(typeText, typingSpeed);
        }
    }
    
    // Start typing when terminal comes into view
    const terminalObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                setTimeout(typeText, 500);
                terminalObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });
    
    const terminalWindow = document.querySelector('.terminal-window');
    if (terminalWindow) {
        terminalObserver.observe(terminalWindow);
    }
}

// Copy to clipboard functionality for code blocks
document.querySelectorAll('.step-code, .instruction code').forEach(codeBlock => {
    codeBlock.style.position = 'relative';
    
    const copyButton = document.createElement('button');
    copyButton.innerHTML = '📋 Copy';
    copyButton.style.cssText = `
        position: absolute;
        top: 8px;
        right: 8px;
        background: rgba(59, 130, 246, 0.2);
        border: 1px solid rgba(59, 130, 246, 0.3);
        color: #3b82f6;
        padding: 4px 12px;
        border-radius: 4px;
        cursor: pointer;
        font-size: 12px;
        font-weight: 600;
        transition: all 0.3s;
        opacity: 0;
    `;
    
    codeBlock.style.position = 'relative';
    codeBlock.appendChild(copyButton);
    
    codeBlock.addEventListener('mouseenter', () => {
        copyButton.style.opacity = '1';
    });
    
    codeBlock.addEventListener('mouseleave', () => {
        copyButton.style.opacity = '0';
    });
    
    copyButton.addEventListener('click', () => {
        const textToCopy = codeBlock.textContent.replace('📋 Copy', '').trim();
        
        navigator.clipboard.writeText(textToCopy).then(() => {
            copyButton.innerHTML = '✓ Copied!';
            copyButton.style.background = 'rgba(16, 185, 129, 0.2)';
            copyButton.style.borderColor = 'rgba(16, 185, 129, 0.3)';
            copyButton.style.color = '#10b981';
            
            setTimeout(() => {
                copyButton.innerHTML = '📋 Copy';
                copyButton.style.background = 'rgba(59, 130, 246, 0.2)';
                copyButton.style.borderColor = 'rgba(59, 130, 246, 0.3)';
                copyButton.style.color = '#3b82f6';
            }, 2000);
        });
    });
});

// Download button click tracking (optional - for analytics)
document.querySelectorAll('.btn-download').forEach(button => {
    button.addEventListener('click', (e) => {
        const platform = button.textContent.includes('Windows') ? 'Windows' :
                        button.textContent.includes('Linux') ? 'Linux' : 'macOS';
        console.log(`Download initiated for ${platform}`);
        // You can add Google Analytics or other tracking here
        // gtag('event', 'download', { 'platform': platform });
    });
});

// Easter egg - Konami code
let konamiCode = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a'];
let konamiIndex = 0;

document.addEventListener('keydown', (e) => {
    if (e.key === konamiCode[konamiIndex]) {
        konamiIndex++;
        if (konamiIndex === konamiCode.length) {
            activateEasterEgg();
            konamiIndex = 0;
        }
    } else {
        konamiIndex = 0;
    }
});

function activateEasterEgg() {
    // Create confetti effect
    const colors = ['#3b82f6', '#8b5cf6', '#06b6d4', '#10b981', '#f59e0b'];
    for (let i = 0; i < 50; i++) {
        setTimeout(() => {
            const confetti = document.createElement('div');
            confetti.style.cssText = `
                position: fixed;
                width: 10px;
                height: 10px;
                background: ${colors[Math.floor(Math.random() * colors.length)]};
                top: -10px;
                left: ${Math.random() * 100}%;
                border-radius: 50%;
                pointer-events: none;
                z-index: 9999;
                animation: fall ${2 + Math.random() * 3}s linear forwards;
            `;
            document.body.appendChild(confetti);
            
            setTimeout(() => confetti.remove(), 5000);
        }, i * 50);
    }
    
    // Add fall animation
    if (!document.getElementById('confetti-style')) {
        const style = document.createElement('style');
        style.id = 'confetti-style';
        style.textContent = `
            @keyframes fall {
                to {
                    transform: translateY(100vh) rotate(360deg);
                    opacity: 0;
                }
            }
        `;
        document.head.appendChild(style);
    }
    
    // Show message
    const message = document.createElement('div');
    message.textContent = '🎉 You found the secret! Thanks for exploring! 🎉';
    message.style.cssText = `
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
        color: white;
        padding: 2rem 3rem;
        border-radius: 1rem;
        font-size: 1.5rem;
        font-weight: 700;
        z-index: 10000;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
        animation: popIn 0.5s cubic-bezier(0.68, -0.55, 0.265, 1.55);
    `;
    
    const styleAnim = document.createElement('style');
    styleAnim.textContent = `
        @keyframes popIn {
            0% { transform: translate(-50%, -50%) scale(0); }
            100% { transform: translate(-50%, -50%) scale(1); }
        }
    `;
    document.head.appendChild(styleAnim);
    
    document.body.appendChild(message);
    setTimeout(() => message.remove(), 3000);
}

// Mobile menu toggle (for future implementation)
const createMobileMenu = () => {
    // This is a placeholder for mobile menu functionality
    // You can expand this based on your needs
    console.log('Mobile menu functionality can be added here');
};

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    console.log('MD5 Hash Checker Website Loaded');
    console.log('🔐 Secure your files with content-addressable storage!');
});
