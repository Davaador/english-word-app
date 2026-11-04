# English Words App

A Flutter app that helps software developers learn English words.
It loads words from a REST API and tests your knowledge with a quiz.

## Features
- Load words from a Spring Boot API
- Filter words by category and level
- Take a quiz and check your answers
- Daily 5: a quiz with five new words every day
- Save your best score on the phone
- Check your sentences from a Spring Boot API

## Tech stack
- Flutter and Dart
- `http` package for API GET and POST calls 
- `shared_preferences` for local storage


## Backend
The app uses the [Words API](https://github.com/Davaador/words-api),
a REST API built with Spring Boot and PostgreSQL.

## Run locally
    flutter pub get
    flutter run

To build an Android release file:

    flutter build apk --release

## Screenshots
![Word list](screenshots/list.jpeg)
![Quiz](screenshots/quiz.jpeg)
![Check AI](screenshots/sentences.jpeg)

## Note
The API runs on a free hosting plan. The first request can be slow
because the server may be asleep. The AI check sentences error because the AI check error.