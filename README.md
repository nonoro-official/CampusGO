# 🍽️ Foodika: Discover, Dine, and Earn

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=firebase&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

Foodika is a dual-sided, full-stack mobile application built to connect food enthusiasts with local MSMEs in the Philippines. 

It moves beyond standard delivery apps by eliminating heavy merchant commissions and focusing on **discovery, gamified loyalty, and actionable demographic insights**.

---

## 📸 Screen Previews

> **Note:** Replace these placeholder links with actual images of your app. Create a `/assets/screenshots/` folder in your repo.

<p align="center">
  <img src="link_to_map_discovery_image.png" width="200" alt="Map Discovery"/>
  <img src="link_to_restaurant_detail_image.png" width="200" alt="Restaurant Profile"/>
  <img src="link_to_live_order_image.png" width="200" alt="Live Order Tracker"/>
  <img src="link_to_admin_insights_image.png" width="200" alt="Admin Insights Dashboard"/>
</p>

---

## ✨ Key Features

### 👤 For Users (B2C)
* **Interactive Map Discovery:** Find nearby hidden gems using `flutter_map` and open-source location data. Filter by tags like "Fast Food," "Cafe," or "Filipino."
* **Gamified Loyalty Economy:** Earn Foodika Points by interacting with the app (e.g., +10 points for sharing a restaurant, +50 points for completing your demographic profile).
* **Voucher Redemption:** Exchange earned points for exclusive discounts at partner restaurants.
* **Live Order Tracking:** Real-time state management showing order progress (Pending -> Preparing -> Ready) synced directly with the merchant's kitchen.

### 🏪 For Merchants (B2B Admin)
* **Live Kitchen Dashboard:** A real-time, one-tap state machine to accept and fulfill incoming orders efficiently.
* **Customer Insights Dashboard:** Aggregated, anonymized demographic analytics. View the percentage of customers by **User Status** (Student vs. Professional) and **Age Groups** to optimize marketing strategies.
* **Menu & Voucher Management:** Create, edit, and set quantity limits on promotional vouchers to drive foot traffic during off-peak hours.
* **Automated Economy Sync:** If an order is canceled, the system automatically refunds the user's points and returns the voucher to the public pool.

---

## 🛠️ Tech Stack & Architecture

* **Frontend:** Flutter & Dart
* **Backend:** Firebase (Serverless Architecture)
  * **Firestore:** Real-time NoSQL database for syncing live orders and user/merchant data.
  * **Firebase Auth:** Secure user authentication.
  * **Firebase Storage:** Cloud storage for menu items and user profile pictures.
* **Mapping:** `flutter_map` (OpenStreetMap integration for zero-cost map overhead).

---

## 🚀 Getting Started

To run this project locally, you will need to have [Flutter](https://flutter.dev/docs/get-started/install) installed and a Firebase project set up.

### 1. Clone the repository
```bash
git clone [https://github.com/yourusername/foodika.git](https://github.com/yourusername/foodika.git)
cd foodika
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Configuration
This project relies on Firebase. You must connect it to your own Firebase instance:
1. Create a new project in the [Firebase Console](https://console.firebase.google.com/).
2. Register an Android and/or iOS app.
3. Download the `google-services.json` (for Android) and place it in `android/app/`.
4. Download the `GoogleService-Info.plist` (for iOS) and place it in `ios/Runner/`.
5. Enable **Firestore**, **Authentication** (Email/Password), and **Storage** in your Firebase console.

### 4. Run the App
```bash
flutter run
```

---

## 📂 Project Structure Overview

```text
lib/
├── pages/
│   ├── admin/          # B2B Merchant dashboards, insights, and live orders
│   ├── auth/           # Login and Registration flows
│   └── user/           # B2C Map, cart, checkout, and gamified profiles
├── services/           # Firebase authentication and database services
├── providers/          # State management (e.g., CartProvider)
└── main.dart           # App entry point
```

---

## 💡 Lessons Learned & Future Scope
Building Foodika required engineering a balanced, closed-loop digital economy. Managing asynchronous database updates (ensuring points are deducted, vouchers are claimed, and kitchen screens update simultaneously) highlighted the importance of robust error handling and real-time state management. 

**Future features could include:**
* Push notifications for proximity-based deals.
* Integration of local payment gateways (GCash/Maya).
