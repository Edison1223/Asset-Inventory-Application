# Asset Inventory Application 📦

Hi, this is my Final Year Project that using Flutter-based solution for managing organizational assets, featuring a dual-role access system for Administrators and Regular Users.

## 🚀 Key Features
Role-Based Access Control: Distinct functionalities for Admin and Regular User roles.

Admin Dashboard: Full control over asset records and user management.

User Management: Admins can create and manage credentials for Regular Users.

Real-time Database: Integrated with Firebase (Firestore) for seamless data syncing.

## 🔐 Access Levels & Authentication
The application uses a two-tier permission system:

### 1. Administrator (Hardcoded)
The Admin account is predefined for initial setup and system oversight.

Username: admin

Password: admin123

Capabilities: Full CRUD (Create, Read, Update, Delete) on assets and the ability to register new Regular Users.

### 2. Regular User
Regular Users are created by the Admin via the in-app management panel.

Username/Password: Defined by the Admin during creation.

Capabilities: Restricted access (e.g., viewing assets, updating status, or reporting issues).

### 🛠️ Tech Stack
Frontend: Flutter (Dart)

Backend: Firebase



