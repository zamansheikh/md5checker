# MD5 Hash Checker - Landing Page

This folder contains the landing page for the MD5 Hash Checker project.

## 📁 Files

- `index.html` - Main landing page
- `styles.css` - Complete styling with dark theme
- `script.js` - Interactive features and animations

## 🚀 GitHub Pages Setup

To publish this landing page on GitHub Pages:

1. **Push the docs folder to GitHub:**
   ```bash
   git add docs/
   git commit -m "Add landing page"
   git push origin main
   ```

2. **Enable GitHub Pages:**
   - Go to your repository on GitHub
   - Navigate to **Settings** → **Pages**
   - Under **Source**, select `main` branch and `/docs` folder
   - Click **Save**

3. **Your site will be live at:**
   ```
   https://zamansheikh.github.io/md5checker/
   ```

## ✨ Features

### Design
- 🎨 Modern dark theme with gradient accents
- 📱 Fully responsive (mobile, tablet, desktop)
- ⚡ Smooth animations and transitions
- 🖥️ Animated terminal window showcase
- 🎯 Professional color scheme

### Sections
1. **Hero** - Eye-catching introduction with animated terminal
2. **Features** - Showcase all key features with icons
3. **How It Works** - Step-by-step workflow visualization
4. **Downloads** - Direct download links for all platforms
5. **Use Cases** - Real-world application scenarios
6. **Documentation** - Links to comprehensive docs
7. **CTA** - Call-to-action for downloads and GitHub stars
8. **Footer** - Social links and site navigation

### Interactive Features
- ✅ Smooth scroll navigation
- ✅ Fade-in animations on scroll
- ✅ Terminal typing effect
- ✅ Copy-to-clipboard for code blocks
- ✅ Hover effects on cards
- ✅ Download tracking (console logs)
- 🎁 Easter egg (Konami code: ↑↑↓↓←→←→BA)

## 🎨 Customization

### Colors
Edit the CSS variables in `styles.css`:

```css
:root {
    --primary-color: #3b82f6;    /* Main brand color */
    --secondary-color: #8b5cf6;   /* Accent color */
    --bg-primary: #0f172a;        /* Background */
    /* ... more variables */
}
```

### Download Links
Update download URLs in `index.html` when you release new versions:

```html
<a href="https://github.com/zamansheikh/md5checker/releases/download/v1.0.0/...">
```

### Social Links
Update your social media links in the footer section of `index.html`.

## 📊 Analytics (Optional)

To add Google Analytics:

1. Get your Google Analytics tracking ID
2. Add this before closing `</head>` tag in `index.html`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_TRACKING_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_TRACKING_ID');
</script>
```

## 🔧 Local Testing

Open `index.html` in your browser or use a local server:

```bash
# Using Python
python -m http.server 8000

# Using Node.js
npx http-server

# Then visit: http://localhost:8000
```

## 📱 Browser Support

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers (iOS Safari, Chrome Android)

## 🎯 Performance

- Minimal external dependencies (only Google Fonts)
- Optimized CSS with CSS Grid and Flexbox
- Smooth 60fps animations
- Fast load times (~50KB total)

## 📝 License

Same as the main project - MIT License.

---

Made with ❤️ by Md. Shamsuzzaman
