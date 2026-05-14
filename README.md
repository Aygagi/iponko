# IponKo 🐷

### Student Savings App — Philippines

**Flutter Frontend + REST API Backend**

> "Mag-ipon tayo!" — A habit-building savings app for Filipino students and their parents.

---

## 👥 Team

| Role               | Name   | Branch     |
| ------------------ | ------ | ---------- |
| Frontend (Flutter) | Joshua | `frontend` |
| Backend (API)      | Jhed   | `backend`  |

---

## 📌 Project Status

| Layer                                    | Status         |
| ---------------------------------------- | -------------- |
| Flutter project scaffold                 | ✅ Done        |
| Data models (User, Goal, Deposit, Badge) | ✅ Done        |
| Offline storage (Hive)                   | ✅ Done        |
| Repository interface (API-ready)         | ✅ Done        |
| Splash Screen                            | ✅ Done        |
| Sign Up / Registration                   | ✅ Done        |
| PIN Screen (setup + login)               | ✅ Done        |
| Student Dashboard                        | ✅ Done        |
| Add Deposit Screen                       | ✅ Done        |
| Create Goal Screen                       | ✅ Done        |
| Goals List Screen                        | ✅ Done        |
| Deposit Log + Charts                     | ✅ Done        |
| Badges Screen                            | ✅ Done        |
| Parent Dashboard                         | ✅ Done        |
| Profile & Settings                       | ✅ Done        |
| **Frontend — COMPLETE**                  | ✅             |
| Backend API                              | 🔄 Jhed's turn |

---

## 🔧 For Jhed — Backend Developer

Hey Jhed! The entire frontend is done and waiting for your API. Here's everything you need to plug in cleanly — **zero UI changes needed** on Joshua's side once your backend is ready.

---

### 📁 The One File You Need to Match

**`iponko/lib/repositories/ipon_repository.dart`**

This is the abstract interface the frontend uses. Create `api_repository.dart` implementing every method here. The frontend never calls your API directly — it goes through this interface.

---

### 🔁 How the Swap Works

Only **one line** changes in the entire frontend when your API is ready:

**`iponko/lib/providers/app_providers.dart`** — line ~16:

```dart
// BEFORE (offline Hive):
return HiveRepository();

// AFTER (your Spring Boot API):
return ApiRepository(baseUrl: 'http://your-server-address/api');
```

That's it. Zero UI changes. The app just works online.

---

### 📦 Agreed JSON Contract

Your API responses **must match these field names and types exactly**.

#### User

```json
{
  "id": "string (UUID)",
  "name": "string",
  "email": "string",
  "role": "student | parent",
  "school": "string | null",
  "gradeLevel": "int | null",
  "linkedChildId": "string | null",
  "linkedParentId": "string | null",
  "createdAt": "ISO 8601 datetime string"
}
```

#### Goal

```json
{
  "id": "string (UUID)",
  "userId": "string",
  "name": "string",
  "targetAmount": "double",
  "currentAmount": "double",
  "targetDate": "ISO 8601 datetime string",
  "createdAt": "ISO 8601 datetime string",
  "status": "active | completed | archived",
  "emoji": "string | null"
}
```

#### Deposit

```json
{
  "id": "string (UUID)",
  "userId": "string",
  "goalId": "string | null",
  "amount": "double",
  "source": "allowance | baon | gift | other",
  "date": "ISO 8601 datetime string",
  "note": "string | null",
  "isApprovedByParent": "boolean",
  "createdAt": "ISO 8601 datetime string"
}
```

---

### 🌐 Expected API Endpoints

Build these in priority order.

#### Auth

| Method | Endpoint             | Description                 |
| ------ | -------------------- | --------------------------- |
| POST   | `/api/auth/register` | Register new user           |
| POST   | `/api/auth/login`    | Login, returns JWT token    |
| GET    | `/api/auth/me`       | Get current user from token |

#### Goals

| Method | Endpoint             | Description              |
| ------ | -------------------- | ------------------------ |
| GET    | `/api/goals?userId=` | Get all goals for a user |
| POST   | `/api/goals`         | Create a new goal        |
| PUT    | `/api/goals/:id`     | Update a goal            |
| DELETE | `/api/goals/:id`     | Delete a goal            |

#### Deposits

| Method | Endpoint                    | Description                 |
| ------ | --------------------------- | --------------------------- |
| GET    | `/api/deposits?userId=`     | Get all deposits for a user |
| POST   | `/api/deposits`             | Log a new deposit           |
| DELETE | `/api/deposits/:id`         | Delete a deposit            |
| PATCH  | `/api/deposits/:id/approve` | Parent approves a deposit   |

#### Users

| Method | Endpoint          | Description                   |
| ------ | ----------------- | ----------------------------- |
| GET    | `/api/users/:id`  | Get user by ID                |
| PUT    | `/api/users/:id`  | Update user profile           |
| POST   | `/api/users/link` | Link parent to child via code |

---

### 🔐 Auth

Use **JWT Bearer tokens**. After login, the frontend stores the token and sends it as:

```
Authorization: Bearer <token>
```

---

### 🚀 Getting Started (Jhed's Setup)

```bash
# Clone the repo
git clone https://github.com/Aygagi/iponko.git
cd iponko

# Create your backend branch
git checkout -b backend
git push -u origin backend

# Work in the backend/ folder
mkdir backend
cd backend
# Start your Spring Boot project here
```

Keep all backend code inside `/backend` folder — separate from the Flutter code in `/iponko`.

---

### 📂 Repo Structure

```
iponko/                             ← Flutter frontend (Joshua) ✅ COMPLETE
  lib/
    models/                         ← JSON contracts live here
    repositories/
      ipon_repository.dart          ← Interface your API must match
      hive_repository.dart          ← Current offline implementation
    providers/
      app_providers.dart            ← Swap HiveRepository → ApiRepository here
    screens/
      auth/                         ← Splash, Sign Up, PIN
      student/                      ← Dashboard, Goals, Deposits, Badges
      parent/                       ← Parent Dashboard
      shared/                       ← Profile & Settings
backend/                            ← Your Spring Boot project (Jhed) 🔄
README.md
```

---

### ⚠️ Important Notes for Jhed

- All amounts are **Philippine Peso (PHP)** — store as `DECIMAL(10,2)` in your database
- `currentAmount` on goals is computed from deposits — compute server-side or accept frontend computation
- `isSynced` field is **frontend-only** — you don't need to store it
- Dates are always **ISO 8601**: `2025-04-30T14:30:00.000Z`
- UUIDs are generated on the frontend — your backend should accept client-generated IDs
- `source` field on deposits must be exactly: `allowance`, `baon`, `gift`, or `other`
- `role` field on users must be exactly: `student` or `parent`

---

## 👨‍💻 Developed by

**Joshua & Jhed** — BSIT AI & Robotics
Integ 2 Final Project

---

_IponKo — Mag-ipon tayo! 🐷_
