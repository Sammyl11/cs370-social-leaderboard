# Squad Score: The Social Leaderboard App
A modern, responsive leaderboard web app with a gaming-inspired UI, designed for social competition and collaboration.

## About This Project
Our app is designed to bring structure and excitement to casual competition among friends. Instead of keeping score on scraps of paper or forgetting who won last week, users can join squads, log results, and build leaderboards that update automatically. Additionally, notifications and chatrooms keep groups connected and engaged. Whether it is a billiards group, pickup soccer, or weekend board games, Squad Score hopes to empower more connected communities through competition, especially in times where people are more disconnected than ever.

## Features

- Dark-theme, gaming-inspired UI with light-theme option for accessibility
- User authentication (via Supabase) for login/signup  
- Squad creation and management (create squads, join existing squads, manage squad membership)
- Optional “evidence” submission and validation when adding scores to leaderboard
- Chatroom support for squads
- Responsive Layout: works on desktop, tablet, and mobile devices

Squad Score is now live! Try the [deployed version](https://cs370-social-leaderboard.vercel.app/) here.

## Repository Structure

```
/
├── css/                       # CSS stylesheets
├── js/                        # Front-end JavaScript logic
└── db_guides/                 # Supabase Markdown documentation
   ├── SUPABASE_SETUP.md       # Documentation for setting up Supabase backend
   ├── SUPABASE_AUTH.md        # Documentation for authentication configuration
   ├── SQUAD_SCHEMA_UPDATE.md  # Sample code for building squads schema
   └── USAGE_EXAMPLES.md       # Example workflows for using the leaderboard and squads
├── .gitignore
├── All_Supabase_Scripts.sql   # SQL schema / migration scripts (Supabase)
├── supabase-auth.js           # Auth integration scripts
├── test-api.js                # API test or helper scripts
├── package.json               # Node project metadata (if running dev server)
├── *.html                     # HTML pages (login, signup, leaderboards, squad management, chat, etc.)
└── README.md                  # This file
```

## Prerequisites

- Modern web browser (e.g. Chrome, Firefox, Safari)
- (If using backend) PostgreSQL or Supabase account to host the database using provided SQL schema  
- (Optional) Node.js — for running development server or any build scripts  

## Installation & Setup

1. Clone or download the project files
   ```bash
   git clone https://github.com/sammyl11/cs370-social-leaderboard.git
   cd cs370-social-leaderboard
   ```

2. Navigate to the project directory
3. (Optional) Install dependencies:
   ```bash
   npm install
   ```

## Running the Project

### Option 1: Direct File Opening
Simply open `index.html` in your web browser.

### Option 2: Development Server
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
Edit the `:root` and `.theme-light` variables in `styles.css` to change desired colors for dark and light themes.

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
