# Squad Score: The Social Leaderboard App
A modern, responsive leaderboard web app with a gaming-inspired UI, designed for social competition and collaboration.

## About This Project
Our app is designed to bring structure and excitement to casual competition among friends. Instead of keeping score on scraps of paper or forgetting who won last week, users can join squads, log results, and build leaderboards that update automatically. Additionally, notifications and chatrooms keep groups connected and engaged. Whether it is a billiards group, pickup soccer, or weekend board games, Squad Score hopes to empower more connected communities through competition, especially in times where people are more disconnected than ever.

## Features

- **Modern Design**: Dark theme with gaming-inspired colors and typography
- **Responsive Layout**: Works perfectly on desktop, tablet, and mobile devices
- **Interactive Navigation**: Smooth transitions and hover effects
- **Accessibility**: Keyboard navigation support and semantic HTML

Our app is now live! Try the deployed version here: [https://cs370-social-leaderboard.vercel.app/]()

## Getting Started

### Prerequisites

- Node.js (optional, for development server)
- Modern web browser

### Installation & Setup

1. Clone or download the project files
2. Navigate to the project directory
3. (Optional) Install dependencies:
   ```bash
   npm install
   ```

### Running the Project

#### Option 1: Direct File Opening
Simply open `index.html` in your web browser.

#### Option 2: Development Server
```bash
# Start development server with live reload
npm run dev

# Or use a simple static server
npm start
```

The website will be available at `http://localhost:3000`

## Project Structure

```
squad-score-website/
├── index.html          # Main HTML file
├── styles.css          # CSS styles and responsive design
├── script.js           # JavaScript functionality
├── package.json        # Project configuration
└── README.md          # This file
```

## Customization

### Changing Colors
Edit the CSS variables in `styles.css` to match your brand colors:

```css
:root {
  --bg-primary: #1A202C;
  --text-primary: #ffffff;
  --accent-orange: #F6AD55;
  --accent-green: #68D391;
  --accent-pink: #ED64A6;
}
...
```

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Future Enhancements

- Leaderboards page with dynamic data
- User authentication system
- Real-time score updates
- Squad management features
- User profile pages
- Mobile app integration

## License

MIT License - feel free to use this project for your own purposes.

## Contributing

Contributions are welcome! If you want to contribute:

1. Fork the project  
2. Create a new branch: `git checkout -b feature/your-feature-name`  
3. Make your changes (new feature, bug fix, UI improvement, etc.)  
4. Commit and push your changes  
5. Open a Pull Request with a clear description of what you changed  

Please make sure any new features include corresponding database migrations (if needed) and update documentation (in README or relevant `.md` files). 
