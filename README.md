# 🎓 CampusGO: Discover, Participate, and Earn

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=firebase&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

CampusGO is a full-stack mobile application designed to simplify campus event discovery, organization, and participation within the CIIT community.

Built for students, professors, and event organizers, the application centralizes campus events, announcements, rewards, and updates into a single platform while encouraging student engagement through **QR code-based reward collection**, seamless cloud connectivity, and an intuitive event management experience.

The project is developed for **Android** and **Web** platforms using Flutter, providing a consistent experience across both devices.

---

## 📸 Screen Previews

<p align="center">
  <img src="assets/screenshots/dashboard.png" width="200" alt="Dashboard"/>
  <img src="assets/screenshots/events.png" width="200" alt="Events"/>
  <img src="assets/screenshots/rewards.png" width="200" alt="Rewards"/>
</p>

---

## ✨ Key Features

### 👤 For Students

- **Campus Event Discovery:** Browse upcoming seminars, workshops, competitions, and organization events from a personalized dashboard with categorized listings.
- **Reward System:** Earn points by participating in campus events and purchasing official event merchandise. Redeem accumulated points for exclusive campus merchandise, discounts, and special rewards.
- **Campus Map:** Easily locate event venues and important campus facilities through an interactive campus map.
- **CIIT Authentication:** Secure login using verified CIIT email addresses and student ID numbers to ensure only authorized users can access the platform.
- **Dashboard & Updates:** Stay informed with campus announcements, event reminders, reward availability, and the latest campus activities from a centralized dashboard.
- **Smart Notifications:** Receive consistent but non-invasive notifications for registrations, announcements, rewards, and event updates.
- **Theme Support:** Has both light and dark themes for a comfortable user experience.

### 🏫 For Event Organizers

- **Event Management Dashboard:** Create, edit, publish, and manage campus events from a centralized administrative interface.
- **QR Code Attendance & Rewards:** Generate unique QR codes for events, allowing participants to securely claim reward points after attendance.
- **Participant Management:** Monitor registrations, attendance, and participant information in real time.
- **Announcement Center:** Publish announcements and important updates directly to student dashboards.
- **Reward Management:** Create and manage redeemable merchandise, reward inventories, and point requirements.
- **Cloud Synchronization:** Keep events, announcements, participant information, and rewards synchronized across all connected devices through Firebase.

---

## 🛠️ Tech Stack & Architecture

- **Platforms:** Android & Web
- **Frontend:** Flutter & Dart
- **Backend:** Firebase (Serverless Architecture)
  - **Firestore:** Real-time NoSQL database for events, users, rewards, announcements, and registrations.
  - **Firebase Authentication:** Secure CIIT email authentication and account management.
  - **Firebase Storage:** Cloud storage for event posters, merchandise images, and user assets.
  - **Firebase Cloud Messaging:** Push notifications for event reminders and campus announcements.
- **Cloud Connectivity:** Real-time synchronization between students, organizers, and administrators.

---

## 🚀 Getting Started

To run this project locally, you will need to have [Flutter](https://flutter.dev/docs/get-started/install) installed together with your own Firebase project.

### 1. Clone the Repository

```bash
git clone https://github.com/nonoro-official/CampusGO.git
cd CampusGO
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

This project relies on Firebase. Connect it to your own Firebase instance:

1. Create a new project in the Firebase Console.
2. Register both an **Android** application and a **Web** application.
3. Download the `google-services.json` file and place it inside:

```text
android/app/
```

4. Configure your Firebase Web options using the generated configuration or FlutterFire CLI.
5. Enable the following Firebase services:

- Firestore Database
- Firebase Authentication
- Firebase Storage
- Firebase Cloud Messaging (Optional)

### 4. Run the Application

For Android:

```bash
flutter run
```

For Web:

```bash
flutter run -d chrome
```

---

## 📂 Project Structure Overview (wip)

```text
lib/
├── core/
│   ├── constants/
│   ├── services/
│   ├── themes/
│   └── utils/
│
├── features/
│   ├── admin/
│   ├── auth/
│   ├── dashboard/
│   ├── events/
│   ├── map/
│   ├── notifications/
│   ├── profile/
│   └── rewards/
│
├── shared/
│   ├── models/
│   ├── providers/
│   ├── repositories/
│   └── widgets/
│
└── main.dart
```

---

## 💡 Lessons Learned & Future Scope (wip)

Building **CampusGO** required designing a centralized platform capable of synchronizing event information, participant registrations, QR code reward validation, and reward transactions across multiple users in real time. Developing a cloud-connected application reinforced the importance of scalable architecture, secure authentication, efficient state management, and reliable QR code verification while balancing feature development within a limited project timeline.

**Future features could include:**

- Digital event certificates and achievement badges
- Google Calendar integration
- Personalized event recommendations
- Organization-specific pages
- Attendance analytics dashboard
- In-app event feedback and ratings
- Merchandise inventory management