# HealMeal

Welcome to the **HealMeal** application repository! 

HealMeal is a comprehensive Flutter-based platform designed to provide seamless access to healthcare products, lab test bookings, prescription uploads, and role-based management (Admin, Pharmacist, Rider, Lab Technician, and Business roles).

## Features

- **User & Role Management**: Tailored experiences for Customers, Admins, Pharmacists, Lab Techs, and Riders.
- **E-Commerce & Pharmacy**: Browse and search for medical products, add to cart, and checkout seamlessly.
- **Prescription Uploads**: Easily upload prescriptions for fast medication processing.
- **Lab Tests**: Book and manage laboratory tests and diagnostics.
- **Order Tracking**: Real-time tracking and history for orders and deliveries.
- **AI Chat Assistant**: Integrated AI search and support powered by Groq.
- **Secure Backend**: Powered by Firebase (Auth, Firestore) with strict security rules.

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- A Firebase project configured with Firestore and Authentication.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Saymum-GS/HealMeal.git
   cd HealMeal
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Setup**
   Create a `.env` file in the root directory and add your required API keys (e.g., `GROQ_API_KEY`).

4. **Run the app**
   ```bash
   flutter run
   ```

## Architecture & Tech Stack
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Cubit / BLoC](https://bloclibrary.dev/)
- **Backend**: Firebase (Firestore, Authentication, Admin SDK)
- **AI Integration**: Groq API for intelligent search and chat features.

---
*HealMeal - Making healthcare and nutrition accessible for everyone.*
