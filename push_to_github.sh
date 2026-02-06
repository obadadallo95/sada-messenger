#!/bin/bash

# Initialize git repository
git init

# Add all files (respects .gitignore automatically)
git add .

# Commit with message
git commit -m "Initial Release v1.0.0"

# Add remote origin
git remote add origin https://github.com/obadadallo95/sada-messenger.git

# Push to main branch
git branch -M main
git push -u origin main

